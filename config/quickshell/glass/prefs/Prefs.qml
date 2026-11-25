import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.UPower
import Quickshell.Wayland
import qs
import qs.components
import qs.services
import qs.settings

// Glyph Settings: Super+I. Designed around physical interactive objects rather than conventional forms.
// Left column: list of section names in Doto font (styled like the power menu) — active section is enlarged with a red dot.
// Right side: live interactive section canvas:
//   - HOME: 3x3 bento layout preview
//   - DECK: screen preview with edge-pinned deck panel
//   - WINDOWS: live desktop mockup displaying gaps and borders
//   - IDLE: minute timeline controlling screen blanking and sleep
// Numerical controls are rendered as circular dot dials (drag around perimeter or scroll wheel); toggles are animated pill switches.
// Navigation: Up/Down selects sections, Tab moves between controls, Left/Right adjusts values, Esc closes.
// Changes apply live: stored in Theme.state (glyph.json) and Rules.store (rules.json, shared with Demonshot), triggering respective apply hooks.
// Window gaps, borders, blur, and shadows apply via Theme.apply (Rules.windows() would revert to Demonshot's styling).
PanelWindow {
    id: root

    property int sel: 0
    signal wallRequested // Wallpaper picker opens full-screen overlay (wall/Walls), managed via shell.qml
    readonly property var sections: ["HOME", "DECK", "BAR", "LOOK", "STYLE", "WINDOWS", "DISPLAY", "AUDIO", "POWER", "INPUT", "IDLE", "SHELL", "CORNERS"]
    readonly property string moves: "shift ←→ move · ↵ swap · del drop · drag"
    readonly property string rings: "drag round the rings · scroll"
    readonly property var hints: [moves, moves, moves, "", "hover to preview · ↵ or click sets it", rings, "drag a screen to move it · " + rings, "click or ←→ a device", "↵ or click a mode", rings, "drag the marks", "", "click a corner to cycle action"]
    readonly property var r: Rules.store

    // Glyph icon mappings for home widgets, deck sections, and bar tray items
    readonly property var icons: ({
        weather: "\u{F0595}", calendar: "\u{F00ED}", cpu: "\u{F061A}", ram: "\u{F035B}", gpu: "\u{F08AE}", disk: "\u{F02CA}",
        battery: "\u{F0079}", buds: "\u{F02CB}", player: "\u{F040A}", system: "\u{F0128}", cat: "\u{F011B}", cava: "\u{F0EA2}",
        clock: "\u{F0150}", perf: "\u{F04C5}", net: "\u{F05A9}", media: "\u{F075A}",
        layout: "\u{F030C}", wifi: "\u{F05A9}", bluetooth: "\u{F00AF}", sound: "\u{F057E}", notes: "\u{F009A}",
        mode: "\u{F04C5}", power: "\u{F0425}"
    })
    // Circular home widgets; others default to 40px rounded squares. Technical note: ram/gpu/disk/battery default to circular dial representation
    readonly property var rounds: ["weather", "cpu", "ram", "gpu", "disk", "battery", "buds", "cava"]

    // ---- Open/close transitions: internal animation (Glyph layer-shell surfaces disable Hyprland window animations). Active section is preserved between sessions ----
    property bool shown: false
    property real t: shown ? 1 : 0
    Behavior on t { NumberAnimation { duration: Theme.t; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.glide } }
    function open() {
        pickMon = Hyprland.focusedMonitor?.name ?? "";
        shown = true;
        stage.forceActiveFocus();
    }
    function close() { shown = false; }
    function toggle() { shown ? close() : open(); }
    function go(i) {
        sel = (i + sections.length) % sections.length;
        stage.forceActiveFocus(); // Prevent focus loss when switching between hidden sections
    }

    // Target display configured by DISPLAY and HOME: defaults to focused monitor on open; falls back to primary if disconnected
    property string pickMon
    readonly property var names: Quickshell.screens.map(s => s.name)
    readonly property string mon: names.includes(pickMon) ? pickMon : names[0] ?? ""
    readonly property bool multi: names.length > 1
    onMonChanged: home.cur = 0 // Reset cursor when switching monitors as each display has its own widget configuration

    // ---- ID lists in Theme.state: home widgets, deck sections, bar tray items. Modified on a copy — JsonAdapter writes to disk on assignment.
    // Methods return updated cursor index. Home widgets are monitor-specific: multi-monitor assigns an independent set upon editing; otherwise shared ----
    function list(key) { return key === "widgets" ? Theme.scr(mon, "widgets") : Theme.state[key]; }
    function edit(key, f) {
        const a = list(key).slice();
        f(a);
        if (key === "widgets" && (multi || Theme.own(mon)?.widgets)) Theme.setScr(mon, "widgets", a);
        else Theme.state[key] = a;
    }
    function move(key, i, to) {
        if (to < 0 || to >= list(key).length || to === i) return i;
        edit(key, a => a.splice(to, 0, a.splice(i, 1)[0]));
        return to;
    }
    function cut(key, i) {
        const n = list(key).length;
        if (i >= n) return i;
        edit(key, a => a.splice(i, 1));
        return Math.max(0, Math.min(i, n - 2));
    }
    // Enter on selected item: cycles to next available item in 'all' that is not currently placed. In an empty list, adds first free item
    function cycle(key, i, all) {
        const a = list(key);
        if (all.every(k => a.includes(k))) return i;
        i = Math.min(i, a.length);
        let j = all.indexOf(a[i]);
        do j = (j + 1) % all.length; while (a.includes(all[j]));
        edit(key, b => b[i] = all[j]);
        return i;
    }
    // Tray toggle: if item is already present, remove it; if absent, insert it after current selection
    function flip(key, w, cur) {
        const a = list(key), i = a.indexOf(w);
        if (i >= 0) {
            edit(key, b => b.splice(i, 1));
            return Math.max(0, Math.min(i < cur ? cur - 1 : cur, a.length - 2));
        }
        const at = Math.min(cur + 1, a.length);
        edit(key, b => b.splice(at, 0, w));
        return at;
    }
    // Keyboard navigation in focused list: Left/Right to select, Shift+Left/Right to reorder, Enter/Space to cycle type, Del/Backspace to remove. Returns -1 for unhandled keys
    function nav(e, key, cur, all) {
        const n = list(key).length, d = e.key === Qt.Key_Left ? -1 : e.key === Qt.Key_Right ? 1 : 0;
        if (d && (e.modifiers & Qt.ShiftModifier)) return move(key, cur, cur + d);
        if (d) return n ? (cur + d + n) % n : 0;
        if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space) return cycle(key, cur, all);
        if (e.key === Qt.Key_Delete || e.key === Qt.Key_Backspace) return cut(key, cur);
        return -1;
    }
    // Bento grid auto-flow packing: left-to-right, top-to-bottom; items that don't fit current row advance to next line leaving remaining cells vacant; max 3 rows, overflow excluded
    function pack(ids) {
        let row = 0, col = 0;
        return ids.map((w, i) => {
            const span = Theme.kinds[w] ?? 1;
            if (col + span > 3) {
                row++;
                col = 0;
            }
            const c = { id: w, i, row, col, span, fits: row < 3 };
            col += span;
            return c;
        });
    }

    SystemClock { id: clock; enabled: root.visible; precision: SystemClock.Minutes }
    readonly property string hello: { const h = clock.date.getHours(); return h < 5 ? "Good night" : h < 12 ? "Good morning" : h < 18 ? "Good afternoon" : "Good evening"; }
    readonly property string who: (Theme.state.name || Quickshell.env("USER")).replace(/&/g, "&amp;").replace(/</g, "&lt;")

    // Active shell name and description parsed from its rice.json (same metadata used by Rice switcher app)
    property var meta: ({})
    FileView { path: Quickshell.shellPath("rice.json"); onLoaded: try { root.meta = JSON.parse(text()); } catch (e) {} }
    // "Switch shell" button only displayed when multiple shells are detected in sibling directories containing rice.json (Demon's Shot, etc.)
    property int shells: 1
    Process {
        running: root.visible
        command: [Quickshell.env("HOME") + "/.config/quickshell/rice/rice", "list"]
        stdout: StdioCollector { onStreamFinished: root.shells = text.trim().split("\n").length }
    }

    visible: shown || t > 0.05
    anchors { left: true; right: true; top: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    // Keyboard focus mode: OnDemand for multi-monitor setups (clicking a window on another screen yields focus, clicking here regains it).
    // Exclusive for single monitor (prevents newly opened windows underneath the full-screen scrim from stealing navigation keys and Esc)
    WlrLayershell.keyboardFocus: shown ? multi ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "glass-prefs"

    Rectangle {
        anchors.fill: parent
        color: "#0D1017" // Solid background: prevents bright window portions behind from bleeding through semi-transparent scrim
        opacity: root.t
        MouseArea { anchors.fill: parent; onClicked: stage.forceActiveFocus() } // Clicking empty space unfocuses child inputs; Esc dismisses panel
    }

    Stage {
        id: stage
        opacity: root.t
        focus: true
        Keys.onPressed: e => {
            if (e.key === Qt.Key_Up || e.key === Qt.Key_K) root.go(root.sel - 1);
            else if (e.key === Qt.Key_Down || e.key === Qt.Key_J) root.go(root.sel + 1);
            else if (e.key === Qt.Key_Right && stage.activeFocus) stage.nextItemInFocusChain(true)?.forceActiveFocus();
            else if (e.key === Qt.Key_Escape) root.close();
            else return;
            e.accepted = true;
        }

        // Sections list: selected section is enlarged with active cyan pill
        Column {
            x: 140 - 20 * (1 - root.t)
            anchors.verticalCenter: parent.verticalCenter
            spacing: 16
            Repeater {
                model: root.sections
                Row {
                    id: word
                    required property string modelData
                    required property int index
                    readonly property bool on: root.sel === index
                    spacing: 16
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: word.on
                        width: 5
                        height: 28
                        radius: 3
                        color: name.activeFocus ? Theme.fg : Theme.cyan
                    }
                    Text {
                        text: word.modelData
                        font.family: word.on ? Theme.title : Theme.ui
                        font.pixelSize: word.on ? 36 : 22
                        font.weight: word.on ? Font.Bold : Font.DemiBold
                        color: word.on ? Theme.fg : Theme.mute
                        Behavior on font.pixelSize { NumberAnimation { duration: Theme.t; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.glide } }
                        Behavior on color { ColorAnimation { duration: Theme.t } }
                    }
                    TapHandler { onTapped: root.go(word.index) }
                }
            }
        }

        Row {
            x: 150
            anchors { bottom: parent.bottom; bottomMargin: 70 }
            spacing: 34
            Lb { text: "↑↓ section" }
            Lb { text: "tab · ←→ change" }
            Lb { visible: !!text; text: root.hints[root.sel] }
            Lb { text: "esc close"; TapHandler { onTapped: root.close() } }
        }

        // ---- HOME: Bento canvas scaled to 168/220 — matches live layout, order, and packing.
        // Click to select, click again or Enter to cycle widget type, drag to reorder onto target cell.
        // Widgets exceeding the 3x3 grid display on the right as pale outline previews.
        // Multi-monitor displays monitor picker above canvas: each display maintains its own widget set ----
        Page {
            id: home
            k: 0
            caption: `home${root.multi ? ` · ${root.mon.toLowerCase()}${Theme.scr(root.mon, "home") ? "" : " · hidden there, display shows it"}` : ""}`
                + ` · bento 3 × 3 · ${used} of 9 cells`
            readonly property var cells: root.pack(root.list("widgets"))
            readonly property var placed: cells.filter(c => c.fits)
            readonly property var off: cells.filter(c => !c.fits)
            readonly property int used: placed.reduce((a, c) => a + c.span, 0)
            readonly property var cur_: cells[cur] ?? null
            property int cur: 0

            function tap(i) {
                grid.forceActiveFocus();
                cur = cur === i ? root.cycle("widgets", i, Object.keys(Theme.kinds)) : i;
            }
            // Reorder item dropped onto grid coordinate p: onto an existing widget swaps position; into empty cell moves behind last preceding item; out of bounds ignored
            function land(i, p) {
                if (p.x < 0 || p.y < 0 || p.x > grid.width || p.y > grid.height) return;
                const at = Math.min(2, Math.floor(p.y / 184)) * 3 + Math.min(2, Math.floor(p.x / 184));
                const hit = placed.find(c => c.row * 3 + c.col <= at && at < c.row * 3 + c.col + c.span);
                const n = placed.filter(c => c.row * 3 + c.col < at).length; // Placed widgets always occupy start of list
                cur = root.move("widgets", i, hit ? hit.i : i < n ? n - 1 : n);
            }

            Pick { visible: root.multi; label: "screen"; opts: root.names.map(n => n.toLowerCase()); cur: root.names.indexOf(root.mon); onPicked: i => root.pickMon = root.names[i] }

            Row {
                spacing: 60

                Item {
                    id: grid
                    width: 536
                    height: 536
                    activeFocusOnTab: true
                    Keys.onPressed: e => {
                        const c = root.nav(e, "widgets", home.cur, Object.keys(Theme.kinds));
                        if (c < 0) return;
                        home.cur = c;
                        e.accepted = true;
                    }
                    Repeater {
                        model: 9
                        Dots {
                            required property int index
                            x: index % 3 * 184
                            y: Math.floor(index / 3) * 184
                        }
                    }
                    Repeater {
                        model: home.placed
                        Tile {
                            x: modelData.col * 184
                            y: modelData.row * 184
                        }
                    }
                }

                Column {
                    width: 404
                    spacing: 12
                    Lb { text: "cells" }
                    Row {
                        spacing: 10
                        Num { id: usedN; text: home.used; font.pixelSize: 150 }
                        Num { anchors.baseline: usedN.baseline; text: "/9"; font.pixelSize: 54; color: Theme.mute }
                    }
                    Lb {
                        width: parent.width
                        elide: Text.ElideRight
                        text: !home.cur_ ? "empty · ↵ adds one" : `${home.cur_.id} · ${home.cur_.span} cell${home.cur_.span > 1 ? "s" : ""}${home.cur_.fits ? "" : " · off grid"}`
                    }
                    // Cat GIF selector (services/Gifs) — visible when 'cat' widget is active. Click or Left/Right to select
                    Column {
                        id: gifPick
                        visible: home.cur_?.id === "cat"
                        topPadding: 28
                        spacing: 12
                        Lb {
                            width: 404
                            elide: Text.ElideRight
                            text: `gif · ${Gifs.name(Gifs.cur)} · ${Gifs.sel + 1} of ${Gifs.list.length}`
                            color: gifStrip.activeFocus ? Theme.fg : Theme.grey
                        }
                        ListView {
                            id: gifStrip
                            width: 404
                            height: 58
                            orientation: ListView.Horizontal
                            spacing: (width - 6 * 58) / 5 // Exactly 6 items per row
                            clip: true
                            snapMode: ListView.SnapToItem
                            boundsBehavior: Flickable.StopAtBounds
                            keyNavigationEnabled: false
                            activeFocusOnTab: true
                            model: Gifs.list
                            currentIndex: Gifs.sel
                            onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)
                            Keys.onPressed: e => {
                                if (e.key === Qt.Key_Left) Gifs.step(-1);
                                else if (e.key === Qt.Key_Right) Gifs.step(1);
                                else return;
                                e.accepted = true;
                            }
                            delegate: Rectangle {
                                id: th
                                required property string modelData
                                required property int index
                                readonly property bool on: index === Gifs.sel
                                width: 58
                                height: 58
                                radius: Theme.corner(width * 0.18)
                                color: Theme.s1
                                border { width: on ? 2 : 1; color: on ? Theme.fg : Theme.s2 }
                                GifDots { anchors { fill: parent; margins: 6 } path: th.modelData; bg: th.color; playing: gifPick.visible && root.visible }
                                TapHandler {
                                    onTapped: {
                                        Gifs.pick(th.modelData);
                                        gifStrip.forceActiveFocus();
                                    }
                                }
                                HoverHandler { cursorShape: Qt.PointingHandCursor }
                            }
                        }
                    }
                    Item { width: 1; height: 40 }
                    Lb { text: home.off.length ? `off grid · ${home.off.length}` : "everything fits" }
                    Flow {
                        width: parent.width
                        spacing: 10
                        Repeater {
                            model: home.off
                            Tile { cell: 84; gap: 8 }
                        }
                    }
                }
            }

            Tray {
                ids: Object.keys(Theme.kinds)
                icons: root.icons
                used: root.list("widgets")
                dim: home.off.map(c => c.id)
                widths: Theme.kinds
                onToggled: key => home.cur = root.flip("widgets", key, home.cur)
            }
        }

        // ---- DECK: Screen preview with bottom-centered deck and right-edge Quick Settings; both revealable via edge hover.
        // Deck sections ordered to match panel layout; bottom tray contains available section types ----
        Page {
            id: deck
            k: 1
            caption: `deck · ${Theme.state.deck.length} of ${Theme.decks.length} sections · bottom edge`
            property int cur: 0
            // Drag state for section 'from' (-1 if inactive): dx is cursor delta in preview px, 'at' is current track pos, 'to' is target drop slot
            property int from: -1
            property real dx: 0
            readonly property real at: Math.max(10, Math.min(10 + (Theme.state.deck.length - 1) * 104, 10 + from * 104 + dx))
            readonly property int to: Math.round((at - 10) / 104)

            Row {
                spacing: 40

                Mini {
                    // Hot edge detection strips: bottom edge triggers Deck, right edge triggers Quick Settings
                    Seg {
                        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 8 }
                        width: 320
                        height: 4
                        n: 24
                        f: Theme.state.deckHover ? 1 : 0
                    }
                    Seg {
                        anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                        width: 4
                        height: 240
                        n: 16
                        vertical: true
                        f: Theme.state.quickHover ? 1 : 0
                    }

                    Rectangle {
                        id: strip
                        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 30 }
                        width: Math.max(1, Theme.state.deck.length) * 104 + 20
                        height: 116
                        radius: Theme.corner(40)
                        color: Theme.s1
                        border { width: 1; color: strip.activeFocus ? Theme.fg : Theme.s2 }
                        Behavior on width { NumberAnimation { duration: Theme.t; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.glide } }
                        activeFocusOnTab: true
                        Keys.onPressed: e => {
                            const c = root.nav(e, "deck", deck.cur, Theme.decks);
                            if (c < 0) return;
                            deck.cur = c;
                            e.accepted = true;
                        }

                        Lb { visible: !Theme.state.deck.length; anchors.centerIn: parent; text: "empty" }
                        Repeater {
                            model: Theme.state.deck
                            Item {
                                id: ds
                                required property string modelData
                                required property int index
                                readonly property bool on: deck.cur === index
                                readonly property bool hot: on && strip.activeFocus
                                // Drag reordering: dragged item follows cursor; items between source and target shift by one slot to make room
                                readonly property int slot: deck.from < 0 ? index
                                    : index > deck.from && index <= deck.to ? index - 1
                                    : index < deck.from && index >= deck.to ? index + 1 : index
                                x: dd.active ? deck.at : 10 + slot * 104
                                width: 104
                                height: strip.height
                                z: dd.active ? 1 : 0
                                Behavior on x {
                                    enabled: !dd.active
                                    NumberAnimation { duration: Theme.t; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.glide }
                                }

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 10
                                    Rectangle {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: 56
                                        height: 56
                                        radius: 28
                                        color: ds.hot ? Theme.fg : Theme.s2
                                        border { width: ds.on && !ds.hot ? 1 : 0; color: Theme.fg }
                                        Icon { anchors.centerIn: parent; text: root.icons[ds.modelData] ?? ""; font.pixelSize: 24; color: ds.hot ? Theme.ink : Theme.fg }
                                    }
                                    Lb { anchors.horizontalCenter: parent.horizontalCenter; text: ds.modelData; px: 10; color: ds.on ? Theme.fg : Theme.grey }
                                }
                                TapHandler {
                                    onTapped: {
                                        strip.forceActiveFocus();
                                        deck.cur = deck.cur === ds.index ? root.cycle("deck", ds.index, Theme.decks) : ds.index;
                                    }
                                }
                                DragHandler {
                                    id: dd
                                    target: null
                                    yAxis.enabled: false
                                    // Without explicit target, translation delta is in root scene pixels; divide by Stage scale Theme.s
                                    onActiveTranslationChanged: deck.dx = activeTranslation.x / Theme.s
                                    onActiveChanged: {
                                        if (active) {
                                            deck.cur = ds.index;
                                            deck.from = ds.index;
                                            return;
                                        }
                                        // Execute reordering after signal: list modification recreates delegates including this one
                                        const from = deck.from, to = deck.to;
                                        Qt.callLater(() => {
                                            deck.from = -1;
                                            deck.cur = root.move("deck", from, to);
                                        });
                                    }
                                }
                            }
                        }
                    }
                }

                Column {
                    spacing: 14
                    Toggle { width: 200; text: "deck · hover"; on: Theme.state.deckHover; onFlip: Theme.state.deckHover = !Theme.state.deckHover }
                    Toggle { width: 200; text: "quick · hover"; on: Theme.state.quickHover; onFlip: Theme.state.quickHover = !Theme.state.quickHover }
                    Lb { topPadding: 6; text: "bottom edge · right edge"; px: 10 }
                }
            }

            Tray {
                ids: Theme.decks
                icons: root.icons
                used: Theme.state.deck
                onToggled: key => deck.cur = root.flip("deck", key, deck.cur)
            }
        }

        // ---- BAR: Edge orientation previews with click to toggle. Tray items arranged matching live bar:
        // vertical stack when on left edge (labels beside icons), horizontal strip when on top edge (labels under icons); drag to reorder. Tray shows available items ----
        Page {
            id: bar
            k: 2
            caption: `bar · ${Theme.state.bar.length} of ${Theme.bars.length} in the tray · ${onTop ? "top" : "left"} edge`
            readonly property bool onTop: Theme.state.barAt === "top"
            readonly property real step: onTop ? 104 : 68 // Slot size along bar axis
            property int cur: 0
            // Drag state for item 'from' (-1 if inactive): d is cursor delta along bar axis in preview px, 'at' is track position, 'to' is target slot
            property int from: -1
            property real d: 0
            readonly property real at: Math.max(10, Math.min(10 + (Theme.state.bar.length - 1) * step, 10 + from * step + d))
            readonly property int to: Math.round((at - 10) / step)

            Grid {
                columns: bar.onTop ? 1 : 2
                columnSpacing: 200
                rowSpacing: 40

                Rectangle {
                    id: col
                    readonly property int n: Math.max(1, Theme.state.bar.length)
                    width: bar.onTop ? n * 104 + 20 : 88
                    height: bar.onTop ? 116 : n * 68 + 20
                    radius: Theme.corner(bar.onTop ? 40 : 44)
                    color: Theme.s1
                    border { width: 1; color: col.activeFocus ? Theme.fg : Theme.s2 }
                    Behavior on width { NumberAnimation { duration: Theme.t; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.glide } }
                    Behavior on height { NumberAnimation { duration: Theme.t; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.glide } }
                    activeFocusOnTab: true
                    Keys.onPressed: e => {
                        const c = root.nav(e, "bar", bar.cur, Theme.bars);
                        if (c < 0) return;
                        bar.cur = c;
                        e.accepted = true;
                    }

                    Lb { visible: !Theme.state.bar.length; anchors.centerIn: parent; text: "empty"; px: 10 }
                    Repeater {
                        model: Theme.state.bar
                        Item {
                            id: bs
                            required property string modelData
                            required property int index
                            readonly property bool on: bar.cur === index
                            readonly property bool hot: on && col.activeFocus
                            readonly property int slot: bar.from < 0 ? index
                                : index > bar.from && index <= bar.to ? index - 1
                                : index < bar.from && index >= bar.to ? index + 1 : index
                            // Position along bar axis: follows cursor during drag
                            property real pos: bd.active ? bar.at : 10 + slot * bar.step
                            Behavior on pos {
                                enabled: !bd.active
                                NumberAnimation { duration: Theme.t; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.glide }
                            }
                            x: bar.onTop ? pos : 0
                            y: bar.onTop ? 0 : pos
                            width: bar.onTop ? 104 : col.width
                            height: bar.onTop ? col.height : 68
                            z: bd.active ? 1 : 0

                            Rectangle {
                                id: bdot
                                x: (parent.width - width) / 2
                                y: bar.onTop ? 18 : (parent.height - height) / 2
                                width: 52
                                height: 52
                                radius: 26
                                color: bs.hot ? Theme.fg : Theme.s2
                                border { width: bs.on && !bs.hot ? 1 : 0; color: Theme.fg }
                                Icon { anchors.centerIn: parent; text: root.icons[bs.modelData] ?? ""; font.pixelSize: 22; color: bs.hot ? Theme.ink : Theme.fg }
                            }
                            Lb {
                                x: bar.onTop ? (parent.width - width) / 2 : parent.width + 24
                                y: bar.onTop ? bdot.y + bdot.height + 10 : (parent.height - height) / 2
                                text: bs.modelData
                                px: 10
                                color: bs.on ? Theme.fg : Theme.grey
                            }
                            TapHandler {
                                onTapped: {
                                    col.forceActiveFocus();
                                    bar.cur = bar.cur === bs.index ? root.cycle("bar", bs.index, Theme.bars) : bs.index;
                                }
                            }
                            DragHandler {
                                id: bd
                                target: null
                                xAxis.enabled: bar.onTop
                                yAxis.enabled: !bar.onTop
                                onActiveTranslationChanged: bar.d = (bar.onTop ? activeTranslation.x : activeTranslation.y) / Theme.s
                                onActiveChanged: {
                                    if (active) {
                                        bar.cur = bs.index;
                                        bar.from = bs.index;
                                        return;
                                    }
                                    const from = bar.from, to = bar.to;
                                    Qt.callLater(() => {
                                        bar.from = -1;
                                        bar.cur = root.move("bar", from, to);
                                    });
                                }
                            }
                        }
                    }
                }

                Column {
                    spacing: 14
                    Lb { text: "edge" }
                    // Edge orientation previews with pill indicator; Left/Right to switch
                    Row {
                        id: edges
                        spacing: 20
                        activeFocusOnTab: true
                        Keys.onPressed: e => {
                            if (e.key !== Qt.Key_Left && e.key !== Qt.Key_Right && e.key !== Qt.Key_Space && e.key !== Qt.Key_Return) return;
                            Theme.state.barAt = bar.onTop ? "left" : "top";
                            e.accepted = true;
                        }
                        Repeater {
                            model: ["left", "top"]
                            Column {
                                id: ed
                                required property string modelData
                                readonly property bool on: (modelData === "top") === bar.onTop
                                spacing: 10
                                Rectangle {
                                    width: 200
                                    height: 125
                                    radius: 18
                                    color: Theme.bg
                                    border { width: ed.on && edges.activeFocus ? 2 : 1; color: ed.on ? Theme.fg : Theme.s3 }
                                    Behavior on border.color { ColorAnimation { duration: Theme.t } }
                                    Rectangle {
                                        x: 10
                                        y: 10
                                        width: ed.modelData === "top" ? parent.width - 20 : 16
                                        height: ed.modelData === "top" ? 16 : parent.height - 20
                                        radius: Theme.corner(8)
                                        color: ed.on ? Theme.fg : Theme.s3
                                        Behavior on color { ColorAnimation { duration: Theme.t } }
                                    }
                                    TapHandler { onTapped: Theme.state.barAt = ed.modelData }
                                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                                }
                                Lb { anchors.horizontalCenter: parent.horizontalCenter; text: ed.modelData; px: 10; color: ed.on ? Theme.fg : Theme.grey }
                            }
                        }
                    }
                    Item { width: 1; height: 12 }
                    Toggle { width: 200; text: "window title"; on: Theme.state.barTitle; onFlip: Theme.state.barTitle = !Theme.state.barTitle }
                    Lb { topPadding: 6; text: bar.onTop ? "left of the clock" : "above the clock"; px: 10 }
                }
            }

            Tray {
                ids: Theme.bars
                icons: root.icons
                used: Theme.state.bar
                onToggled: key => bar.cur = root.flip("bar", key, bar.cur)
            }
        }

        // ---- LOOK: Miniature home screen preview reflecting toggle settings; custom greeting name input in pill ----
        Page {
            id: look
            k: 3
            caption: "look · the home screen, live"
            property bool dim: false // Colon blinking state
            Timer { running: look.visible && root.visible && Theme.state.blink; interval: 500; repeat: true; onTriggered: look.dim = !look.dim }

            Row {
                spacing: 40

                Mini {
                    Orb { visible: Theme.state.orb; x: 400; y: 110; scale: 330 / 1100; transformOrigin: Item.TopLeft }
                    Row {
                        x: 60
                        y: 52
                        Num { id: hrs; text: Theme.hh(clock.date); font.pixelSize: 120 }
                        Num { text: ":"; font.pixelSize: 120; opacity: Theme.state.blink && look.dim ? 0.2 : 1 }
                        Num { text: Qt.formatTime(clock.date, "mm"); font.pixelSize: 120 }
                        Lb { visible: !Theme.state.clock24; anchors.baseline: hrs.baseline; leftPadding: 12; text: clock.date.getHours() < 12 ? "am" : "pm" }
                    }
                    Lb { x: 64; y: 172; text: Qt.locale("en_US").toString(clock.date, "dddd · d MMMM"); px: 11 }
                    Text {
                        x: 62
                        y: 232
                        textFormat: Text.StyledText
                        text: `${root.hello},<br><font color="${Theme.grey}">${root.who}.</font>`
                        font { family: Theme.ui; pixelSize: 30; weight: Font.Light }
                        lineHeight: 1.1
                        color: Theme.fg
                    }
                    // Glyph edge meters: right side shows volume, bottom side shows progress
                    Seg { visible: Theme.state.edges; x: parent.width - 12; y: 140; width: 4; height: 200; n: 12; f: 0.6; vertical: true }
                    Seg { visible: Theme.state.edges; x: 230; y: parent.height - 10; width: 300; height: 4; n: 24; f: 0.4 }
                }

                Column {
                    spacing: 14
                    Toggle { width: 200; text: "light"; on: Theme.light; onFlip: Theme.setLight(!Theme.light) }
                    Toggle { width: 200; text: "dot grid"; on: Theme.state.grid; onFlip: Theme.state.grid = !Theme.state.grid }
                    Toggle { width: 200; text: "orb"; on: Theme.state.orb; onFlip: Theme.state.orb = !Theme.state.orb }
                    Toggle { width: 200; text: "24 hours"; on: Theme.state.clock24; onFlip: Theme.state.clock24 = !Theme.state.clock24 }
                    Toggle { width: 200; text: "blink"; on: Theme.state.blink; onFlip: Theme.state.blink = !Theme.state.blink }
                    Toggle { width: 200; text: "edges"; on: Theme.state.edges; onFlip: Theme.state.edges = !Theme.state.edges }
                    Act {
                        icon: "\u{F02E9}"
                        text: "wallpaper"
                        onHit: {
                            root.close();
                            root.wallRequested();
                        }
                    }
                }
            }

            // Custom greeting display name; falls back to $USER if blank
            Rectangle {
                width: 760
                height: 72
                radius: Theme.corner(36)
                color: Theme.s2
                border { width: name.activeFocus ? 1 : 0; color: Theme.fg }
                Lb { id: nameL; x: 30; anchors.verticalCenter: parent.verticalCenter; text: "name"; color: name.activeFocus ? Theme.fg : Theme.grey }
                TextInput {
                    id: name
                    anchors { left: nameL.right; leftMargin: 24; right: parent.right; rightMargin: 30; verticalCenter: parent.verticalCenter }
                    text: Theme.state.name
                    maximumLength: 24
                    activeFocusOnTab: true
                    font { family: Theme.ui; pixelSize: 24 }
                    color: Theme.fg
                    selectionColor: Theme.s3
                    clip: true
                    onTextEdited: Theme.state.name = text
                    cursorDelegate: Rectangle {
                        width: 2
                        color: name.activeFocus ? Theme.accent : "transparent"
                        Timer { running: name.activeFocus; interval: 500; repeat: true; onTriggered: parent.opacity = 1 - parent.opacity }
                    }
                    Text { visible: !name.text; text: Quickshell.env("USER"); font: name.font; color: Theme.mute }
                    Keys.onPressed: e => {
                        if (e.key === Qt.Key_Up || e.key === Qt.Key_Down) root.go(root.sel + (e.key === Qt.Key_Up ? -1 : 1));
                        else if (e.key === Qt.Key_Escape || e.key === Qt.Key_Return || e.key === Qt.Key_Enter) stage.forceActiveFocus();
                        else return;
                        e.accepted = true;
                    }
                }
            }
        }

        // ---- STYLE: Color palette configuration. Desktop preview reflects hovered or focused swatch (or active theme if none hovered):
        // bar, Quick Settings, kitty terminal, media player, Glyph bar. Callout lines indicate color role mappings.
        // Controls underneath configure source (nothing, wallpaper, palette preset) and light/dark theme;
        // source-specific options include dotted wallpaper swatch (click to open picker), tones/variants, or grouped palettes.
        // Selection options match launcher 'style' mode (Theme.styles). Swatches use indexed models to avoid recreating elements on update ----
        Page {
            id: tint
            k: 4
            property Item hot: null // Swatch currently hovered or focused
            readonly property var p: hot?.item.pal ?? Theme.pal
            readonly property string src: Theme.state.paint === "scheme" ? (Theme.pal.group === "more" ? "" : Theme.pal.group + " ") + Theme.pal.name
                : Theme.state.paint === "wall" && Theme.tones.length ? `wallpaper · ${Theme.pal.name}` : "nothing"
            caption: `style · ${src} · ${Theme.light ? "light" : "dark"}` + (hot && !hot.item.now ? `   →   ${hot.item.name} · ↵ sets it` : "")
            function block(h) { return Theme.styles.find(b => b.head === h)?.items ?? []; }
            function peek(sw) {
                if (sw.peek) hot = sw;
                else if (hot === sw) hot = null;
            }

            Desk { p: tint.p }

            Row {
                spacing: 24
                Pick {
                    label: "from"
                    opts: ["nothing", "wall", "palette"]
                    cur: ["", "wall", "scheme"].indexOf(Theme.state.paint)
                    onPicked: i => Theme.state.paint = ["", "wall", "scheme"][i]
                }
                Pick { label: "theme"; opts: ["dark", "light"]; cur: Theme.light ? 1 : 0; onPicked: i => Theme.setLight(i === 1) }
            }

            // Source-specific sub-options. Fixed minimum height prevents layout jumps when switching sources (Page is vertically centered).
            Item {
                width: 1040
                height: Math.max(300, own.height)
                Column {
                    id: own
                    spacing: 28
                    Lb { visible: !Theme.state.paint; text: "black · white dots · one red — nothing to pick"; color: Theme.mute }
                    Row {
                        visible: Theme.state.paint === "wall"
                        spacing: 34
                        // Dot-matrix wallpaper preview; click opens wallpaper picker
                        Rectangle {
                            width: 168
                            height: 105
                            radius: Theme.corner(14)
                            color: "transparent"
                            border { width: Theme.wall ? 0 : 1; color: Theme.s3 }
                            Image {
                                anchors.fill: parent
                                source: visible ? Theme.url(Theme.wallSrc(Theme.wall)) : "" // Defer texture loading when hidden
                                fillMode: Image.PreserveAspectCrop
                                sourceSize: Qt.size(336, 210)
                                asynchronous: true
                                layer.enabled: true
                                layer.effect: Dm { step: 4 }
                            }
                            Lb { visible: !Theme.wall; anchors.centerIn: parent; px: 10; text: "no wallpaper" }
                            TapHandler {
                                onTapped: {
                                    root.close();
                                    root.wallRequested();
                                }
                            }
                            HoverHandler { cursorShape: Qt.PointingHandCursor }
                        }
                        Column {
                            spacing: 6
                            Lb { text: Theme.tones.length ? "tones · from the wallpaper" : "no colour in it · click it for another" }
                            Row {
                                Repeater {
                                    model: tint.block("tones").length
                                    Swatch { id: tw; item: tint.block("tones")[index] ?? ({ name: "" }); onPeekChanged: tint.peek(tw) }
                                }
                            }
                        }
                    }
                    Column {
                        visible: Theme.state.paint === "wall" && Theme.tones.length > 0
                        spacing: 6
                        Lb { text: "variant · how much colour, like material you" }
                        Row {
                            Repeater {
                                model: tint.block("variant").length
                                Swatch { id: vw; item: tint.block("variant")[index] ?? ({ name: "" }); onPeekChanged: tint.peek(vw) }
                            }
                        }
                    }
                    // Grouped palette swatches — sections between source and theme
                    Flow {
                        visible: Theme.state.paint === "scheme"
                        width: 1040
                        spacing: 40
                        Repeater {
                            model: Theme.state.paint === "scheme" ? Theme.styles.length - 2 : 0
                            Column {
                                id: sb
                                required property int index
                                readonly property var block: Theme.styles[index + 1] ?? ({ head: "", items: [] })
                                spacing: 6
                                Lb { text: sb.block.head }
                                Row {
                                    Repeater {
                                        model: sb.block.items.length
                                        Swatch { id: pw; item: sb.block.items[index] ?? ({ name: "" }); onPeekChanged: tint.peek(pw) }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ---- WINDOWS: Desktop preview with two windows reflecting live dial values. Window resizing animates only if 'motion' is enabled ----
        Page {
            k: 5
            caption: `windows · hyprland · gaps ${gIn.v} / ${gOut.v} · border ${bord.v} · rounding ${rnd.v} · panels ${pan.v} %`

            Row {
                spacing: 40

                Mini {
                    id: desk
                    Repeater {
                        model: 2
                        Rectangle {
                            id: wnd
                            required property int index
                            readonly property real o: gOut.v * desk.k
                            readonly property real l: 78 * Theme.s * desk.k + o // 64px bar + 14px margin in logical pixels
                            readonly property real w: (desk.width - (at === "top" ? o : l) - o - 2 * gIn.v * desk.k) / 2
                            readonly property string at: Theme.state.barAt
                            x: (at !== "top" ? l : o) + (index ? w + 2 * gIn.v * desk.k : 0)
                            y: at === "top" ? l : o
                            width: w
                            height: desk.height - (at === "top" ? l : o) - o
                            radius: rnd.v * desk.k
                            color: Theme.s1
                            border { width: bord.v ? Math.max(1, bord.v * desk.k) : 0; color: index ? Theme.s3 : Theme.fg }
                            Behavior on x { enabled: root.r.motion; NumberAnimation { duration: Theme.t; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.glide } }
                            Behavior on y { enabled: root.r.motion; NumberAnimation { duration: Theme.t; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.glide } }
                            Behavior on width { enabled: root.r.motion; NumberAnimation { duration: Theme.t; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.glide } }
                            Behavior on height { enabled: root.r.motion; NumberAnimation { duration: Theme.t; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.glide } }

                            Column {
                                x: 20
                                y: 20
                                spacing: 9
                                Lb { text: wnd.index ? "zen" : "kitty"; px: 10; color: wnd.index ? Theme.mute : Theme.grey }
                                Repeater {
                                    model: [0.7, 0.45, 0.85, 0.3, 0.6, 0.5]
                                    Rectangle {
                                        required property real modelData
                                        width: (wnd.width - 40) * modelData
                                        height: 5
                                        radius: 2.5
                                        color: Theme.s3
                                    }
                                }
                            }
                        }
                    }
                }

                // Technical note: Blur and shadows are not visible in the flat black preview — exposed as toggles only
                Column {
                    spacing: 14
                    Toggle { width: 200; text: "blur"; on: root.r.blur; onFlip: { root.r.blur = !root.r.blur; Theme.apply(); } }
                    Toggle { width: 200; text: "shadow"; on: root.r.shadow; onFlip: { root.r.shadow = !root.r.shadow; Theme.apply(); } }
                    Toggle { width: 200; text: "motion"; on: root.r.motion; onFlip: { root.r.motion = !root.r.motion; Rules.motion(); } }
                }
            }

            Row {
                spacing: 40
                Dial { id: gIn; label: "gaps in"; to: 30; value: root.r.gapsIn; onMoved: v => { root.r.gapsIn = v; Theme.apply(); } }
                Dial { id: gOut; label: "gaps out"; to: 60; value: root.r.gapsOut; onMoved: v => { root.r.gapsOut = v; Theme.apply(); } }
                Dial { id: bord; label: "border"; to: 6; n: 24; value: root.r.border; onMoved: v => { root.r.border = v; Theme.apply(); } }
                Dial { id: rnd; label: "rounding"; to: 40; value: Theme.state.rounding; onMoved: v => Theme.state.rounding = v } // shell.qml handles Theme.apply call internally
                Dial { id: pan; label: "panels"; to: 100; step: 5; value: Theme.state.corners; onMoved: v => Theme.state.corners = v } // Shell corner radius percentage
            }
        }

        // ---- DISPLAY: Multi-monitor arrangement according to Hyprland (click or Left/Right to select).
        // Settings below apply to selected monitor: brightness (built-in panel), logical resolution, scaling, refresh rate,
        // bar and home widget toggles. Night light applies globally to all displays ----
        Page {
            id: disp
            k: 6
            readonly property var m: Rules.mons.find(x => x.name === root.mon) ?? Rules.mon
            readonly property var w: Rules.want(m)
            caption: `display · ${m.name.toLowerCase()} · ${m.w} × ${m.h} · ${m.hz} hz`

            Row {
                spacing: 60
                Column {
                    z: 1 // Display drag elevated above brightness dial
                    spacing: 22
                    Item {
                        id: map
                        readonly property var ms: Rules.mons
                        // Display drag state 'held': 'at' stores target logical coordinates; held until Hyprland updates monitor state
                        property string held: ""
                        property var at: null
                        onMsChanged: held = ""
                        readonly property real x0: Math.min(...ms.map(m => m.x))
                        readonly property real y0: Math.min(...ms.map(m => m.y))
                        readonly property real bw: Math.max(...ms.map(m => m.x + m.lw)) - x0
                        readonly property real bh: Math.max(...ms.map(m => m.y + m.lh)) - y0
                        readonly property real k: Math.min(width / bw, height / bh)
                        width: 560
                        height: 320
                        activeFocusOnTab: true
                        Keys.onPressed: e => {
                            const d = e.key === Qt.Key_Left ? -1 : e.key === Qt.Key_Right ? 1 : 0, n = root.names.length;
                            if (!d || !n) return;
                            root.pickMon = root.names[(root.names.indexOf(root.mon) + d + n) % n];
                            e.accepted = true;
                        }
                        Repeater {
                            model: map.ms
                            Rectangle {
                                id: sc
                                required property var modelData
                                readonly property bool on: modelData.name === root.mon
                                readonly property var p: map.held === modelData.name && map.at ? map.at : modelData
                                x: (map.width - map.bw * map.k) / 2 + (p.x - map.x0) * map.k + 5
                                y: (map.height - map.bh * map.k) / 2 + (p.y - map.y0) * map.k + 5
                                z: map.held === modelData.name ? 1 : 0
                                width: modelData.lw * map.k - 10
                                height: modelData.lh * map.k - 10
                                radius: Theme.corner(18)
                                color: Theme.bg
                                border { width: sc.on && map.activeFocus ? 2 : 1; color: sc.on ? Theme.fg : Theme.s3 }
                                Behavior on border.color { ColorAnimation { duration: Theme.t } }
                                Image {
                                    anchors { fill: parent; margins: 12 }
                                    fillMode: Image.Tile
                                    source: "data:image/svg+xml," + encodeURIComponent(`<svg xmlns="http://www.w3.org/2000/svg" width="10" height="10"><circle cx="5" cy="5" r="1.5" fill="#${Theme.hex(sc.on ? Theme.mute : Theme.s2)}"/></svg>`)
                                }
                                Column {
                                    anchors.centerIn: parent
                                    spacing: 6
                                    Lb { anchors.horizontalCenter: parent.horizontalCenter; text: sc.modelData.name; color: sc.on ? Theme.fg : Theme.grey }
                                    Lb { anchors.horizontalCenter: parent.horizontalCenter; text: `${sc.modelData.w} × ${sc.modelData.h}`; px: 10 }
                                }
                                TapHandler {
                                    onTapped: {
                                        root.pickMon = sc.modelData.name;
                                        map.forceActiveFocus();
                                    }
                                }
                                HoverHandler { cursorShape: root.multi ? Qt.OpenHandCursor : Qt.PointingHandCursor }
                                // Drag snaps to neighbor boundaries (Rules.dock); release applies via Rules.place.
                                // Drag is locked while waiting for Hyprland to confirm previous placement to prevent desync against outdated positions.
                                // Translation delta is scaled by Stage factor Theme.s
                                DragHandler {
                                    target: null
                                    enabled: root.multi && (!map.held || active)
                                    cursorShape: Qt.ClosedHandCursor
                                    onActiveTranslationChanged: {
                                        if (!active) return;
                                        const m = sc.modelData, k = Theme.s * map.k;
                                        map.at = Rules.dock({ x: m.x + activeTranslation.x / k, y: m.y + activeTranslation.y / k, w: m.lw, h: m.lh },
                                                           map.ms.filter(o => o.name !== m.name), 16 / map.k);
                                    }
                                    onActiveChanged: {
                                        const m = sc.modelData;
                                        if (active) {
                                            root.pickMon = m.name;
                                            map.at = null;
                                            map.held = m.name;
                                            return;
                                        }
                                        if (map.at && (map.at.x !== m.x || map.at.y !== m.y)) Rules.place(m.name, map.at.x, map.at.y);
                                        else map.held = "";
                                    }
                                }
                            }
                        }
                    }
                    Row {
                        spacing: 14
                        Num { id: resW; text: disp.m.lw; font.pixelSize: 72 }
                        Num { anchors.baseline: resW.baseline; text: "×"; font.pixelSize: 40; color: Theme.mute }
                        Num { anchors.baseline: resW.baseline; text: disp.m.lh; font.pixelSize: 72 }
                    }
                    Lb { text: "logical pixels" }
                }
                // Backlight control available for built-in panels; external DDC/CI monitors are not supported (services/Backlight)
                Column {
                    visible: Sys.hasBri && disp.m.name === Rules.mon.name
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 22
                    Dial { anchors.horizontalCenter: parent.horizontalCenter; size: 300; n: 60; live: true; label: "brightness"; value: Math.round(Sys.bri * 100); onMoved: v => Sys.setBri(v / 100) }
                    // Brightness key step increment (divisions per scale: Backlight.steps)
                    Pick { anchors.horizontalCenter: parent.horizontalCenter; label: "step"; opts: ["2.5%", "5%", "10%"]; cur: [40, 20, 10].indexOf(Theme.state.briSteps); onPicked: i => Theme.state.briSteps = [40, 20, 10][i] }
                }
            }
            Row {
                spacing: 24
                Pick { label: "scale"; opts: Rules.scales; cur: disp.w.scale ? Rules.scales.indexOf(String(disp.w.scale)) : 0; onPicked: i => Rules.set(disp.m.name, "scale", i ? +Rules.scales[i] : 0) }
                // Refresh rates segmented to prevent wide displays (e.g. 5-8 refresh rates on high-end monitors/TVs) from overflowing canvas
                Pick { label: "hz"; seg: Math.min(104, 416 / opts.length); opts: disp.m.rates.map(String); cur: disp.m.rates.indexOf(disp.w.refresh); onPicked: i => Rules.set(disp.m.name, "refresh", disp.m.rates[i]) }
            }
            // Single-monitor fallback: if bar was disabled while docked and laptop is un-docked, it can be re-enabled here
            Row {
                spacing: 20
                Toggle { text: "bar"; on: Theme.scr(root.mon, "bar"); onFlip: Theme.setScr(root.mon, "bar", !on) }
                Toggle { text: "home"; on: Theme.scr(root.mon, "home"); onFlip: Theme.setScr(root.mon, "home", !on) }
                Lb { anchors.verticalCenter: parent.verticalCenter; leftPadding: 10; text: "on this screen · its widgets — in home" }
                // Reset custom external monitor positions, scaling, and refresh rates back to Hyprland defaults (Rules.forget)
                Act { visible: Object.keys(Rules.store.outs).length > 0; icon: "\u{F0450}"; text: "hypr config"; onHit: Rules.forget() }
            }
            Row {
                spacing: 40
                Toggle { anchors.verticalCenter: parent.verticalCenter; text: "night light"; on: Sys.night; onFlip: Sys.toggleNight() }
                Dial { label: "warmth · k · all screens"; from: 2500; to: 6500; step: 100; value: root.r.warmth; onMoved: v => { root.r.warmth = v; if (root.r.night) Rules.night(); } }
            }
        }

        // ---- AUDIO: output and input — volume, mute, level, the default device (prefs/Audio) ----
        Page {
            id: audioPage
            k: 7
            caption: aud.caption
            Audio { id: aud; live: audioPage.visible && root.shown }
        }

        // ---- POWER: Power profiles (Rules.modes) — four circular presets, ring gauge indicates intensity, selected is highlighted white.
        // Ultra mode sets power saver, locks refresh rate to 60 Hz, and disables animations, blur, and window shadows ----
        Page {
            k: 8
            caption: `power · ${Rules.modes[Rules.mode].what} · ${Rules.hz} hz`

            Row {
                spacing: 32
                Repeater {
                    model: Rules.modes.slice(0, Rules.modeCount)
                    Rectangle {
                        id: pc
                        required property var modelData
                        required property int index
                        readonly property bool on: Rules.mode === index
                        width: 230
                        height: 230
                        radius: 115
                        color: on ? Theme.fg : Theme.s1
                        border { width: activeFocus ? 2 : 1; color: activeFocus || on ? Theme.fg : Theme.s2 }
                        Behavior on color { ColorAnimation { duration: Theme.t } }
                        activeFocusOnTab: true
                        Keys.onPressed: e => {
                            if (e.key !== Qt.Key_Return && e.key !== Qt.Key_Enter && e.key !== Qt.Key_Space) return;
                            Rules.setMode(index);
                            e.accepted = true;
                        }
                        Ring { anchors { fill: parent; margins: 14 } n: 40; dot: 6; f: (pc.index + 1) / 4; on: pc.on ? Theme.ink : Theme.fg; off: pc.on ? Theme.mute : Theme.s3 }
                        Column {
                            anchors.centerIn: parent
                            spacing: 10
                            Num { anchors.horizontalCenter: parent.horizontalCenter; text: pc.modelData.short; font.pixelSize: 54; color: pc.on ? Theme.ink : Theme.fg }
                            Lb { anchors.horizontalCenter: parent.horizontalCenter; text: pc.modelData.name; color: pc.on ? Theme.ink : Theme.grey }
                        }
                        TapHandler { onTapped: Rules.setMode(pc.index) }
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                    }
                }
            }
            Lb { text: Rules.store.ultra ? `ultra · ${Rules.rates[0]} hz, no motion, no blur, no shadows — your settings come back when you leave` : "cpu profile only · hz, motion and looks stay yours" }
            Lb { visible: !PowerProfiles.hasPerformanceProfile; text: "no performance profile on this machine" }
        }

        // ---- INPUT: Key repeat demonstration: first key press immediate, repeat delay pause, followed by rate per second; animated dials ----
        Page {
            id: inp
            k: 9
            caption: "input · keyboard · touchpad"
            property int n: 0 // Count of simulated characters typed; 0 = key released
            Timer {
                running: inp.visible && root.visible
                repeat: true
                interval: inp.n === 0 ? 700 : inp.n === 1 ? delay.v : 1000 / rate.v
                onTriggered: inp.n = (inp.n + 1) % 41
            }

            Row {
                spacing: 30
                Rectangle {
                    width: 110
                    height: 110
                    radius: 30
                    color: inp.n ? Theme.fg : Theme.s1
                    border { width: 1; color: Theme.s2 }
                    Num { anchors.centerIn: parent; text: "A"; font.pixelSize: 54; color: inp.n ? Theme.ink : Theme.fg }
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 16
                    Row {
                        spacing: 6
                        Repeater {
                            model: 40
                            Rectangle {
                                required property int index
                                width: 14
                                height: 14
                                radius: 7
                                color: index < inp.n ? Theme.fg : Theme.s2
                            }
                        }
                    }
                    Lb { text: `hold a key · first, ${delay.v} ms, then ${rate.v} a second` }
                }
            }
            Row {
                spacing: 40
                Dial { id: delay; label: "delay · ms"; from: 150; to: 600; step: 10; value: root.r.repeatDelay; onMoved: v => { root.r.repeatDelay = v; Rules.input(); } }
                Dial { id: rate; label: "rate · /s"; from: 10; to: 60; value: root.r.repeatRate; onMoved: v => { root.r.repeatRate = v; Rules.input(); } }
                Dial { label: "scroll · %"; from: 10; to: 100; step: 5; value: root.r.scroll; onMoved: v => { root.r.scroll = v; Rules.input(); } }
                Dial { label: "pointer"; from: -100; to: 100; step: 5; value: root.r.sens; onMoved: v => { root.r.sens = v; Rules.input(); } }
            }
            Row {
                spacing: 20
                Toggle { text: "natural scroll"; on: root.r.natural; onFlip: { root.r.natural = !root.r.natural; Rules.input(); } }
                Toggle { text: "tap to click"; on: root.r.tap; onFlip: { root.r.tap = !root.r.tap; Rules.input(); } }
                Toggle { text: "off while typing"; on: root.r.typingOff; onFlip: { root.r.typingOff = !root.r.typingOff; Rules.input(); } }
                Toggle { text: "flat accel"; on: root.r.flat; onFlip: { root.r.flat = !root.r.flat; Rules.input(); } }
            }
            Pick { label: "layout switch"; opts: Rules.switches.map(s => s[0]); cur: root.r.kbSwitch; onPicked: i => { root.r.kbSwitch = i; Rules.input(); } }
        }

        // ---- IDLE: Inactivity timeline in minutes. Dots dim progressively at each state transition: awake -> locked -> screen off -> asleep.
        // Markers can be dragged along the timeline; positions past 60 min represent 'never' ----
        Page {
            k: 10

            Item {
                id: line
                width: 1000
                height: 300
                readonly property var at: [lk.v, dpms.v, zz.v]

                Repeater {
                    model: 61
                    Rectangle {
                        required property int index
                        readonly property int lvl: line.at.filter(m => m && m <= index).length
                        x: index * 15 - 4
                        y: 246
                        width: 8
                        height: 8
                        radius: 4
                        color: [Theme.fg, Theme.grey, Theme.mute, Theme.s3][lvl]
                    }
                }
                // 'never' setting represented by an empty ring past the timeline
                Rectangle { x: 62 * 15 - 7; y: 243; width: 14; height: 14; radius: 7; color: "transparent"; border { width: 1; color: Theme.mute } }
                Repeater {
                    model: [0, 15, 30, 45, 60]
                    Lb { required property int modelData; x: modelData * 15 - width / 2; y: 272; text: modelData; px: 10 }
                }
                Lb { x: 62 * 15 - width / 2; y: 272; text: "never"; px: 10 }

                Mark { id: lk; row: 0; label: "lock"; value: root.r.lockAfter; onMoved: v => { root.r.lockAfter = v; Rules.idle(); } }
                Mark { id: dpms; row: 1; label: "screen off"; value: root.r.dpmsAfter; onMoved: v => { root.r.dpmsAfter = v; Rules.idle(); } }
                Mark { id: zz; row: 2; label: Rules.hibernateOn ? "sleep · hibernate" : "sleep"; value: root.r.sleepAfter; onMoved: v => { root.r.sleepAfter = v; Rules.idle(); } }
            }
            Row {
                spacing: 26
                Repeater {
                    model: [["awake", Theme.fg], ["locked", Theme.grey], ["dark", Theme.mute], ["asleep", Theme.s3]]
                    Row {
                        required property var modelData
                        spacing: 10
                        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 8; height: 8; radius: 4; color: parent.modelData[1] }
                        Lb { text: parent.modelData[0]; px: 10 }
                    }
                }
            }
            Row {
                spacing: 24
                Pick { label: "sleep into"; visible: Rules.canHibernate; opts: ["suspend", "hibernate"]; cur: root.r.hibernate ? 1 : 0; onPicked: i => { root.r.hibernate = i === 1; Rules.idle(); } }
                Toggle { text: "caffeine"; on: Sys.caffeine; onFlip: Sys.caffeine = !Sys.caffeine }
            }
        }

        // ---- SHELL: Rice insignia and active shell info; switch shells using the Rice switcher app ----
        Page {
            k: 11
            caption: "shell · quickshell"

            Row {
                spacing: 50
                Item {
                    width: 260
                    height: 260
                    Ring { anchors.fill: parent; n: 16; dot: 14; f: 1 }
                    Rectangle { anchors.centerIn: parent; width: 52; height: 52; radius: 26; color: Theme.fg }
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 18
                    Lb { text: "running now" }
                    Num { text: root.meta.name ?? "GLYPH"; font.pixelSize: 140 }
                    Lb { text: root.meta.tagline ?? "" }
                }
            }
            Row {
                spacing: 20
                Act {
                    visible: root.shells > 1
                    icon: "\u{F04E1}"
                    text: "switch shell"
                    onHit: {
                        root.close();
                        Quickshell.execDetached(["qs", "-c", "rice"]);
                    }
                }
                Act { icon: "\u{F0450}"; text: "reload"; onHit: Quickshell.reload(false) }
                Toggle { text: "do not disturb"; on: Theme.state.dnd; onFlip: Theme.state.dnd = !Theme.state.dnd }
            }
        }

        // ---- CORNERS: macOS Hot Corners Manager ----
        Page {
            k: 12
            caption: "hot corners · desktop automation"

            readonly property var actionLabels: ({
                none: "— (Disabled)",
                quicknote: "Quick Note",
                missioncontrol: "Mission Control",
                quick: "Control Center",
                launcher: "Spotlight Search",
                deck: "Dashboard / Deck",
                lock: "Lock Screen",
                shot: "Take Screenshot"
            })
            readonly property var actionKeys: ["none", "quicknote", "missioncontrol", "quick", "launcher", "deck", "lock", "shot"]

            function cycle(pos) {
                const hc = Object.assign({}, Theme.state.hotCorners || {});
                const cur = hc[pos] || "none";
                const nextIdx = (actionKeys.indexOf(cur) + 1) % actionKeys.length;
                hc[pos] = actionKeys[nextIdx];
                Theme.state.hotCorners = hc;
            }

            Item {
                width: 760
                height: 380

                // Central Monitor Mockup
                Rectangle {
                    id: monScreen
                    anchors.centerIn: parent
                    width: 440
                    height: 270
                    radius: 18
                    color: Theme.s2
                    border.width: 1.5
                    border.color: Theme.s3

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 4
                        radius: 14
                        color: Qt.rgba(13 / 255, 16 / 255, 23 / 255, 0.85)
                    }

                    Rectangle {
                        anchors { top: parent.top; left: parent.left; right: parent.right; margins: 8 }
                        height: 12
                        radius: 6
                        color: Qt.rgba(255, 255, 255, 0.12)
                    }

                    Rectangle {
                        anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: 8 }
                        width: 130
                        height: 12
                        radius: 6
                        color: Qt.rgba(255, 255, 255, 0.12)
                    }

                    // 4 glowing corner indicators
                    Rectangle {
                        anchors { top: parent.top; left: parent.left; margins: 4 }
                        width: 28; height: 28; radius: 14
                        color: Theme.cyan; opacity: hovTL.containsMouse ? 0.8 : 0.2
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }
                    Rectangle {
                        anchors { top: parent.top; right: parent.right; margins: 4 }
                        width: 28; height: 28; radius: 14
                        color: Theme.cyan; opacity: hovTR.containsMouse ? 0.8 : 0.2
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }
                    Rectangle {
                        anchors { bottom: parent.bottom; left: parent.left; margins: 4 }
                        width: 28; height: 28; radius: 14
                        color: Theme.cyan; opacity: hovBL.containsMouse ? 0.8 : 0.2
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }
                    Rectangle {
                        anchors { bottom: parent.bottom; right: parent.right; margins: 4 }
                        width: 28; height: 28; radius: 14
                        color: Theme.cyan; opacity: hovBR.containsMouse ? 0.8 : 0.2
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }
                }

                // Top-Left Pill
                Rectangle {
                    id: btnTL
                    anchors { right: monScreen.left; top: monScreen.top; rightMargin: 14 }
                    width: 180; height: 38; radius: 19
                    color: hovTL.containsMouse ? Theme.s1 : Theme.s2
                    border.width: 1; border.color: hovTL.containsMouse ? Theme.cyan : Theme.s3

                    Row {
                        anchors.centerIn: parent; spacing: 6
                        Text { text: "\u{F053}"; font.family: Theme.nf; font.pixelSize: 10; color: Theme.cyan; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: parent.parent.parent.parent.actionLabels[Theme.state.hotCorners?.topLeft ?? "none"]; font.family: Theme.ui; font.pixelSize: 11; font.weight: Font.DemiBold; color: Theme.fg; anchors.verticalCenter: parent.verticalCenter }
                    }
                    MouseArea {
                        id: hovTL; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: parent.parent.parent.cycle("topLeft")
                    }
                }

                // Top-Right Pill
                Rectangle {
                    id: btnTR
                    anchors { left: monScreen.right; top: monScreen.top; leftMargin: 14 }
                    width: 180; height: 38; radius: 19
                    color: hovTR.containsMouse ? Theme.s1 : Theme.s2
                    border.width: 1; border.color: hovTR.containsMouse ? Theme.cyan : Theme.s3

                    Row {
                        anchors.centerIn: parent; spacing: 6
                        Text { text: parent.parent.parent.parent.actionLabels[Theme.state.hotCorners?.topRight ?? "quick"]; font.family: Theme.ui; font.pixelSize: 11; font.weight: Font.DemiBold; color: Theme.fg; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: "\u{F054}"; font.family: Theme.nf; font.pixelSize: 10; color: Theme.cyan; anchors.verticalCenter: parent.verticalCenter }
                    }
                    MouseArea {
                        id: hovTR; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: parent.parent.parent.cycle("topRight")
                    }
                }

                // Bottom-Left Pill
                Rectangle {
                    id: btnBL
                    anchors { right: monScreen.left; bottom: monScreen.bottom; rightMargin: 14 }
                    width: 180; height: 38; radius: 19
                    color: hovBL.containsMouse ? Theme.s1 : Theme.s2
                    border.width: 1; border.color: hovBL.containsMouse ? Theme.cyan : Theme.s3

                    Row {
                        anchors.centerIn: parent; spacing: 6
                        Text { text: "\u{F053}"; font.family: Theme.nf; font.pixelSize: 10; color: Theme.cyan; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: parent.parent.parent.parent.actionLabels[Theme.state.hotCorners?.bottomLeft ?? "missioncontrol"]; font.family: Theme.ui; font.pixelSize: 11; font.weight: Font.DemiBold; color: Theme.fg; anchors.verticalCenter: parent.verticalCenter }
                    }
                    MouseArea {
                        id: hovBL; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: parent.parent.parent.cycle("bottomLeft")
                    }
                }

                // Bottom-Right Pill
                Rectangle {
                    id: btnBR
                    anchors { left: monScreen.right; bottom: monScreen.bottom; leftMargin: 14 }
                    width: 180; height: 38; radius: 19
                    color: hovBR.containsMouse ? Theme.s1 : Theme.s2
                    border.width: 1; border.color: hovBR.containsMouse ? Theme.cyan : Theme.s3

                    Row {
                        anchors.centerIn: parent; spacing: 6
                        Text { text: parent.parent.parent.parent.actionLabels[Theme.state.hotCorners?.bottomRight ?? "quicknote"]; font.family: Theme.ui; font.pixelSize: 11; font.weight: Font.DemiBold; color: Theme.fg; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: "\u{F054}"; font.family: Theme.nf; font.pixelSize: 10; color: Theme.cyan; anchors.verticalCenter: parent.verticalCenter }
                    }
                    MouseArea {
                        id: hovBR; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: parent.parent.parent.cycle("bottomRight")
                    }
                }
            }

            Lb { text: "click any corner pill to cycle actions · dwell in that screen corner for 200ms to trigger" }
        }
    }

    // Right-side page container: only active section is visible (Tab navigation restricted to visible items), slides up on entrance
    component Page: Column {
        required property int k
        property string caption
        x: 800
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: visible ? 0 : 24
        visible: root.sel === k
        opacity: visible ? 1 : 0
        spacing: 28
        Behavior on opacity { NumberAnimation { duration: Theme.t; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.glide } }
        Behavior on anchors.verticalCenterOffset { NumberAnimation { duration: Theme.t; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.glide } }
        Lb { text: parent.caption }
    }

    // Miniature 16:10 display preview: wallpaper (dot-grid pattern if enabled) and status bar; k maps logical display pixels to preview pixels
    component Mini: Rectangle {
        readonly property real k: width / (Rules.mon.w ? Rules.mon.w / Rules.scale : Quickshell.screens[0]?.width ?? 1920)
        width: 760
        height: 475
        radius: 24
        color: Theme.bg
        border { width: 1; color: Theme.s3 }
        Image {
            visible: Theme.state.grid
            anchors { fill: parent; margins: 12 }
            fillMode: Image.Tile
            source: "data:image/svg+xml," + encodeURIComponent(`<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16"><circle cx="8" cy="8" r="1" fill="#${Theme.hex(Theme.s2)}"/></svg>`)
        }
        // Edge-pinned status bar: 14px margin and 64px width in preview pixels; corresponds to Theme.s logical pixels
        Rectangle {
            readonly property real u: Theme.s * parent.k
            readonly property bool onTop: Theme.state.barAt === "top"
            x: 14 * u
            y: 14 * u
            width: onTop ? parent.width - 28 * u : 64 * u
            height: onTop ? 64 * u : parent.height - 28 * u
            radius: Theme.corner(Math.min(width, height) / 2)
            color: Theme.s1
            border { width: 1; color: Theme.s2 }
        }
    }

    // Empty Bento cell placeholder: 4x4 dot matrix
    component Dots: Grid {
        columns: 4
        padding: 30
        spacing: 28
        Repeater {
            model: 16
            Rectangle { width: 6; height: 6; radius: 3; color: Theme.s3 }
        }
    }

    // Home widget preview: circle or 40px rounded square (scaled), dot-matrix icon, name.
    // Selected widget has a white border; focused has solid white fill; overflowing widgets show dim outline
    component Tile: Rectangle {
        id: tile
        required property var modelData // { id, i, row, col, span, fits }
        property real cell: 168
        property real gap: 16
        readonly property bool on: home.cur === modelData.i
        readonly property bool hot: on && grid.activeFocus
        readonly property bool round: root.rounds.includes(modelData.id)
        width: modelData.span * cell + (modelData.span - 1) * gap
        height: cell
        radius: round ? cell / 2 : Theme.corner(cell * 0.18)
        color: hot ? Theme.fg : modelData.fits ? Theme.s1 : "transparent"
        border { width: on ? 2 : 1; color: on ? Theme.fg : modelData.fits ? Theme.s2 : Theme.mute }
        z: drag.active ? 1 : 0
        // Drag delta scaled by Stage factor Theme.s
        readonly property real dx: drag.activeTranslation.x / Theme.s
        readonly property real dy: drag.activeTranslation.y / Theme.s
        transform: Translate { x: drag.active ? tile.dx : 0; y: drag.active ? tile.dy : 0 }
        Behavior on color { ColorAnimation { duration: Theme.t } }

        Ring {
            visible: tile.round && tile.cell > 100
            anchors { fill: parent; margins: 10 }
            n: 40
            dot: 4
            f: 0.66
            on: tile.hot ? Theme.ink : Theme.fg
            off: tile.hot ? Theme.fade(Theme.ink, 0.15) : Theme.s3
        }
        Column {
            anchors.centerIn: parent
            spacing: 10
            Icon {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.icons[tile.modelData.id] ?? "?"
                font.pixelSize: tile.cell * 0.26
                color: tile.hot ? Theme.ink : tile.modelData.fits ? Theme.fg : Theme.grey
                layer.enabled: true
                layer.effect: Dm { step: 3 }
            }
            Lb { visible: tile.cell > 100; anchors.horizontalCenter: parent.horizontalCenter; text: tile.modelData.id; px: 10; color: tile.hot ? Theme.ink : Theme.grey }
        }
        TapHandler { onTapped: home.tap(tile.modelData.i) }
        // Drop handled asynchronously after signal: list reordering recreates tile delegates including this instance
        DragHandler {
            id: drag
            target: null
            onActiveChanged: {
                if (active) {
                    home.cur = tile.modelData.i;
                    return;
                }
                const p = grid.mapFromItem(tile.parent, tile.x + tile.width / 2 + tile.dx, tile.y + tile.height / 2 + tile.dy);
                Qt.callLater(home.land, tile.modelData.i, p);
            }
        }
    }

    // Idle marker: guide line to timeline, Doto formatted minutes, and state label. Drag along track; Left/Right adjusts by 1 minute; >60 = never (0).
    // Updates internal 'v' while dragging; commits to rules.json and hypridle upon release or after 400ms debounce
    component Mark: Item {
        id: mk
        property int row
        property string label
        property int value
        property int v: value
        signal moved(int v)
        function put(m) {
            m = m > 60.5 ? 0 : Math.max(1, Math.round(m));
            if (m === v) return;
            v = m;
            wait.restart();
        }
        onValueChanged: if (!ma.pressed && !wait.running) v = value
        Timer { id: wait; interval: 400; onTriggered: if (!ma.pressed && mk.v !== mk.value) mk.moved(mk.v) }

        x: (v || 62) * 15
        y: row * 76
        width: 160
        height: 250 - y
        activeFocusOnTab: true
        Keys.onPressed: e => {
            if (e.key === Qt.Key_Left) put(v ? v - 1 : 60);
            else if (e.key === Qt.Key_Right) put(v ? v + 1 : 61);
            else return;
            e.accepted = true;
        }
        Behavior on x { NumberAnimation { duration: 120 } }

        Rectangle { width: 1; height: parent.height; color: mk.activeFocus || ma.pressed ? Theme.fg : Theme.mute }
        Column {
            x: 12
            Num { text: mk.v || "—"; font.pixelSize: 44 }
            Lb { topPadding: 6; text: mk.label; px: 10; color: mk.activeFocus ? Theme.fg : Theme.grey }
        }
        MouseArea {
            id: ma
            width: parent.width
            height: 76
            preventStealing: true
            cursorShape: Qt.SizeHorCursor
            onPressed: mk.forceActiveFocus()
            onPositionChanged: e => mk.put(mapToItem(line, e.x, 0).x / 15)
            onReleased: {
                wait.stop();
                if (mk.v !== mk.value) mk.moved(mk.v);
            }
        }
    }

    // Action button: pill shape with circular icon container. Click, Enter, or Space to activate
    component Act: Rectangle {
        id: act
        property string icon
        property string text
        signal hit
        width: actL.implicitWidth + 110
        height: 64
        radius: Theme.corner(32)
        color: Theme.s2
        border { width: activeFocus ? 1 : 0; color: Theme.fg }
        activeFocusOnTab: true
        Keys.onPressed: e => {
            if (e.key !== Qt.Key_Return && e.key !== Qt.Key_Enter && e.key !== Qt.Key_Space) return;
            act.hit();
            e.accepted = true;
        }
        Rectangle {
            x: 6
            y: 6
            width: 52
            height: 52
            radius: 26
            color: Theme.s3
            Icon { anchors.centerIn: parent; text: act.icon; font.pixelSize: 22 }
        }
        Lb { id: actL; x: 76; anchors.verticalCenter: parent.verticalCenter; text: act.text; color: act.activeFocus ? Theme.fg : Theme.grey }
        TapHandler { onTapped: act.hit() }
    }
}

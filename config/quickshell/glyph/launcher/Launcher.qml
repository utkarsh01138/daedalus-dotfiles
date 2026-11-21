import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs
import qs.components

// Application launcher: Super tap or Super+Space. 860px centered panel, screen dims to 74% opacity.
// Search pill with red caret, mode selection chips (Tab): apps / style / windows / calc.
// With an empty query — "recent" section and all applications arranged in a 6-column grid, alphabet index on the right.
// 'style' mode — color schemes, similar to Caelestia scheme picker: source (Nothing, wallpaper, or palette presets),
// wallpaper tones and variants (tonal spot, etc.) or palette presets (Catppuccin, Rosé Pine, etc.),
// and theme styles (Theme.styles, matching STYLE in settings). Circles represent color swatches, dot marks the active scheme,
// and Enter applies the style without closing the launcher. Palette searches match group names (e.g., "catppuccin").
// Entrance animation matches Charms and Clip: 24px slide-up and fade. Icons are rendered with dot-matrix stylization inside circular discs; selected item has a white circle indicator.
PanelWindow {
    id: root

    property int mode: 0
    property int sel: 0
    readonly property var modes: ["apps", "style", "windows", "calc"]
    readonly property string query: input.text
    property var uses: ({}) // App ID -> launch frequency count

    // Theme icon or path from .desktop; if unavailable, falls back to generic app icon rather than an empty circle
    function icon(name) { return Quickshell.iconPath(name || "application-x-executable", "application-x-executable"); }

    // On startup, DesktopEntries emits events for entries individually (~160 valuesChanged events):
    // re-evaluating the grid binding on each would cause multi-second freezes. Debounced until the list settles.
    property var apps: []
    Timer {
        id: appsT
        interval: 300
        running: true
        onTriggered: root.apps = DesktopEntries.applications.values.filter(e => !e.noDisplay).map(e => ({
            id: e.id, name: e.name, src: root.icon(e.icon),
            extra: `${e.id} ${e.genericName} ${(e.keywords ?? []).join(" ")}`.toLowerCase(), run: () => e.execute()
        })).sort((a, b) => a.name.localeCompare(b.name))
    }
    Connections {
        target: DesktopEntries.applications
        function onValuesChanged() { appsT.restart(); }
    }
    // Window list — only populated while 'windows' mode is active to prevent every title change from rebuilding the list
    readonly property var wins: !visible || mode !== 2 ? [] : Hyprland.toplevels.values.map(t => {
        const cls = t.lastIpcObject?.class ?? "";
        return { name: t.title, src: icon(DesktopEntries.heuristicLookup(cls)?.icon), extra: cls.toLowerCase(),
                 run: () => { focusT.addr = t.address; focusT.restart(); } };
    })
    // While the launcher holds exclusive keyboard focus (WlrKeyboardFocus.Exclusive), Hyprland switches workspace
    // but defers window focus — once keyboard focus is released, it would snap back to the previous window and workspace.
    // Therefore, window focus is dispatched after releasing keyboard focus (applied on the subsequent frame).
    // Technical detail: 100ms timer provides sufficient frame headroom; alternatively handled via onVisibleChanged post-fade.
    Timer {
        id: focusT
        property string addr
        interval: 100
        onTriggered: Hyprland.dispatch(`hl.dsp.focus({ window = "address:0x${addr}" })`) // Quickshell provides address without 0x prefix
    }

    // Subsequence matching: prefix and contiguous matches score higher. 'hl' contains indices of matching characters.
    function match(s, q) {
        if (!q) return { score: 1, hl: [] };
        const l = s.toLowerCase(), hl = [], at = l.indexOf(q);
        if (at >= 0) { for (let k = 0; k < q.length; k++) hl.push(at + k); return { score: (at === 0 ? 100 : 50) - at, hl }; }
        let i = 0;
        for (const c of q) {
            i = l.indexOf(c, i);
            if (i < 0) return null;
            hl.push(i++);
        }
        return { score: 10, hl };
    }
    function filter(src, q) {
        const out = [];
        for (const it of src) {
            const m = match(it.name, q);
            if (m) out.push(Object.assign({}, it, { hl: m.hl, score: m.score }));
            else if (it.extra.includes(q)) out.push(Object.assign({}, it, { hl: [], score: 1 }));
        }
        return out.sort((a, b) => b.score - a.score || (uses[b.id] ?? 0) - (uses[a.id] ?? 0));
    }

    // Blocks layout: { head, sub, items }; each cell is assigned row/col coordinates for arrow navigation.
    readonly property var blocks: {
        const q = query.trim().toLowerCase();
        let b;
        if (mode === 1) b = Theme.styles.map(x => ({ head: x.head, items: filter(x.items.map(it => Object.assign({ extra: "", keep: true }, it)), q) })).filter(x => x.items.length);
        else if (mode === 3) b = [];
        else if (mode === 2) b = [{ head: "windows", sub: String(wins.length), items: filter(wins, q) }];
        else if (q) {
            const r = filter(apps, q);
            const cmdItems = [];
            const rawQ = query.trim();
            if (rawQ.startsWith(">") || r.length === 0 || rawQ.includes(" ") || rawQ.includes("-") || ["shader", "mnemosyne", "btop", "htop", "kitty"].includes(rawQ)) {
                const cmd = rawQ.startsWith(">") ? rawQ.slice(1).trim() : rawQ;
                cmdItems.push({
                    id: "cmd-exec",
                    name: cmd,
                    isCmd: true,
                    src: root.icon("utilities-terminal"),
                    extra: "terminal",
                    run: (inKitty) => {
                        if (inKitty) {
                            Quickshell.execDetached(["kitty", "-e", "sh", "-c", cmd + "; exec fish"]);
                        } else {
                            Quickshell.execDetached(["sh", "-c", cmd]);
                        }
                    }
                });
            }
            b = [];
            if (root.calcOut && !root.calcOut.startsWith("error") && !root.calcOut.includes("failed")) {
                b.push({
                    head: "calculation",
                    items: [{
                        id: "calc-result",
                        name: root.calcOut,
                        isCalc: true,
                        src: root.icon("accessories-calculator"),
                        extra: "calc",
                        run: () => {
                            Quickshell.execDetached(["wl-copy", root.calcOut]);
                            root.close();
                        }
                    }]
                });
            }
            if (cmdItems.length && (rawQ.startsWith(">") || r.length === 0)) {
                b.push({ head: "commands", items: cmdItems });
            }
            if (r.length) {
                b.push({ head: "results", sub: String(r.length), items: r });
            }
            if (cmdItems.length && !rawQ.startsWith(">") && r.length > 0) {
                b.push({ head: "run as command", items: cmdItems });
            }
        } else {
            const recent = apps.filter(a => uses[a.id]).sort((a, b) => uses[b.id] - uses[a.id]).slice(0, 6);
            b = (recent.length ? [{ head: "recent", items: recent }] : []).concat([{ head: "all apps", sub: String(apps.length), all: true, items: apps }]);
        }
        let row = 0, k = 0;
        for (const x of b) {
            x.items = x.items.map((it, i) => Object.assign({}, it, { row: row + Math.floor(i / 6), col: i % 6, k: k++ }));
            row += Math.ceil(x.items.length / 6);
        }
        return b;
    }
    readonly property var flat: blocks.reduce((a, x) => a.concat(x.items), [])
    readonly property var cur: flat[sel] ?? null

    property bool shown: false
    property real t: shown ? 1 : 0
    Behavior on t { NumberAnimation { duration: Theme.t; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.glide } }

    function open() {
        focusT.stop(); // Prevent lingering focus timer from a previous open from stealing focus from the launcher
        input.text = "";
        mode = 0;
        sel = 0;
        flick.contentY = 0;
        shown = true;
        input.forceActiveFocus();
    }
    function close() { shown = false; }
    function toggle() { shown ? close() : open(); }
    function move(dr, dc) {
        if (!flat.length) return;
        if (dc) return sel = (sel + dc + flat.length) % flat.length;
        const c = cur, row = flat.filter(x => x.row === c.row + dr);
        if (row.length) sel = row.reduce((a, x) => Math.abs(x.col - c.col) < Math.abs(a.col - c.col) ? x : a).k;
    }
    function launch(inKitty) {
        if (!shown) return; // Ignores extra clicks during Theme.t fade-out (e.g., double-clicks triggering a second window launch)
        if (mode === 3 || (mode === 0 && calcOut && (!cur || cur.isCalc))) {
            if (calcOut) Quickshell.execDetached(["wl-copy", calcOut]);
            return close();
        }
        const it = cur;
        if (!it) {
            const rawQ = query.trim();
            if (rawQ) {
                const cmd = rawQ.startsWith(">") ? rawQ.slice(1).trim() : rawQ;
                if (inKitty) {
                    Quickshell.execDetached(["kitty", "-e", "sh", "-c", cmd + "; exec fish"]);
                } else {
                    Quickshell.execDetached(["sh", "-c", cmd]);
                }
                close();
            }
            return;
        }
        if (it.isCmd) {
            it.run(inKitty);
            return close();
        }
        if (it.keep) return it.run();
        close();
        if (it.id) {
            uses = Object.assign({}, uses, { [it.id]: (uses[it.id] ?? 0) + 1 });
            usesFile.setText(JSON.stringify(uses));
        }
        it.run();
    }

    FileView {
        id: usesFile
        path: Quickshell.statePath("launcher-uses.json")
        printErrors: false
        onLoaded: try { root.uses = JSON.parse(text()); } catch (e) {}
    }

    property string calcOut: ""
    property string calcTemp: ""
    Process {
        id: calc
        stdout: StdioCollector { onStreamFinished: root.calcTemp = text.trim() }
        onExited: code => {
            const out = root.calcTemp.toLowerCase();
            root.calcOut = (code === 0 && !out.startsWith("error") && !out.includes("failed")) ? root.calcTemp : "";
        }
    }
    onQueryChanged: {
        sel = 0;
        const q = query.trim();
        if (q && !q.startsWith(">") && (mode === 3 || /[0-9+\-*\/^%=$]|to\s|in\s|usd|inr|eur|gbp|jpy|sin|cos|tan|sqrt|pi/i.test(q))) {
            calc.exec(["qalc", "-t", q.replace(/^[=>\s]+/, "")]);
        } else {
            calcOut = "";
            calcTemp = "";
        }
    }
    onModeChanged: { sel = 0; flick.contentY = 0; if (mode === 3) queryChanged(); }
    // Clamp selection index if list shrinks without a query change (e.g., a window closes in 'windows' mode)
    onFlatChanged: sel = Math.max(0, Math.min(sel, flat.length - 1))

    onVisibleChanged: if (visible) input.forceActiveFocus()

    visible: t > 0
    anchors { left: true; right: true; top: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "glyph-launcher"

    Rectangle {
        anchors.fill: parent
        color: Theme.scrim
        opacity: root.t
        MouseArea { anchors.fill: parent; onClicked: root.close() }
    }

    Stage {
        id: stage

        Rectangle {
            id: panel
            x: (stage.width - width) / 2
            y: 140 + 24 * (1 - root.t)
            width: 860
            height: Math.min(stage.height - 280, 30 + 66 + 20 + body.height + 34)
            opacity: root.t
            radius: Theme.corner(44)
            color: Theme.s1
            border { width: 1; color: Theme.s2 }
            MouseArea { anchors.fill: parent }

            // Search input: pill container, red cursor caret, mode selector chips
            Rectangle {
                id: search
                x: 34
                y: 30
                width: parent.width - 68
                height: 66
                radius: Theme.corner(33)
                color: Theme.s2

                Icon { id: lens; x: 24; anchors.verticalCenter: parent.verticalCenter; text: "\u{F0349}"; color: Theme.grey; font.pixelSize: 22 }
                TextInput {
                    id: input
                    anchors { left: lens.right; leftMargin: 16; right: chips.left; rightMargin: 12; verticalCenter: parent.verticalCenter }
                    font { family: Theme.ui; pixelSize: 22 }
                    color: Theme.fg
                    selectionColor: Theme.s3
                    clip: true
                    cursorDelegate: Rectangle {
                        width: 2
                        color: Theme.accent
                        Timer { running: input.activeFocus; interval: 500; repeat: true; onTriggered: parent.opacity = 1 - parent.opacity }
                    }
                    Text {
                        visible: !input.text
                        x: 6
                        text: ["Search apps", "Color from nothing, the wallpaper or a palette", "Find a window", "2 + 2, 20 usd to eur…"][root.mode]
                        font: input.font
                        color: Theme.mute
                    }
                    Keys.onPressed: e => {
                        const shift = e.modifiers & Qt.ShiftModifier;
                        if (e.key === Qt.Key_Escape) root.close();
                        else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) root.launch(shift);
                        else if (e.key === Qt.Key_Tab) root.mode = (root.mode + 1) % 4;
                        else if (e.key === Qt.Key_Backtab) root.mode = (root.mode + 3) % 4;
                        else if (e.key === Qt.Key_Down) root.move(1, 0);
                        else if (e.key === Qt.Key_Up) root.move(-1, 0);
                        else if (e.key === Qt.Key_Right && (!input.text || input.cursorPosition === input.text.length) && root.flat.length) root.move(0, 1);
                        else if (e.key === Qt.Key_Left && (!input.text || input.cursorPosition === 0) && root.flat.length) root.move(0, -1);
                        else return;
                        e.accepted = true;
                    }
                }
                Row {
                    id: chips
                    anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                    spacing: 6
                    Repeater {
                        model: root.modes
                        Rectangle {
                            required property string modelData
                            required property int index
                            width: chip.width + 32
                            height: chip.height + 20
                            radius: height / 2
                            color: root.mode === index ? Theme.fg : "transparent"
                            Lb { id: chip; anchors.centerIn: parent; text: parent.modelData; px: 11; color: root.mode === parent.index ? Theme.ink : Theme.grey }
                            TapHandler { onTapped: { root.mode = parent.index; input.forceActiveFocus(); } }
                        }
                    }
                }
            }

            Flickable {
                id: flick
                anchors { left: parent.left; right: parent.right; top: search.bottom; bottom: parent.bottom; topMargin: 20; leftMargin: 34; rightMargin: 34; bottomMargin: 34 }
                contentHeight: body.height
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                function ensure(y, h) {
                    if (y < contentY) contentY = Math.max(0, y);
                    else if (y + h > contentY + height) contentY = y + h - height;
                }

                Column {
                    id: body
                    width: flick.width

                    // Calculator mode & Live omni-search calculation
                    Column {
                        visible: root.mode === 3 || (root.mode === 0 && !!root.calcOut && !root.calcOut.startsWith("error") && !root.calcOut.includes("failed"))
                        topPadding: 10
                        spacing: root.mode === 3 ? 10 : 4
                        Lb { text: root.calcOut ? (root.mode === 3 ? "↵ copy" : "↵ copy calculation") : "qalc" }
                        Num { width: body.width; elide: Text.ElideRight; text: root.calcOut || "—"; font.pixelSize: root.mode === 3 ? 96 : 48 }
                    }

                    // Indexed model rather than array binding: query changes, app launches, or recent list updates
                    // reuse existing ~160 cell instances, icons, and layers rather than reallocating them
                    Repeater {
                        id: blockRep
                        model: root.blocks.length

                        Column {
                            id: block
                            required property int index
                            readonly property var modelData: root.blocks[index] ?? ({ head: "", items: [] })
                            readonly property Item g: grid
                            width: body.width
                            topPadding: index ? 30 : 10 // +20px top flick margin: scrolled content cuts off cleanly below search pill

                            Row {
                                spacing: 14
                                bottomPadding: 18
                                // Doto font letter range indicator: visible letters currently in view
                                Num { visible: !!block.modelData.all; anchors.baseline: blab.baseline; text: root.range; font.pixelSize: 34 }
                                Lb { id: blab; text: block.modelData.head + (block.modelData.sub ? ` · ${block.modelData.sub}` : "") }
                            }
                            Grid {
                                id: grid
                                columns: 6
                                rowSpacing: 22
                                Repeater {
                                    model: block.modelData.items.length
                                    Cell { items: block.modelData.items; gy: block.y + grid.y }
                                }
                            }
                        }
                    }
                }
            }

            // Alphabet index on right: letters visible in view are highlighted white, click scrolls to first match
            Column {
                visible: root.mode === 0 && !root.query && !!root.allGrid
                anchors { right: parent.right; rightMargin: 12; top: parent.top; topMargin: 130 }
                spacing: 3
                Repeater {
                    model: [..."ABCDEFGHIJKLMNOPQRSTUVWXYZ"]
                    Text {
                        required property string modelData
                        width: 12
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData
                        font { family: Theme.mono; pixelSize: 10 }
                        color: root.range.includes(modelData) ? Theme.fg : Theme.mute
                        TapHandler { onTapped: root.jump(parent.modelData) }
                    }
                }
            }
        }
    }

    // Letter range for visible application rows in view: e.g., "A–F"
    readonly property var allItems: blocks.find(b => b.all)?.items ?? []
    readonly property Item allGrid: { const i = blocks.findIndex(b => b.all); return blockRep.count > i && i >= 0 ? blockRep.itemAt(i)?.g ?? null : null; }
    readonly property string range: {
        if (!allGrid || !allItems.length) return "";
        const top = allGrid.mapToItem(body, 0, 0).y, rh = 88 + 10 + 20 + 22; // Circle height, spacing, label, row gap
        const r0 = Math.max(0, Math.floor((flick.contentY - top) / rh)), r1 = Math.floor((flick.contentY + flick.height - top) / rh);
        const seen = allItems.slice(r0 * 6, (r1 + 1) * 6).map(a => a.name[0].toUpperCase());
        return seen.length ? seen[0] === seen[seen.length - 1] ? seen[0] : `${seen[0]}–${seen[seen.length - 1]}` : "";
    }
    function jump(l) {
        const i = allItems.findIndex(a => a.name[0].toUpperCase() >= l);
        if (i < 0) return;
        sel = allItems[i].k;
        flick.contentY = Math.min(Math.max(0, flick.contentHeight - flick.height), allGrid.mapToItem(body, 0, 0).y + Math.floor(i / 6) * (88 + 10 + 20 + 22));
    }

    // Application cell: 88px circle with glyph or dot-matrix icon; label highlights matching letters in white
    component Cell: Column {
        id: cell
        required property int index
        property var items: []
        readonly property var modelData: items[index] ?? ({ name: "", hl: [] })
        readonly property bool on: root.sel === modelData.k
        // Quickshell recreates the layer-shell window on each open, and Image loads textures even when hidden:
        // 160 active icons cost ~60ms of initial frame time. Off-screen cells (beyond one row buffer) are kept lightweight
        // without an image while preserving layout height.
        property real gy // Grid Y offset within body container
        readonly property bool near: gy + y < flick.contentY + flick.height + 140 && gy + y + height > flick.contentY - 140
        width: body.width / 6
        height: 88 + spacing + label.implicitHeight
        spacing: 10
        onOnChanged: if (on) flick.ensure(mapToItem(body, 0, 0).y - 8, height + 8) // 8px swatch ring buffer above disc

        Rectangle {
            id: disc
            visible: cell.near
            anchors.horizontalCenter: parent.horizontalCenter
            width: 88
            height: 88
            radius: 44
            color: cell.modelData.fill ?? (cell.on ? Theme.fg : Theme.s2)
            border { width: cell.modelData.fill ? 1 : 0; color: Theme.s3 } // Dark border for swatches on panel background
            // Swatch highlight ring around selected item: avoids white fill which would mask swatch color. 'dot' shows current palette accent
            Rectangle { visible: cell.on && !!cell.modelData.fill; anchors.centerIn: parent; width: 104; height: 104; radius: 52; color: "transparent"; border { width: 2; color: Theme.fg } }
            Rectangle { id: inner; visible: !!cell.modelData.dot; anchors.centerIn: parent; width: 40; height: 40; radius: 20; color: cell.modelData.dot ?? "transparent" }
            Rectangle { visible: !!cell.modelData.now; anchors.centerIn: parent; width: 14; height: 14; radius: 7; color: Theme.on(inner.visible ? inner.color : disc.color) }
            Image {
                anchors.centerIn: parent
                visible: status === Image.Ready
                width: 44
                height: 44
                source: cell.near ? cell.modelData.src ?? "" : ""
                sourceSize: Qt.size(44, 44)
                asynchronous: true
                retainWhileLoading: true // Retain previous icon when cell content changes until new icon finishes loading
                layer.enabled: cell.near // Disable layer rendering for off-screen cells
                layer.effect: Dm { step: 2.5 }
            }
            TapHandler { onTapped: { root.sel = cell.modelData.k; root.launch(); } }
            HoverHandler { cursorShape: Qt.PointingHandCursor }
        }
        Text {
            id: label
            visible: cell.near
            width: parent.width - 8
            anchors.horizontalCenter: parent.horizontalCenter
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            textFormat: Text.StyledText
            readonly property var hl: cell.modelData.hl ?? []
            text: [...cell.modelData.name].map((c, i) => {
                const e = c === "<" ? "&lt;" : c === "&" ? "&amp;" : c;
                return hl.includes(i) ? `<font color="${Theme.fg}">${e}</font>` : e;
            }).join("")
            font { family: Theme.ui; pixelSize: 14 }
            color: cell.on ? Theme.fg : Theme.grey
        }
    }
}

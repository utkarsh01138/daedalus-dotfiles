import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.Notifications
import Quickshell.Wayland
import qs
import qs.components
import qs.settings
import qs.services

// Quick Settings: Super+A or tray click. 470px panel at the right edge, pinned to the bottom, slides in from the right:
// clock, Wi-Fi/Bluetooth pills, circular tiles, sliders (filled portion is a white pill, empty portion is dots), mini-player, notifications.
// Windows behind the panel dim to 35% opacity.
PanelWindow {
    id: root

    signal powerRequested
    signal settingsRequested

    property bool open: false
    // peeked — opened via hover on the right edge (Hot): does not grab keyboard focus; auto-closes once the cursor leaves the panel
    property bool peeked: false
    function toggle() { peeked = false; open = !open; }
    function close() { open = false; }
    // Clicking inside pins the panel: subsequent closing works normally (Esc, click outside); hover state no longer governs dismissal
    function pin() { peeked = false; }
    function peek() {
        if (open) return;
        peeked = true;
        open = true;
    }
    // Open picker sub-menu: "wifi" | "bt" — under pills (Picker), "rec" — under tiles (Rec), "" — none
    property string pick: ""
    onOpenChanged: if (open) { Sys.earRun([]); Sys.queryShader(); } else pick = ""
    // Closes when the cursor stays outside the panel and Hot strip for 500ms.
    // 'seen': Hyprland does not assign cursor focus to a newly mapped surface until the mouse moves;
    // before the first motion event its position is unknown, so the panel waits (preventing an instant open-and-close cycle for a stationary cursor)
    Timer { interval: 500; running: root.open && root.peeked && seen.hovered && !keep.hovered && !edge.hovered; onTriggered: root.close() }

    property real t: open ? 1 : 0
    Behavior on t { NumberAnimation { duration: Theme.t; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.glide } }

    visible: t > 0
    anchors { left: true; right: true; top: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open && !peeked ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "glyph-quick"

    readonly property var wifi: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var net: wifi?.networks.values.find(n => n.connected) ?? null
    readonly property var bt: Bluetooth.defaultAdapter
    readonly property var btDev: Bluetooth.devices.values.find(d => d.connected) ?? null
    SystemClock { id: clock; precision: SystemClock.Minutes }

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: 0.35 * root.t
        MouseArea { anchors.fill: parent; onClicked: root.close() }
    }

    Stage {
        id: stage
        HoverHandler { id: seen }
        // Hover zone: panel plus edge strip — cursor at the extreme border is not considered "left", preventing
        // an instant close/reopen loop. Panel is inside the zone rather than a sibling: button HoverHandlers
        // (power modes, Picker rows) suppress sibling hover underneath them, but not ancestor hover
        Item {
            anchors { right: parent.right; bottom: parent.bottom }
            width: panel.width + panel.anchors.rightMargin
            height: panel.height + 14
            HoverHandler { id: keep }
            Rectangle {
                id: panel
                anchors { right: parent.right; rightMargin: 14 - 24 * (1 - root.t); bottom: parent.bottom; bottomMargin: 14 }
                width: 470
                height: col.height + 44
                opacity: root.t
                radius: 0
                color: Theme.s1
                border { width: 1; color: Theme.accent }
                focus: true
                Keys.onEscapePressed: root.close()
                MouseArea { anchors.fill: parent } // Clicking inside the panel does not dismiss it

                Column {
                    id: col
                    x: 22
                    y: 22
                    width: parent.width - 44
                    spacing: 16

                    Item {
                        id: notifHeader
                        width: parent.width
                        height: 20
                        visible: Notes.list.length > 0
                        Lb { x: 6; text: `notifications · ${Notes.list.length}` }
                        Lb {
                            anchors.right: parent.right
                            rightPadding: 6
                            visible: Notes.list.length > 0
                            text: "clear all"
                            color: Theme.fg
                            TapHandler { onTapped: { root.pin(); Notes.clear(); } }
                        }
                    }

                    // Notification cards, newest on top; scrollable when content overflows
                    ListView {
                        id: notes
                        width: parent.width
                        visible: Notes.list.length > 0
                        height: visible ? Math.min(shown, Math.max(80, stage.height - 28 - 44 - controls.height - (notifHeader.visible ? 36 : 0))) : 0
                        property real shown: contentHeight
                        Behavior on shown { enabled: Rules.moving; NumberAnimation { duration: Theme.t; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.glide } }
                        clip: true
                        spacing: 10
                        model: Notes.list.slice().reverse()
                        boundsBehavior: Flickable.StopAtBounds

                        delegate: Rectangle {
                            required property var modelData
                            readonly property var n: modelData
                            width: notes.width
                            height: body.height + 32
                            radius: Theme.corner(26)
                            color: Theme.s2
                            border { width: n.urgency === NotificationUrgency.Critical ? 1 : 0; color: Theme.red }

                            Rectangle {
                                x: 18
                                y: 16
                                width: 42
                                height: 42
                                radius: 21
                                color: Theme.s3
                                Icon { anchors.centerIn: parent; text: "\u{F009A}"; visible: !nicon.visible }
                                Image {
                                    id: nicon
                                    anchors.centerIn: parent
                                    width: 24
                                    height: 24
                                    visible: status === Image.Ready
                                    source: n.appIcon ? Quickshell.iconPath(n.appIcon, true) : ""
                                    sourceSize: Qt.size(24, 24)
                                    layer.enabled: true
                                    layer.effect: Dm { step: 2 }
                                }
                            }
                            Column {
                                id: body
                                x: 74
                                y: 16
                                width: parent.width - x - 18
                                Lb { width: parent.width; elide: Text.ElideRight; text: `${n.appName || "app"} · ${Notes.ago(n, clock.date.getTime())}`; px: 11 }
                                Text { textFormat: Text.PlainText; width: parent.width; elide: Text.ElideRight; text: n.summary; font { family: Theme.ui; pixelSize: 15; weight: Font.DemiBold } color: Theme.fg }
                                Text {
                                    width: parent.width
                                    visible: !!n.body
                                    topPadding: 2
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 3
                                    elide: Text.ElideRight
                                    textFormat: Text.PlainText
                                    text: n.body
                                    font { family: Theme.ui; pixelSize: 14 }
                                    color: Theme.grey
                                }
                            }
                            TapHandler {
                                onTapped: {
                                    root.pin();
                                    const it = n;
                                    it.actions.find(a => a.identifier === "default")?.invoke();
                                    if (it.tracked) it.dismiss();
                                }
                            }
                        }
                    }

                    Column {
                        id: controls
                        width: parent.width
                        spacing: 16

                    Item {
                        width: parent.width
                        height: 54
                        Row {
                            x: 6
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 14
                            Num { anchors.verticalCenter: parent.verticalCenter; text: `${Theme.hh(clock.date)}:${Qt.formatTime(clock.date, "mm")}`; font.pixelSize: 44 }
                            Lb { anchors.verticalCenter: parent.verticalCenter; text: Qt.locale("en_US").toString(clock.date, "ddd d MMM") }
                        }
                        Row {
                            anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
                            spacing: 14
                            Round { icon: "\u{F0493}"; onClicked: { root.close(); root.settingsRequested(); } } // Settings; shells are configured via their respective SHELL
                            Round { icon: "\u{F0425}"; onClicked: { root.close(); root.powerRequested(); } }
                        }
                    }

                    Row {
                        width: parent.width
                        spacing: 12
                        Pill {
                            on: Networking.wifiEnabled
                            icon: on ? "\u{F05A9}" : "\u{F05AA}"
                            name: "Wi-Fi"
                            sub: !on ? "off" : (Networking.connectivity === NetworkConnectivity.Portal ? "sign in · " : "") + (root.net?.name ?? "no network")
                            picked: root.pick === "wifi"
                            onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
                            onMenu: root.pick = picked ? "" : "wifi"
                        }
                        Pill {
                            on: root.bt?.enabled ?? false
                            icon: on ? "\u{F00AF}" : "\u{F00B2}"
                            name: "Bluetooth"
                            sub: !on ? "off" : root.btDev?.name ?? "on"
                            picked: root.pick === "bt"
                            onClicked: if (root.bt) root.bt.enabled = !root.bt.enabled
                            onMenu: root.pick = picked ? "" : "bt"
                        }
                    }

                    Picker { width: parent.width; kind: root.pick; onTouched: root.pin() }

                    // Nothing / CMF earbuds (Sys.ear): device name and battery levels, with ANC mode selector underneath (styled like power modes)
                    Column {
                        visible: !!Sys.ear
                        width: parent.width
                        spacing: 10
                        Item {
                            width: parent.width
                            height: 20
                            Lb { x: 6; text: Sys.buds?.name ?? "" }
                            Lb {
                                anchors.right: parent.right
                                rightPadding: 6
                                text: ["l", "r", "case"].filter(k => Sys.ear?.[k] !== undefined).map(k => `${k} ${Sys.ear[k]}`).join(" · ")
                                color: Theme.fg
                            }
                        }
                        Rectangle {
                            id: anc
                            width: parent.width
                            height: 54
                            radius: Theme.corner(27)
                            color: Theme.s2
                            readonly property real cell: (width - 12) / Sys.ancModes.length
                            readonly property int at: Sys.ancModes.findIndex(m => m[0] === Sys.ear?.mode)
                            Rectangle {
                                visible: anc.at >= 0
                                x: 6 + anc.cell * anc.at
                                y: 6
                                width: anc.cell
                                height: parent.height - 12
                                radius: height / 2
                                color: Theme.fg
                                Behavior on x { NumberAnimation { duration: Theme.t; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.glide } }
                            }
                            Repeater {
                                model: Sys.ancModes
                                Item {
                                    id: am
                                    required property var modelData
                                    required property int index
                                    x: 6 + anc.cell * index
                                    width: anc.cell
                                    height: anc.height
                                    Lb { anchors.centerIn: parent; text: am.modelData[1]; color: anc.at === am.index ? Theme.ink : Theme.grey }
                                    TapHandler { onTapped: { root.pin(); Sys.setAnc(am.modelData[0]); } }
                                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                                }
                            }
                        }
                    }

                    Grid {
                        width: parent.width
                        columns: 4
                        rowSpacing: 14
                        Tile { icon: "\u{F009B}"; name: "dnd"; on: Theme.state.dnd; onClicked: Theme.state.dnd = !Theme.state.dnd }
                        Tile { icon: "\u{F0594}"; name: "night"; on: Sys.night; onClicked: Sys.toggleNight() }
                        Tile { icon: "\u{F001D}"; name: "airplane"; on: Sys.air; onClicked: Sys.toggleAir() }
                        Tile { icon: "\u{F0176}"; name: "caffeine"; on: Sys.caffeine; onClicked: Sys.caffeine = !Sys.caffeine }
                        Tile { icon: on ? "\u{F036C}" : "\u{F036D}"; name: "mic"; on: Sys.micOn; onClicked: Sys.toggleMic() }
                        Tile { icon: "\u{F044A}"; name: "record"; on: Sys.rec; picked: root.pick === "rec"; onClicked: { root.close(); Sys.toggleRec(); } onMenu: root.pick = picked ? "" : "rec" }
                        Tile { icon: "\u{F03D8}"; name: Sys.shaderLabel(Sys.shader); on: Sys.shader !== ""; picked: root.pick === "shader"; onClicked: Sys.cycleShader(); onMenu: root.pick = picked ? "" : "shader" }
                        Tile { icon: "\u{F050E}"; name: "dark"; on: !Theme.light; onClicked: Theme.setLight(!Theme.light) }
                    }

                    Rec { width: parent.width; visible: root.pick === "rec"; onTouched: root.pin(); onStart: { root.close(); Sys.toggleRec(); } }
                    ShaderMenu { width: parent.width; visible: root.pick === "shader"; onTouched: root.pin() }

                    Slider { icon: "\u{F00E0}"; visible: Sys.hasBri; value: Sys.bri; onMoved: v => Sys.setBri(v) }
                    Slider { icon: Sys.muted ? "\u{F075F}" : "\u{F057E}"; value: Sys.muted ? 0 : Sys.vol; onMoved: v => Sys.setVol(v) }

                    // Power profile mode selector, similar to Caelestia: four segmented cells, white fill indicator glides to the selected mode; tick marks indicate intensity.
                    // Ultra mode caps refresh rate to 60 Hz and disables animations, blur, and window shadows (Rules.modes)
                    // Right button: Game mode toggle (Rules.store.game) — disables animations, blur, shadows, and gaps; enables tearing
                    Row {
                        width: parent.width
                        spacing: 12
                        Rectangle {
                            id: modes
                            width: parent.width - game.width - 12
                            height: 54
                            radius: Theme.corner(27)
                            color: Theme.s2
                            readonly property real cell: (width - 12) / Rules.modeCount
                            Rectangle {
                                x: 6 + modes.cell * Rules.mode
                                y: 6
                                width: modes.cell
                                height: parent.height - 12
                                radius: height / 2
                                color: Theme.fg
                                Behavior on x { NumberAnimation { duration: Theme.t; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.glide } }
                            }
                            Repeater {
                                model: Rules.modeCount
                                Item {
                                    id: mc
                                    required property int index
                                    readonly property bool on: Rules.mode === index
                                    x: 6 + modes.cell * index
                                    width: modes.cell
                                    height: modes.height
                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 10
                                        Row {
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 3
                                            Repeater {
                                                model: 4
                                                Rectangle {
                                                    required property int index
                                                    anchors.bottom: parent.bottom
                                                    width: 4
                                                    height: 6 + index * 4
                                                    radius: 2
                                                    color: index <= mc.index ? (mc.on ? Theme.ink : Theme.fg) : (mc.on ? Theme.mute : Theme.s3)
                                                }
                                            }
                                        }
                                        Lb { anchors.verticalCenter: parent.verticalCenter; text: Rules.modes[mc.index].short; color: mc.on ? Theme.ink : Theme.grey }
                                    }
                                    TapHandler { onTapped: { root.pin(); Rules.setMode(mc.index); } }
                                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                                }
                            }
                        }
                        Rectangle {
                            id: game
                            width: 54
                            height: 54
                            radius: 27
                            color: Rules.store.game ? Theme.fg : Theme.s2
                            Behavior on color { ColorAnimation { duration: Theme.t } }
                            Icon { anchors.centerIn: parent; text: "\u{F0297}"; font.pixelSize: 22; color: Rules.store.game ? Theme.ink : Theme.fg }
                            TapHandler { onTapped: { root.pin(); Rules.store.game = !Rules.store.game; } }
                            HoverHandler { cursorShape: Qt.PointingHandCursor }
                        }
                    }

                    // Mini media player
                    Rectangle {
                        visible: !!Media.player
                        width: parent.width
                        height: 86
                        radius: Theme.corner(30)
                        color: Theme.s2
                        Art { id: mart; x: 12; anchors.verticalCenter: parent.verticalCenter; width: 62; height: 62; step: 4; url: Media.player?.trackArtUrl ?? "" }
                        Column {
                            anchors { left: mart.right; leftMargin: 16; right: mctl.left; rightMargin: 16; verticalCenter: parent.verticalCenter }
                            Text { textFormat: Text.PlainText; width: parent.width; elide: Text.ElideRight; text: Media.player?.trackTitle || "Nothing on"; font { family: Theme.ui; pixelSize: 16; weight: Font.DemiBold } color: Theme.fg }
                            Text { textFormat: Text.PlainText; width: parent.width; elide: Text.ElideRight; text: Media.player?.trackArtist ?? ""; font { family: Theme.ui; pixelSize: 13 } color: Theme.grey }
                        }
                        Controls { id: mctl; anchors { right: parent.right; rightMargin: 18; verticalCenter: parent.verticalCenter } size: 20; play: 44 }
                    }
                    }
                }
            }
        }
    }
    // Hot trigger strip: panel overlays this edge, and cursor hovering over it maintains panel visibility just like the panel itself
    Item {
        anchors { right: parent.right; bottom: parent.bottom }
        width: 2
        height: Math.round(parent.height * 0.8)
        HoverHandler { id: edge }
    }

    // Circular header action button
    component Round: Rectangle {
        property string icon
        signal clicked
        width: 44
        height: 44
        radius: 22
        color: Theme.s2
        Icon { anchors.centerIn: parent; text: parent.icon }
        TapHandler { onTapped: { root.pin(); parent.clicked(); } }
    }
    // Pill button: active is white with black text. Right-click opens network/device list dropdown; chevron indicates expanded state
    component Pill: Rectangle {
        id: pill
        property bool on
        property bool picked
        signal menu
        property string icon
        property string name
        property string sub
        signal clicked
        width: (col.width - 12) / 2
        height: 76
        radius: Theme.corner(38)
        color: on ? Theme.fg : Theme.s2
        Behavior on color { ColorAnimation { duration: Theme.t } }
        Rectangle {
            id: pi
            x: 12
            anchors.verticalCenter: parent.verticalCenter
            width: 52
            height: 52
            radius: 26
            color: pill.on ? Theme.ink : Theme.s3
            Icon { anchors.centerIn: parent; text: pill.icon; font.pixelSize: 22 }
        }
        Column {
            anchors { left: pi.right; leftMargin: 12; right: chev.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
            Text { text: pill.name; font { family: Theme.ui; pixelSize: 16; weight: Font.DemiBold } color: pill.on ? Theme.ink : Theme.fg }
            Text {
                width: parent.width
                elide: Text.ElideRight
                textFormat: Text.PlainText
                text: pill.sub
                font { family: Theme.mono; pixelSize: 11; letterSpacing: 0.9; capitalization: Font.AllUppercase }
                color: pill.on ? Theme.ink : Theme.fg
                opacity: 0.6
            }
        }
        Icon {
            id: chev
            anchors { right: parent.right; rightMargin: 20; verticalCenter: parent.verticalCenter }
            text: "\u{F0140}"
            font.pixelSize: 18
            color: pill.on ? Theme.ink : Theme.fg
            opacity: pill.picked ? 1 : 0.4
            rotation: pill.picked ? 180 : 0
            Behavior on rotation { NumberAnimation { duration: Theme.t; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.glide } }
        }
        TapHandler { onTapped: { root.pin(); pill.clicked(); } }
        TapHandler { acceptedButtons: Qt.RightButton; onTapped: { root.pin(); pill.menu(); } }
    }
    // 68px circular tile: active state is a filled white circle. Right-click opens submenu (e.g., recording settings); active state shows white label
    component Tile: Column {
        id: tile
        property bool on
        property bool picked
        signal menu
        property string icon
        property string name
        signal clicked
        width: col.width / 4
        spacing: 8
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 68
            height: 68
            radius: 34
            color: tile.on ? Theme.fg : Theme.s2
            Behavior on color { ColorAnimation { duration: Theme.t } }
            Icon { anchors.centerIn: parent; text: tile.icon; font.pixelSize: 24; color: tile.on ? Theme.ink : Theme.fg }
            TapHandler { onTapped: { root.pin(); tile.clicked(); } }
            TapHandler { acceptedButtons: Qt.RightButton; onTapped: { root.pin(); tile.menu(); } }
        }
        Lb { anchors.horizontalCenter: parent.horizontalCenter; text: tile.name; px: 10; color: tile.picked ? Theme.fg : Theme.grey }
    }
    // Slider: filled portion is a white pill with an icon; empty portion is rendered as dotted markings
    component Slider: Rectangle {
        id: sl
        property real value
        property string icon
        signal moved(real v)
        readonly property real shown: area.pressed ? area.v : value
        width: col.width
        height: 54
        radius: Theme.corner(27)
        color: Theme.s2
        // Dotted scale for empty track (11px spacing). Done in QML rather than SVG tiling to avoid rasterization blur under canvas scaling
        Row {
            x: 10
            anchors.verticalCenter: parent.verticalCenter
            spacing: 11 - 2.8
            Repeater {
                model: Math.max(0, Math.floor((sl.width - 20) / 11) + 1)
                Rectangle { width: 2.8; height: 2.8; radius: 1.4; color: Theme.mute }
            }
        }
        Rectangle {
            width: Math.max(height, sl.width * sl.shown)
            height: parent.height
            radius: Theme.corner(27)
            color: Theme.fg
            Icon { x: 18; anchors.verticalCenter: parent.verticalCenter; text: sl.icon; font.pixelSize: 21; color: Theme.ink }
        }
        Rectangle {
            anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
            width: val.width + 16
            height: val.height + 8
            radius: Theme.corner(10)
            color: Theme.s2
            Lb { id: val; anchors.centerIn: parent; text: Math.round(sl.shown * 100) }
        }
        MouseArea {
            id: area
            property real v
            property real wacc: 0
            anchors.fill: parent
            preventStealing: true
            function set(x) { v = Math.max(0, Math.min(1, x / width)); sl.moved(v); }
            // Pin panel on release: in peek mode, pinning transfers keyboard focus (None -> Exclusive), causing Hyprland
            // to release all mouse buttons — otherwise, the first drag after peek would jump to the click point and abort
            onPressed: e => set(e.x)
            onPositionChanged: e => set(e.x)
            onReleased: root.pin()
            // Mouse wheel adjustments: 5% per notch. Touchpad gestures (which have scroll phases) are slowed 4x to avoid sweeping half the scale.
            // Accumulate up to 2% delta: small touchpad increments are lost to brightness rounding, which would otherwise spam brightnessctl.
            // Avoid pinning on scroll: scrolling is not a selection click, so edge-peeked panel can still auto-close without grabbing focus.
            // Scrolling direction follows Qt Slider convention: natural scroll preserves upward/rightward increase
            onWheel: e => {
                wacc += (e.inverted ? -1 : 1) * (e.angleDelta.y || -e.angleDelta.x) / 120 * 0.05 * (e.phase === Qt.NoScrollPhase ? 1 : 0.25);
                if (Math.abs(wacc) < 0.02)
                    return;
                sl.moved(Math.max(0, Math.min(1, sl.shown + wacc)));
                wacc = 0;
            }
        }
    }
}

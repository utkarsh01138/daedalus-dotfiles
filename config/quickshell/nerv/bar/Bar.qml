import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Hyprland
import Quickshell.Networking
import Quickshell.Services.UPower
import Quickshell.Wayland
import qs
import qs.components
import qs.services
import qs.settings

// NERV Tactical Command Rail: Edge-to-edge flush top panel with zero curves,
// MAGI tri-cluster decision consensus, CPU thread oscillograph, and live umbilical/battery telemetry.
PanelWindow {
    id: root

    signal markClicked
    signal trayClicked
    signal powerClicked
    signal clockClicked

    readonly property bool vert: false
    anchors { left: true; right: true; top: true }
    implicitHeight: 36
    exclusionMode: ExclusionMode.Normal
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "nerv-bar"
    WlrLayershell.exclusiveZone: 36

    property bool quickOpen: false
    property bool deckOpen: Sys.deckOpen
    property bool calOpen: false
    property bool dim: false
    Timer { running: Theme.state.blink; interval: 500; repeat: true; onTriggered: root.dim = !root.dim }

    // Keep SysStats active for real-time telemetry
    Binding { target: SysStats; property: "cat"; value: true }

    readonly property int active: Hyprland.focusedWorkspace?.id ?? 0
    readonly property int count: Math.min(10, Math.max(6, active, ...Hyprland.workspaces.values.filter(w => w.toplevels.values.length).map(w => w.id)))
    readonly property var top: ToplevelManager.activeToplevel
    readonly property var bat: UPower.displayDevice
    readonly property var wifi: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null

    function go(ws) { Hyprland.dispatch(`hl.dsp.focus({ workspace = "${ws}" })`); }

    SystemClock { id: clock; precision: SystemClock.Minutes }

    Rectangle {
        id: pill
        anchors.fill: parent
        radius: 0
        color: Theme.s1
        border.width: 0

        // Razor-sharp Evangelion Blood Crimson bottom rail border
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            color: Theme.accent
        }

        Notch { onNotch: d => root.go(d > 0 ? "-1" : "+1") }

        // Left Cluster: NERV Badge, Tactical Sector Selectors, Window Title
        Row {
            id: leftCluster
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10

            // NERV Tactical Badge Command Trigger
            Rectangle {
                id: mark
                anchors.verticalCenter: parent.verticalCenter
                width: 58
                height: 22
                radius: 0
                color: Theme.accent

                Row {
                    anchors.centerIn: parent
                    spacing: 4
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 4
                        height: 4
                        color: "#000000"
                    }
                    Text {
                        text: "NERV"
                        font { family: Theme.mono; pixelSize: 10; bold: true }
                        color: "#000000"
                    }
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.markClicked() }
            }

            // Tactical Workspace Sectors
            Row {
                id: ws
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                Repeater {
                    model: root.count

                    Rectangle {
                        required property int index
                        readonly property int n: index + 1
                        readonly property bool occ: (Hyprland.workspaces.values.find(w => w.id === n)?.toplevels.values.length ?? 0) > 0
                        readonly property bool on: root.active === n
                        width: 24
                        height: 22
                        radius: 0
                        color: on ? Theme.accent : occ ? Theme.s2 : "transparent"
                        border { width: 1; color: on ? Theme.hazard : occ ? Qt.rgba(0.9, 0.11, 0.14, 0.5) : Theme.s3 }
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Text {
                            anchors.centerIn: parent
                            text: String(parent.n).padStart(2, "0")
                            font { family: Theme.mono; pixelSize: 9; bold: true }
                            color: parent.on ? "#000000" : parent.occ ? Theme.fg : Theme.mute
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.go(parent.n) }
                    }
                }
            }

            // Window Title Bar
            Item {
                id: titleItem
                anchors.verticalCenter: parent.verticalCenter
                width: Math.max(0, centerCluster.x - leftCluster.x - ws.width - mark.width - 48)
                height: 22
                clip: true
                visible: Theme.state.barTitle && (Hyprland.focusedWorkspace?.toplevels.values.length ?? 0) > 0 && !!root.top

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "// [ " + (root.top ? root.top.appId.split(".").pop().toUpperCase() : "") + " ]"
                        font { family: Theme.mono; pixelSize: 9; bold: true }
                        color: Theme.accent
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.top ? root.top.title : ""
                        font { family: Theme.ui; pixelSize: 10 }
                        color: Theme.chalk
                        elide: Text.ElideRight
                        width: titleItem.width - 90
                    }
                }
            }
        }

        // Center Cluster: MAGI Supercomputer Tri-Cluster + Live CPU Oscillograph
        Row {
            id: centerCluster
            anchors.centerIn: parent
            spacing: 14

            MagiPill {
                anchors.verticalCenter: parent.verticalCenter
            }

            Oscillograph {
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // Right Cluster: System Telemetry, Tray & Military Clock
        Row {
            id: rightCluster
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12

            // System Tray Items
            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12

                Repeater {
                    model: Theme.state.bar
                    Loader {
                        id: part
                        required property string modelData
                        readonly property bool quick: modelData !== "mode" && modelData !== "power"
                        sourceComponent: root.parts[modelData] ?? null
                        visible: !!sourceComponent && (modelData !== "battery" || root.bat.isLaptopBattery)
                        TapHandler { enabled: part.quick; onTapped: root.trayClicked() }
                        HoverHandler { enabled: part.quick; cursorShape: Qt.PointingHandCursor }
                    }
                }
            }

            // Hairline separator
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 1
                height: 18
                color: Theme.s3
            }

            // Military Clock in FOT-Matisse Pro
            Row {
                id: clk
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3
                TapHandler { onTapped: root.clockClicked() }
                HoverHandler { cursorShape: Qt.PointingHandCursor }

                Num {
                    text: Theme.hh(clock.date)
                    font.pixelSize: 13
                    font.bold: true
                    color: Theme.fg
                }
                Num {
                    text: ":"
                    font.pixelSize: 13
                    font.bold: true
                    color: Theme.hazard
                    opacity: Theme.state.blink && root.dim ? 0.3 : 1
                }
                Num {
                    text: Qt.formatTime(clock.date, "mm")
                    font.pixelSize: 13
                    font.bold: true
                    color: Theme.fg
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    leftPadding: 4
                    text: Qt.locale("en_US").toString(clock.date, "ddd").toUpperCase()
                    font { family: Theme.mono; pixelSize: 9; bold: true }
                    color: Theme.grey
                }
            }
        }
    }

    readonly property var parts: ({ layout: layoutC, wifi: wifiC, bluetooth: btC, sound: soundC, notes: notesC, battery: batC, mode: modeC, power: powerC, cat: catC })

    // Layout
    Component {
        id: layoutC
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 26
            height: 18
            radius: 0
            color: Theme.s2
            border { width: 1; color: Theme.s3 }
            Text {
                anchors.centerIn: parent
                text: Sys.layout.toUpperCase()
                font { family: Theme.mono; pixelSize: 8; bold: true }
                color: Theme.chalk
            }
        }
    }

    // RunCat
    Component {
        id: catC
        AnimatedImage {
            width: 38
            height: 22
            source: "runcat.gif"
            mipmap: true
            speed: 1 + 4 * SysStats.cpu
            layer.enabled: Theme.light
            layer.effect: MultiEffect { brightness: -1 }
        }
    }

    // Wi-Fi
    Component {
        id: wifiC
        Row {
            spacing: 4
            anchors.verticalCenter: parent.verticalCenter
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 5
                height: 5
                radius: 0
                color: root.wifi?.connected ? Theme.crimson : Theme.mute
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.wifi?.connected ? "NET:OK" : "NET:OFF"
                font { family: Theme.mono; pixelSize: 9; bold: true }
                color: root.wifi?.connected ? Theme.chalk : Theme.grey
            }
        }
    }

    // Bluetooth
    Component {
        id: btC
        Icon {
            anchors.verticalCenter: parent.verticalCenter
            text: Bluetooth.defaultAdapter?.enabled ? "\u{F00AF}" : "\u{F00B2}"
            font.pixelSize: 12
            color: Bluetooth.devices.values.some(d => d.connected) ? Theme.fg : Theme.grey
        }
    }

    // Sound
    Component {
        id: soundC
        Row {
            spacing: 4
            anchors.verticalCenter: parent.verticalCenter
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Sys.muted ? "[MUT]" : "[VOL]"
                font { family: Theme.mono; pixelSize: 8; bold: true }
                color: Sys.muted ? Theme.grey : Theme.crimson
                Notch { onNotch: d => Sys.setVol(Sys.vol + d * 0.05) }
            }
            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                Repeater {
                    model: 6
                    Rectangle {
                        required property int index
                        width: 2
                        height: 9
                        radius: 0
                        color: Sys.muted ? Theme.s3 : (index / 6) < Sys.vol ? Theme.crimson : Theme.s3
                    }
                }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Sys.muted ? "0%" : Math.round(Sys.vol * 100) + "%"
                font { family: Theme.mono; pixelSize: 9; bold: true }
                color: Sys.muted ? Theme.mute : Theme.chalk
            }
        }
    }

    // Notifications
    Component {
        id: notesC
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: `[N:${Notes.list.length}]`
                font { family: Theme.mono; pixelSize: 8; bold: true }
                color: Notes.list.length ? Theme.accent : Theme.mute
            }
        }
    }

    // NERV Umbilical Power Cable & Internal Battery Countdown Gauge
    Component {
        id: batC
        Row {
            id: batc
            anchors.verticalCenter: parent.verticalCenter
            HoverHandler { onHoveredChanged: { root.batHot = hovered; root.peek(batc); } Component.onDestruction: root.batHot = false }
            spacing: 5
            readonly property bool ac: !UPower.onBattery
            readonly property bool charging: root.bat.state === UPowerDeviceState.Charging
            property real phase: 0
            readonly property real pulse: charging ? 0.675 + 0.325 * Math.cos(phase * Math.PI / 1.1) : 1
            Timer { running: batc.charging; interval: 50; repeat: true; onTriggered: batc.phase = (batc.phase + 0.05) % 2.2; onRunningChanged: batc.phase = 0 }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: batc.ac ? "[UMBILICAL]" : "[INT.BAT]"
                font { family: Theme.mono; pixelSize: 8; bold: true }
                color: batc.ac ? Theme.chalk : Theme.hazard
            }

            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                Repeater {
                    model: 8
                    Rectangle {
                        required property int index
                        width: 2
                        height: 10
                        radius: 0
                        color: (index / 8) < root.bat.percentage ? (root.batLow ? Theme.crimson : Theme.hazard) : Theme.s3
                        opacity: batc.pulse
                    }
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: {
                    if (batc.ac) return Math.round(root.bat.percentage * 100) + "%";
                    if (root.bat.timeToEmpty > 0) {
                        const m = Math.floor(root.bat.timeToEmpty / 60);
                        const s = Math.floor(root.bat.timeToEmpty % 60);
                        return `${m}:${s < 10 ? "0" : ""}${s}`;
                    }
                    return Math.round(root.bat.percentage * 100) + "%";
                }
                font { family: Theme.mono; pixelSize: 9; bold: true }
                color: root.batLow ? Theme.crimson : Theme.chalk
            }
        }
    }

    // Performance Mode
    Component {
        id: modeC
        Item {
            id: ticks
            anchors.verticalCenter: parent.verticalCenter
            width: 32
            height: 18
            Row {
                anchors.centerIn: parent
                spacing: 2
                Repeater {
                    model: Rules.modeCount
                    Rectangle {
                        required property int index
                        anchors.bottom: parent.bottom
                        width: 2
                        height: 4 + index * 3
                        radius: 0
                        color: index <= Rules.mode ? Theme.fg : Theme.s3
                    }
                }
            }
            HoverHandler { cursorShape: Qt.PointingHandCursor; onHoveredChanged: { root.tickHot = hovered; root.peek(ticks); } Component.onDestruction: root.tickHot = false }
            TapHandler { onTapped: Rules.setMode((Rules.mode + 1) % Rules.modeCount) }
        }
    }

    // Power Trigger
    Component {
        id: powerC
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 34
            height: 18
            radius: 0
            color: pwr.hovered ? Theme.accent : Theme.s2
            border { width: 1; color: Theme.accent }
            Text {
                anchors.centerIn: parent
                text: "PWR"
                font { family: Theme.mono; pixelSize: 8; bold: true }
                color: pwr.hovered ? "#000000" : Theme.chalk
            }
            HoverHandler { id: pwr; cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: root.powerClicked() }
        }
    }

    // ---- Battery & Power mode popover: hovering battery or ticks opens diagnostic card ----
    property bool batHot: false
    property bool tickHot: false
    readonly property bool powHot: batHot || tickHot || popHov.hovered
    readonly property bool batLow: UPower.onBattery && root.bat.percentage < 0.15
    property point popAt
    function peek(it) { if (!pop.visible) popAt = it.mapToItem(pill, it.width, it.height); }
    property bool powOpen: false
    property int powPeek: -1
    onPowHotChanged: powHot ? powOpenT.restart() : powCloseT.restart()
    Timer { id: powOpenT; interval: 180; onTriggered: if (root.powHot) root.powOpen = true }
    Timer { id: powCloseT; interval: 300; onTriggered: if (!root.powHot) root.powOpen = false }
    function hm(sec) { const m = Math.round(sec / 60); return m >= 60 ? `${Math.floor(m / 60)} h ${m % 60} m` : `${m} m`; }
    readonly property string batState: root.bat.state === UPowerDeviceState.Charging
        ? "charging" + (root.bat.timeToFull ? ` · full in ${hm(root.bat.timeToFull)}` : "")
        : !UPower.onBattery ? "on ac · full"
        : "on battery" + (root.bat.timeToEmpty ? ` · ${hm(root.bat.timeToEmpty)} left` : "")

    PopupWindow {
        id: pop
        property real t: root.powOpen ? 1 : 0
        Behavior on t { NumberAnimation { duration: Theme.t; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.glide } }
        visible: t > 0
        anchor.item: pill
        anchor.rect: Qt.rect(root.popAt.x, pill.height + 4, 1, 1)
        anchor.edges: Edges.Top | Edges.Left
        anchor.gravity: Edges.Bottom | Edges.Left
        implicitWidth: Math.ceil(440 * Theme.s)
        implicitHeight: Math.ceil(card.height * Theme.s)
        color: "transparent"

        Stage {
            Rectangle {
                id: card
                width: 440
                height: body.height + 52
                radius: 0
                color: Theme.s1
                border { width: 1; color: Theme.accent }
                opacity: pop.t
                HoverHandler { id: popHov }

                Column {
                    id: body
                    x: 26
                    y: 26
                    width: parent.width - 52
                    spacing: 18

                    // Diagnostic header
                    Rectangle {
                        width: parent.width
                        height: 22
                        radius: 0
                        color: Theme.s2
                        border { width: 1; color: Theme.line }
                        Text {
                            anchors.centerIn: parent
                            text: "[ POWER TELEMETRY // UMBILICAL MONITOR ]"
                            font.family: Theme.mono
                            font.pixelSize: 10
                            font.bold: true
                            color: Theme.hazard
                        }
                    }

                    Row {
                        spacing: 14
                        Num { text: Math.round(root.bat.percentage * 100); font.pixelSize: 64 }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 6
                            Lb { text: "% battery charge"; color: Theme.fg }
                            Lb { text: root.batState }
                        }
                    }
                    Seg { width: parent.width; height: 6; n: 24; f: root.bat.percentage; on: root.batLow ? Theme.red : Theme.fg }

                    Lb { topPadding: 6; text: "power mode selector" }
                    Row {
                        spacing: (body.width - Rules.modeCount * 80) / Math.max(1, Rules.modeCount - 1)
                        Repeater {
                            model: Rules.modeCount
                            Column {
                                id: mo
                                required property int index
                                readonly property bool on: Rules.mode === index
                                spacing: 10
                                Rectangle {
                                    width: 80
                                    height: 80
                                    radius: 0
                                    color: mo.on ? Theme.fg : moHov.hovered ? Theme.s3 : Theme.s2
                                    border { width: mo.on ? 2 : 1; color: mo.on ? Theme.hazard : Theme.line }
                                    Behavior on color { ColorAnimation { duration: Theme.t } }
                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 4
                                        Repeater {
                                            model: 4
                                            Rectangle {
                                                required property int index
                                                anchors.bottom: parent.bottom
                                                width: 5
                                                height: 8 + index * 6
                                                radius: 0
                                                color: index <= mo.index ? (mo.on ? Theme.ink : Theme.fg) : (mo.on ? Theme.mute : Theme.s3)
                                            }
                                        }
                                    }
                                    HoverHandler {
                                        id: moHov
                                        cursorShape: Qt.PointingHandCursor
                                        onHoveredChanged: if (hovered) root.powPeek = mo.index; else if (root.powPeek === mo.index) root.powPeek = -1
                                    }
                                    TapHandler { onTapped: Rules.setMode(mo.index) }
                                }
                                Lb { anchors.horizontalCenter: parent.horizontalCenter; text: mo.index === 3 ? "max" : Rules.modes[mo.index].name; color: mo.on ? Theme.fg : Theme.grey }
                            }
                        }
                    }
                    Lb {
                        readonly property int i: root.powPeek >= 0 ? root.powPeek : Rules.mode
                        width: parent.width
                        elide: Text.ElideRight
                        text: `${Rules.modes[i].what} · ${i === 0 ? Rules.rates[0] : Rules.refreshHz} hz`
                    }
                }
            }
        }
    }
}

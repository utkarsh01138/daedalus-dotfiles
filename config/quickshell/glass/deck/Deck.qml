import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs
import qs.components
import qs.services

// Profile 4: glass — Dashboard Deck (macOS / visionOS liquid frosted acrylic).
// Centered floating bottom acrylic shelf sliding up with spring physics.
// Features smooth continuous arc gauges, live weather, network sparkline, and Now Playing widget.
Scope {
    id: root

    property var on: null // Screen where deck is currently opened
    property bool pinned: false
    function toggle() {
        pinned = !on;
        on = on ? null : Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0];
    }

    readonly property var ids: Theme.state.deck.filter(id => Theme.decks.includes(id))
    readonly property int h: 220 // Section height in layout pixels

    // When open, enable detailed polling for CPU/memory/network stats
    Binding { target: Sys; property: "deckOpen"; value: root.on !== null }
    Binding { target: SysStats; property: "perf"; value: root.on !== null }

    SystemClock { id: clock; precision: SystemClock.Minutes }
    readonly property var en: Qt.locale("en_US")
    function hm(d) { return Qt.formatTime(d, Theme.state.clock24 ? "hh:mm" : "h:mm ap"); }
    function week(d) {
        const t = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
        t.setUTCDate(t.getUTCDate() + 4 - (t.getUTCDay() || 7));
        return Math.ceil(((t - Date.UTC(t.getUTCFullYear(), 0, 1)) / 86400000 + 1) / 7);
    }

    // Network history: [rx, tx] sampled every 2s
    property var net: []
    Timer {
        running: root.on !== null
        interval: 2000
        repeat: true
        onTriggered: root.net = root.net.concat([[SysStats.rx, SysStats.tx]]).slice(-24)
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win

            required property var modelData
            readonly property bool open: root.on === modelData
            property real t: open ? 1 : 0
            Behavior on t { NumberAnimation { duration: 240; easing.type: Easing.OutQuad } }

            screen: modelData
            visible: Theme.state.deckHover && root.ids.length > 0 && !Hyprland.monitorFor(modelData)?.activeWorkspace?.hasFullscreen || t > 0
            anchors { left: true; right: true; top: true; bottom: true }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.layer: t > 0 ? WlrLayer.Overlay : WlrLayer.Top
            WlrLayershell.namespace: "glass-deck"
            mask: Region {
                y: win.open ? 0 : win.height - 4
                width: win.width
                height: win.open ? win.height : 4
            }

            Timer { id: dwell; interval: 150; onTriggered: root.on = win.modelData }
            Timer { id: leave; interval: 300; onTriggered: if (win.open && !root.pinned) root.on = null }

            // Scrim covers desktop, click dismisses deck
            Rectangle {
                anchors.fill: parent
                color: "#000000"
                opacity: 0.35 * win.t
                visible: win.t > 0
                MouseArea { anchors.fill: parent; onClicked: { root.pinned = false; root.on = null; } }
            }

            Stage {
                // Bottom edge hover trigger strip
                Item {
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                    height: win.open ? (panel.height + 28) : 4
                    HoverHandler {
                        onHoveredChanged: {
                            if (hovered) {
                                leave.stop();
                                if (!win.open && Theme.state.deckHover) dwell.restart();
                            } else {
                                dwell.stop();
                                if (win.open && !root.pinned) leave.restart();
                            }
                        }
                    }
                }

                // Frosted Acrylic Floating Deck Shelf
                Rectangle {
                    id: panel
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 14 - (1 - win.t) * (height + 28)
                    width: row.width + 48
                    height: root.h + 48
                    opacity: win.t
                    radius: 24
                    color: Theme.s1
                    border { width: 1; color: Theme.s3 }
                    clip: true

                    // Top specular light hairline
                    Rectangle {
                        anchors { left: parent.left; right: parent.right; top: parent.top }
                        anchors.margins: 4
                        height: 1
                        color: Theme.specular
                        opacity: 0.8
                        radius: 24
                    }

                    // Dynamic Specular Cursor Glow
                    SpecularGlow {
                        glowRadius: 130
                        maxOpacity: 0.55
                    }

                    MouseArea { anchors.fill: parent } // Absorb clicks

                    Row {
                        id: row
                        x: 24
                        y: 24
                        spacing: 20

                        Repeater {
                            model: root.ids
                            Row {
                                id: cell
                                required property string modelData
                                required property int index
                                spacing: 20

                                // Clean 1px continuous frosted hairline divider
                                Rectangle {
                                    visible: cell.index > 0
                                    width: 1
                                    height: root.h - 20
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: Qt.rgba(1, 1, 1, 0.12)
                                    radius: 1
                                }

                                Loader {
                                    anchors.verticalCenter: parent.verticalCenter
                                    sourceComponent: ({
                                        clock: clockC,
                                        weather: weatherC,
                                        perf: perfC,
                                        net: netC,
                                        media: mediaC
                                    })[cell.modelData]
                                }
                            }
                        }
                    }
                }
            }

            // 1. Clock, Date, Week & Daylight continuous progress bar
            Component {
                id: clockC
                Column {
                    width: 210
                    spacing: 4

                    Text {
                        text: (root.en.dayName(clock.date.getDay()) + (Theme.state.clock24 ? "" : clock.date.getHours() < 12 ? " · AM" : " · PM")).toUpperCase()
                        font.family: Theme.ui; font.pixelSize: 11; font.weight: Font.Bold
                        color: Theme.cyan
                    }

                    Text {
                        text: Theme.state.clock24 ? Qt.formatTime(clock.date, "hh:mm") : (clock.date.getHours() % 12 || 12) + Qt.formatTime(clock.date, ":mm")
                        font.family: Theme.ui; font.pixelSize: 58; font.weight: Font.Bold
                        color: Theme.fg
                    }

                    Text {
                        text: `${root.en.toString(clock.date, "d MMMM yyyy")} · Week ${root.week(clock.date)}`
                        font.family: Theme.ui; font.pixelSize: 12; font.weight: Font.Medium
                        color: Theme.sub
                    }

                    Item { width: 1; height: 10 }

                    // Continuous daylight progress bar
                    Rectangle {
                        width: parent.width
                        height: 6
                        radius: 3
                        color: Qt.rgba(255, 255, 255, 0.08)
                        clip: true

                        Rectangle {
                            readonly property real f: Weather.sun ? Math.max(0, Math.min(1, (clock.date - Weather.sun.rise) / (Weather.sun.set - Weather.sun.rise))) : 0
                            width: parent.width * f
                            height: 6
                            radius: 3
                            color: Theme.cyan
                        }
                    }

                    Row {
                        width: parent.width
                        Item {
                            width: parent.width / 2
                            height: 22
                            Row {
                                spacing: 6
                                anchors.verticalCenter: parent.verticalCenter
                                Text { text: "\u{F059C}"; font.family: Theme.nf; font.pixelSize: 12; color: Theme.cyan }
                                Text { text: Weather.sun ? root.hm(Weather.sun.rise) : "--:--"; font.family: Theme.ui; font.pixelSize: 11; color: Theme.sub }
                            }
                        }
                        Item {
                            width: parent.width / 2
                            height: 22
                            Row {
                                spacing: 6
                                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                                Text { text: "\u{F059B}"; font.family: Theme.nf; font.pixelSize: 12; color: Theme.lavender }
                                Text { text: Weather.sun ? root.hm(Weather.sun.set) : "--:--"; font.family: Theme.ui; font.pixelSize: 11; color: Theme.sub }
                            }
                        }
                    }
                }
            }

            // 2. Weather: Live condition, large temperature & 4-day forecast mini-cards
            Component {
                id: weatherC
                Column {
                    width: 200
                    spacing: 4

                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        text: Weather.ok ? Weather.name(Weather.now.code).toUpperCase() : "CLEAR SKY"
                        font.family: Theme.ui; font.pixelSize: 11; font.weight: Font.Bold
                        color: Theme.cyan
                    }

                    Row {
                        spacing: 12
                        anchors.left: parent.left
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Weather.glyph(Weather.now?.code ?? 3, Weather.now?.day)
                            font.family: Theme.nf; font.pixelSize: 44
                            color: Theme.cyan
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Weather.ok ? Math.round(Weather.now.temp) + "°" : "--"
                            font.family: Theme.ui; font.pixelSize: 52; font.weight: Font.Bold
                            color: Theme.fg
                        }
                    }

                    Text {
                        text: Weather.ok ? `Feels ${Math.round(Weather.now.feels)}° · Wind ${Math.round(Weather.now.wind)} m/s` : "Weather data ready"
                        font.family: Theme.ui; font.pixelSize: 11; font.weight: Font.Medium
                        color: Theme.sub
                    }

                    Item { width: 1; height: 10 }

                    // 4-day forecast row
                    Row {
                        spacing: 6
                        Repeater {
                            model: Weather.days.slice(1, 5)
                            Rectangle {
                                required property var modelData
                                required property int index
                                width: 44
                                height: 68
                                radius: 8
                                color: Qt.rgba(255, 255, 255, 0.05)
                                border { width: 1; color: Qt.rgba(255, 255, 255, 0.08) }

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 3
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: root.en.dayName((clock.date.getDay() + index + 1) % 7, Locale.ShortFormat).toUpperCase()
                                        font.family: Theme.ui; font.pixelSize: 9; font.weight: Font.Bold
                                        color: Theme.sub
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: Weather.glyph(modelData.code, true)
                                        font.family: Theme.nf; font.pixelSize: 16
                                        color: Theme.cyan
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: Math.round(modelData.max) + "°"
                                        font.family: Theme.ui; font.pixelSize: 11; font.weight: Font.Bold
                                        color: Theme.fg
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // 3. Performance: Smooth circular gauges for CPU/RAM/GPU, top processes, and CPU cores
            Component {
                id: perfC
                Column {
                    width: 320
                    spacing: 12

                    Row {
                        spacing: 16
                        anchors.horizontalCenter: parent.horizontalCenter

                        ArcGauge {
                            value: SysStats.cpu
                            label: "CPU"
                            sub: `${Math.round(SysStats.cpuTemp)}°C`
                            accentColor: Theme.cyan
                        }

                        ArcGauge {
                            value: SysStats.mem
                            label: "RAM"
                            sub: `${SysStats.memUsed.toFixed(1)}G`
                            accentColor: Theme.lavender
                        }

                        ArcGauge {
                            value: SysStats.gpu
                            label: "GPU"
                            sub: `${Math.round(SysStats.gpuTemp)}°C`
                            accentColor: "#88C0D0"
                        }
                    }

                    Row {
                        spacing: 16
                        anchors.horizontalCenter: parent.horizontalCenter

                        // Processes list with smooth bars
                        Column {
                            width: 170
                            spacing: 5
                            Text {
                                text: "TOP PROCESSES"
                                font.family: Theme.ui; font.pixelSize: 10; font.weight: Font.Bold
                                color: Theme.sub
                            }
                            Repeater {
                                model: SysStats.procs.slice(0, 4)
                                Row {
                                    required property var modelData
                                    spacing: 8
                                    Text {
                                        width: 76
                                        elide: Text.ElideRight
                                        text: modelData[0]
                                        font.family: Theme.ui; font.pixelSize: 11; font.weight: Font.Medium
                                        color: Theme.fg
                                    }
                                    Text {
                                        width: 28
                                        horizontalAlignment: Text.AlignRight
                                        text: Math.round(modelData[1]) + "%"
                                        font.family: Theme.ui; font.pixelSize: 10
                                        color: Theme.sub
                                    }
                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 44
                                        height: 4
                                        radius: 2
                                        color: Qt.rgba(255, 255, 255, 0.08)
                                        clip: true
                                        Rectangle {
                                            width: parent.width * Math.min(1, modelData[1] / 100)
                                            height: 4
                                            radius: 2
                                            color: Theme.cyan
                                        }
                                    }
                                }
                            }
                        }

                        // Cores utilization bars
                        Column {
                            width: 126
                            spacing: 5
                            Text {
                                text: `CORES · ${SysStats.cpuFreq.toFixed(1)} GHz`
                                font.family: Theme.ui; font.pixelSize: 10; font.weight: Font.Bold
                                color: Theme.sub
                            }
                            Row {
                                spacing: 4
                                anchors.horizontalCenter: parent.horizontalCenter
                                Repeater {
                                    model: Math.min(16, SysStats.cores.length)
                                    Rectangle {
                                        required property int index
                                        readonly property real load: SysStats.cores[index] ?? 0
                                        width: 5
                                        height: 52
                                        radius: 2.5
                                        color: Qt.rgba(255, 255, 255, 0.08)
                                        clip: true

                                        Rectangle {
                                            anchors.bottom: parent.bottom
                                            width: parent.width
                                            height: Math.max(3, parent.height * load)
                                            radius: 2.5
                                            color: load > 0.8 ? "#FF5C5C" : Theme.cyan
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // 4. Network: Real-time download/upload cards and smooth sparkline
            Component {
                id: netC
                Column {
                    width: 190
                    spacing: 8

                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        text: ("NETWORK · " + (SysStats.iface || "OFFLINE")).toUpperCase()
                        font.family: Theme.ui; font.pixelSize: 11; font.weight: Font.Bold
                        color: Theme.cyan
                    }

                    // Download card
                    Rectangle {
                        width: parent.width
                        height: 38
                        radius: 10
                        color: Qt.rgba(255, 255, 255, 0.05)
                        border { width: 1; color: Qt.rgba(255, 255, 255, 0.08) }

                        Row {
                            anchors { fill: parent; margins: 8 }
                            spacing: 8
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "\u{F0045}"
                                font.family: Theme.nf; font.pixelSize: 16
                                color: Theme.cyan
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                readonly property var r: SysStats.rate(SysStats.rx).split(" ")
                                text: r[0] + " " + r[1]
                                font.family: Theme.ui; font.pixelSize: 13; font.weight: Font.Bold
                                color: Theme.fg
                            }
                        }
                    }

                    // Upload card
                    Rectangle {
                        width: parent.width
                        height: 38
                        radius: 10
                        color: Qt.rgba(255, 255, 255, 0.05)
                        border { width: 1; color: Qt.rgba(255, 255, 255, 0.08) }

                        Row {
                            anchors { fill: parent; margins: 8 }
                            spacing: 8
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "\u{F005D}"
                                font.family: Theme.nf; font.pixelSize: 16
                                color: Theme.lavender
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                readonly property var r: SysStats.rate(SysStats.tx).split(" ")
                                text: r[0] + " " + r[1]
                                font.family: Theme.ui; font.pixelSize: 13; font.weight: Font.Bold
                                color: Theme.fg
                            }
                        }
                    }

                    // Sparkline history canvas
                    Canvas {
                        id: netCanvas
                        width: parent.width
                        height: 60
                        antialiasing: true
                        property var history: root.net
                        onHistoryChanged: requestPaint()

                        onPaint: {
                            const ctx = getContext("2d");
                            ctx.reset();
                            const w = width, h = height;
                            if (!history || history.length < 2) return;

                            let peak = 10240;
                            for (let i = 0; i < history.length; i++) {
                                peak = Math.max(peak, history[i][0], history[i][1]);
                            }

                            const step = w / (history.length - 1);

                            // RX Area (Cyan fill + stroke)
                            ctx.beginPath();
                            ctx.moveTo(0, h);
                            for (let i = 0; i < history.length; i++) {
                                const y = h - (history[i][0] / peak) * (h - 6);
                                ctx.lineTo(i * step, y);
                            }
                            ctx.lineTo(w, h);
                            ctx.closePath();
                            ctx.fillStyle = "rgba(112, 192, 208, 0.15)";
                            ctx.fill();

                            ctx.beginPath();
                            for (let i = 0; i < history.length; i++) {
                                const y = h - (history[i][0] / peak) * (h - 6);
                                if (i === 0) ctx.moveTo(0, y);
                                else ctx.lineTo(i * step, y);
                            }
                            ctx.lineWidth = 1.5;
                            ctx.strokeStyle = "#70C0D0";
                            ctx.stroke();

                            // TX Line (Lavender stroke)
                            ctx.beginPath();
                            for (let i = 0; i < history.length; i++) {
                                const y = h - (history[i][1] / peak) * (h - 6);
                                if (i === 0) ctx.moveTo(0, y);
                                else ctx.lineTo(i * step, y);
                            }
                            ctx.lineWidth = 1.5;
                            ctx.strokeStyle = "#B48EAD";
                            ctx.stroke();
                        }
                    }
                }
            }

            // 5. Media: Now Playing Apple-style acrylic widget
            Component {
                id: mediaC
                Column {
                    width: 250
                    spacing: 8

                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        text: (Media.player?.identity ?? "NOW PLAYING").toUpperCase()
                        font.family: Theme.ui; font.pixelSize: 11; font.weight: Font.Bold
                        color: Theme.cyan
                    }

                    Row {
                        spacing: 12
                        width: parent.width

                        // Square rounded Album Art
                        Rectangle {
                            width: 68
                            height: 68
                            radius: 12
                            color: Qt.rgba(255, 255, 255, 0.08)
                            border { width: 1; color: Qt.rgba(255, 255, 255, 0.12) }
                            clip: true

                            Image {
                                anchors.fill: parent
                                source: Media.player?.trackArtUrl ?? ""
                                fillMode: Image.PreserveAspectCrop
                                visible: status === Image.Ready
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: !Media.player?.trackArtUrl
                                text: "\u{F0025}"
                                font.family: Theme.nf; font.pixelSize: 28
                                color: Theme.sub
                            }
                        }

                        // Title & Artist
                        Column {
                            width: parent.width - 80
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4

                            Text {
                                width: parent.width
                                elide: Text.ElideRight
                                text: Media.player?.trackTitle || "Nothing Playing"
                                font.family: Theme.ui; font.pixelSize: 14; font.weight: Font.Bold
                                color: Theme.fg
                            }

                            Text {
                                width: parent.width
                                elide: Text.ElideRight
                                text: Media.player?.trackArtist || "Quiet Session"
                                font.family: Theme.ui; font.pixelSize: 12; font.weight: Font.Medium
                                color: Theme.sub
                            }
                        }
                    }

                    Item { width: 1; height: 2 }

                    // Continuous progress bar
                    Rectangle {
                        width: parent.width
                        height: 5
                        radius: 2.5
                        color: Qt.rgba(255, 255, 255, 0.08)
                        clip: true

                        Rectangle {
                            readonly property real p: Media.player?.lengthSupported && Media.player.length > 0 ? (Media.position / Media.player.length) : 0
                            width: parent.width * Math.max(0, Math.min(1, p))
                            height: 5
                            radius: 2.5
                            color: Theme.cyan
                        }
                    }

                    // Time display
                    Row {
                        width: parent.width
                        Text {
                            text: Media.time(Media.position)
                            font.family: Theme.ui; font.pixelSize: 10
                            color: Theme.sub
                        }
                        Item { width: parent.width - 80; height: 1 }
                        Text {
                            text: Media.player?.lengthSupported ? Media.time(Media.player.length) : "--:--"
                            font.family: Theme.ui; font.pixelSize: 10
                            color: Theme.sub
                        }
                    }

                    // macOS-style playback controls
                    Row {
                        spacing: 16
                        anchors.horizontalCenter: parent.horizontalCenter

                        // Prev
                        Rectangle {
                            width: 32
                            height: 32
                            radius: 16
                            color: hovPrev.containsMouse ? Qt.rgba(255, 255, 255, 0.15) : Qt.rgba(255, 255, 255, 0.06)
                            Text {
                                anchors.centerIn: parent
                                text: "\u{F04AE}"
                                font.family: Theme.nf; font.pixelSize: 14
                                color: Theme.fg
                            }
                            MouseArea {
                                id: hovPrev
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Media.player?.previous()
                            }
                        }

                        // Play / Pause
                        Rectangle {
                            width: 38
                            height: 38
                            radius: 19
                            color: Theme.cyan
                            Text {
                                anchors.centerIn: parent
                                text: Media.playing ? "\u{F03E4}" : "\u{F040A}"
                                font.family: Theme.nf; font.pixelSize: 16
                                color: "#0D1017"
                            }
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Media.toggle()
                            }
                        }

                        // Next
                        Rectangle {
                            width: 32
                            height: 32
                            radius: 16
                            color: hovNext.containsMouse ? Qt.rgba(255, 255, 255, 0.15) : Qt.rgba(255, 255, 255, 0.06)
                            Text {
                                anchors.centerIn: parent
                                text: "\u{F04AD}"
                                font.family: Theme.nf; font.pixelSize: 14
                                color: Theme.fg
                            }
                            MouseArea {
                                id: hovNext
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Media.player?.next()
                            }
                        }
                    }
                }
            }
        }
    }

    // ArcGauge: Clean modern continuous circular progress arc
    component ArcGauge: Column {
        id: ag
        property real value: 0
        property string label: ""
        property string sub: ""
        property color accentColor: Theme.cyan
        spacing: 6

        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 78
            height: 78

            Canvas {
                id: arcCv
                anchors.fill: parent
                antialiasing: true
                property real p: ag.value
                property color strokeCol: ag.accentColor
                onPChanged: requestPaint()

                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();
                    const w = width, h = height;
                    const r = Math.min(w, h) / 2 - 6;
                    const cx = w / 2, cy = h / 2;
                    const start = -Math.PI / 2;

                    // Track
                    ctx.beginPath();
                    ctx.arc(cx, cy, r, 0, Math.PI * 2);
                    ctx.lineWidth = 4;
                    ctx.strokeStyle = "rgba(255, 255, 255, 0.08)";
                    ctx.stroke();

                    // Active Arc
                    if (p > 0) {
                        ctx.beginPath();
                        ctx.arc(cx, cy, r, start, start + Math.PI * 2 * Math.min(1, Math.max(0, p)));
                        ctx.lineWidth = 4;
                        ctx.lineCap = "round";
                        ctx.strokeStyle = strokeCol;
                        ctx.stroke();
                    }
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: 1
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Math.round(ag.value * 100)
                    font.family: Theme.ui; font.pixelSize: 18; font.weight: Font.Bold
                    color: Theme.fg
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: ag.sub
                    font.family: Theme.ui; font.pixelSize: 9; font.weight: Font.Medium
                    color: Theme.sub
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: ag.label
            font.family: Theme.ui; font.pixelSize: 11; font.weight: Font.Bold
            color: Theme.fg
        }
    }
}

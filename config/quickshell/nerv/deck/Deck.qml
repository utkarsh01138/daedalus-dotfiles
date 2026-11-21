import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs
import qs.components
import qs.services

// Deck: centered bottom dashboard panel (slides up from beneath the bottom screen edge).
// Hovering cursor at bottom edge (2px strip) for 150ms reveals the panel; leaving hides it after 300ms.
// Sections are arranged in columns ordered by Theme.state.deck (IDs from Theme.decks).
// Light footprint without scrim or keyboard grab: peek stats and dismiss.
Scope {
    id: root

    property var on: null // Screen where deck is currently opened
    property bool pinned: false
    function toggle() {
        pinned = !on;
        on = on ? null : Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0];
    }

    readonly property var ids: Theme.state.deck.filter(id => Theme.decks.includes(id))
    readonly property int h: 232 // Section height in layout pixels

    // When open, enable detailed polling for CPU/memory/network stats
    Binding { target: Sys; property: "deckOpen"; value: root.on !== null }
    Binding { target: SysStats; property: "perf"; value: root.on !== null }

    SystemClock { id: clock; precision: SystemClock.Minutes }
    readonly property var en: Qt.locale("en_US")
    function hm(d) { return Qt.formatTime(d, Theme.state.clock24 ? "hh:mm" : "h:mm ap"); }
    function week(d) { // ISO week calculation
        const t = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
        t.setUTCDate(t.getUTCDate() + 4 - (t.getUTCDay() || 7));
        return Math.ceil(((t - Date.UTC(t.getUTCFullYear(), 0, 1)) / 86400000 + 1) / 7);
    }

    // Network history matrix for past 40 seconds, [rx, tx] sampled every 2s
    property var net: []
    Timer { running: root.on !== null; interval: 2000; repeat: true; onTriggered: root.net = root.net.concat([[SysStats.rx, SysStats.tx]]).slice(-20) }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win

            required property var modelData
            readonly property bool open: root.on === modelData
            property real t: open ? 1 : 0
            Behavior on t { NumberAnimation { duration: Theme.t; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.glide } }

            screen: modelData
            // When in fullscreen, Top layer is not drawn by Hyprland; toggling via keybind creates window directly in Overlay
            visible: Theme.state.deckHover && root.ids.length > 0 && !Hyprland.monitorFor(modelData)?.activeWorkspace?.hasFullscreen || t > 0
            anchors { left: true; right: true; top: true; bottom: true }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            // Closed: Top layer (Glyph progress bar on edge); Open: Overlay layer (visible over fullscreen windows)
            WlrLayershell.layer: t > 0 ? WlrLayer.Overlay : WlrLayer.Top
            WlrLayershell.namespace: "glyph-deck"
            mask: Region {
                y: win.open ? 0 : win.height - 4
                width: win.width
                height: win.open ? win.height : 4
            }

            Timer { id: dwell; interval: 150; onTriggered: root.on = win.modelData }
            Timer { id: leave; interval: 300; onTriggered: if (win.open && !root.pinned) root.on = null }

            // 35% black scrim covers the entire screen, click dismisses deck
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

                Rectangle {
                    id: panel
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 14 - (1 - win.t) * (height + 28)
                    width: row.width + 52
                    height: root.h + 52 + 28
                    opacity: win.t // Uses opacity rather than visible so child Row maintains computed width
                    radius: 0
                    color: Theme.s1
                    border { width: 1; color: Theme.accent }
                    MouseArea { anchors.fill: parent } // Absorb clicks so panel clicks do not dismiss the deck

                    // Tactical diagnostic header banner
                    Rectangle {
                        id: deckBanner
                        anchors { top: parent.top; left: parent.left; right: parent.right }
                        height: 24
                        color: Theme.s2
                        border { width: 1; color: Theme.accent }
                        Row {
                            anchors.centerIn: parent
                            spacing: 8
                            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 4; height: 4; color: Theme.crimson }
                            Text {
                                text: "[ NERV TACTICAL DIAGNOSTIC DECK // SYSTEM TELEMETRY // MAGI-01 ]"
                                font.family: Theme.mono
                                font.pixelSize: 10
                                font.bold: true
                                font.letterSpacing: 1.2
                                color: Theme.hazard
                            }
                            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 4; height: 4; color: Theme.crimson }
                        }
                    }

                    Row {
                        id: row
                        x: 26
                        y: deckBanner.height + 20
                        spacing: 16
                        Repeater {
                            model: root.ids
                            Row {
                                id: cell
                                required property string modelData
                                required property int index
                                spacing: 16
                                // Vertical solid line divider between sections
                                Rectangle {
                                    visible: cell.index > 0
                                    width: 1
                                    height: root.h
                                    color: Theme.s3
                                }
                                Loader { sourceComponent: ({ clock: clockC, weather: weatherC, perf: perfC, net: netC, media: mediaC, magi: magiC })[cell.modelData] }
                            }
                        }
                    }
                }
            }

            // Clock, date, ISO week, and daylight progress segmented gauge (sunrise to sunset)
            Component {
                id: clockC
                Column {
                    width: 216
                    Lb { text: root.en.dayName(clock.date.getDay()) + (Theme.state.clock24 ? "" : clock.date.getHours() < 12 ? " · am" : " · pm") }
                    Num {
                        topPadding: lead + 10
                        text: Theme.state.clock24 ? Qt.formatTime(clock.date, "hh:mm") : (clock.date.getHours() % 12 || 12) + Qt.formatTime(clock.date, ":mm")
                        font.pixelSize: 72
                    }
                    Lb { topPadding: 12; text: `${root.en.toString(clock.date, "d MMMM")} · week ${root.week(clock.date)}` }
                    Item { width: 1; height: 24 }
                    Seg { width: parent.width; height: 6; n: 24; f: Weather.sun ? (clock.date - Weather.sun.rise) / (Weather.sun.set - Weather.sun.rise) : 0 }
                    Item {
                        width: parent.width
                        height: 28
                        Meta { y: 12; icon: "\u{F059C}"; text: Weather.sun ? root.hm(Weather.sun.rise) : "--:--" }
                        Meta { y: 12; anchors.right: parent.right; icon: "\u{F059B}"; text: Weather.sun ? root.hm(Weather.sun.set) : "--:--" }
                    }
                }
            }

            // Weather: current temperature with dot matrix glyph and 4-day forecast
            Component {
                id: weatherC
                Column {
                    width: 188
                    Lb { width: parent.width; elide: Text.ElideRight; text: Weather.ok ? Weather.name(Weather.now.code) : "no sky" }
                    Item { width: 1; height: 10 }
                    Row {
                        spacing: 8
                        Icon {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Weather.glyph(Weather.now?.code ?? 3, Weather.now?.day)
                            font.pixelSize: 48
                            layer.enabled: true
                            layer.effect: Dm { step: 3 }
                        }
                        Num { anchors.verticalCenter: parent.verticalCenter; text: Weather.ok ? Math.round(Weather.now.temp) + "°" : "--"; font.pixelSize: 54 }
                    }
                    Lb { topPadding: 8; visible: Weather.ok; text: `feels ${Math.round(Weather.now?.feels)}° · ${Math.round(Weather.now?.wind)} m/s`; px: 11 }
                    Item { width: 1; height: 18 }
                    Row {
                        spacing: 8
                        Repeater {
                            model: Weather.days.slice(1, 5)
                            Column {
                                required property var modelData
                                required property int index
                                width: 41
                                Lb { anchors.horizontalCenter: parent.horizontalCenter; text: root.en.dayName((clock.date.getDay() + index + 1) % 7, Locale.ShortFormat); px: 10 }
                                Icon {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    topPadding: lead + 6
                                    text: Weather.glyph(modelData.code, true)
                                    font.pixelSize: 24
                                    layer.enabled: true
                                    layer.effect: Dm { step: 2 }
                                }
                                Lb { anchors.horizontalCenter: parent.horizontalCenter; topPadding: 6; text: Math.round(modelData.max) + "°"; px: 11; color: Theme.fg }
                                Lb { anchors.horizontalCenter: parent.horizontalCenter; text: Math.round(modelData.min) + "°"; px: 11 }
                            }
                        }
                    }
                }
            }

            // Performance: CPU/RAM/GPU radial gauges, top processes, and per-core utilization matrix
            Component {
                id: perfC
                Column {
                    width: 300
                    Row {
                        spacing: 18
                        Gauge { on: win.open; f: SysStats.cpu; label: `cpu · ${Math.round(SysStats.cpuTemp)}°` }
                        Gauge { on: win.open; f: SysStats.mem; label: `mem · ${SysStats.memUsed.toFixed(1)}g` }
                        Gauge { on: win.open; f: SysStats.gpu; label: `gpu · ${Math.round(SysStats.gpuTemp)}°` }
                    }
                    Item { width: 1; height: 18 }
                    Row {
                        spacing: 14
                        Column {
                            width: 160
                            spacing: 4
                            Lb { bottomPadding: 2; text: "processes"; px: 10 }
                            Repeater {
                                model: SysStats.procs
                                Row {
                                    required property var modelData
                                    spacing: 6
                                    Lb { width: 78; elide: Text.ElideRight; text: modelData[0]; px: 10; color: Theme.fg }
                                    Lb { width: 34; horizontalAlignment: Text.AlignRight; text: Math.round(modelData[1]) + "%"; px: 10 }
                                    Seg { anchors.verticalCenter: parent.verticalCenter; width: 36; height: 5; n: 6; spacing: 3; f: modelData[1] / 100 }
                                }
                            }
                        }
                        Column {
                            width: 126
                            spacing: 6
                            Lb { text: `cores · ${SysStats.cpuFreq.toFixed(1)} ghz`; px: 10 }
                            // Per-core load column: white dot on top with grey levels below
                            Grid {
                                id: cores
                                readonly property int n: Math.max(1, SysStats.cores.length)
                                // Scaled to fit within root.h=232 budget (gauges + margins + label = <=86px for grid)
                                // Width calculated from fixed column width (126px) to avoid circular layout loops
                                readonly property real d: Math.min((126 - (n - 1) * spacing) / n, (86 - 7 * spacing) / 8)
                                width: n * d + (n - 1) * spacing
                                // Center grid within column
                                anchors.horizontalCenter: parent.horizontalCenter
                                columns: n
                                spacing: 3
                                Repeater {
                                    model: cores.n * 8
                                    Rectangle {
                                        required property int index
                                        readonly property int up: 8 - Math.floor(index / cores.n) // Rows 8 (top) to 1 (bottom)
                                        readonly property int lvl: Math.round(1 + 7 * (SysStats.cores[index % cores.n] ?? 0))
                                        width: cores.d
                                        height: cores.d
                                        radius: 0
                                        color: up === lvl ? Theme.hazard : up < lvl ? Theme.crimson : Theme.s2
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Network bandwidth: download/upload rates with 40s history matrix (download grows up, upload grows down)
            Component {
                id: netC
                Column {
                    width: 176
                    Lb { width: parent.width; elide: Text.ElideRight; text: "net · " + (SysStats.iface || "offline") }
                    Item { width: 1; height: 10 }
                    Speed { icon: "\u{F0045}"; b: SysStats.rx }
                    Item { width: 1; height: 8 }
                    Speed { icon: "\u{F005D}"; b: SysStats.tx }
                    Item { width: 1; height: 18 }
                    Grid {
                        id: hist
                        // Scale based on peak throughput (minimum 10 kB/s threshold to avoid noise at idle)
                        readonly property real peak: Math.max(10240, ...root.net.map(p => Math.max(p[0], p[1])))
                        readonly property real d: (width - 19 * spacing) / 20
                        width: parent.width
                        columns: 20
                        spacing: 3
                        Repeater {
                            model: 20 * 10
                            Rectangle {
                                required property int index
                                readonly property int r: Math.floor(index / 20) // Row index (0..9 top to bottom)
                                readonly property bool tx: r >= 5
                                readonly property var p: root.net[index % 20 - 20 + root.net.length] ?? [0, 0]
                                readonly property bool lit: (tx ? r - 4 : 5 - r) <= Math.ceil(5 * (tx ? p[1] : p[0]) / hist.peak)
                                width: hist.d
                                height: hist.d
                                radius: 0
                                color: lit ? (tx ? Theme.hazard : Theme.crimson) : Theme.s2
                            }
                        }
                    }
                }
            }

            // Media player: rotating halftone album art disc, title, artist, progress, and controls
            Component {
                id: mediaC
                Column {
                    width: 240
                    Lb { width: parent.width; elide: Text.ElideRight; text: Media.player?.identity ?? "silence" }
                    Item { width: 1; height: 12 }
                    Row {
                        spacing: 14
                        Item {
                            id: art
                            width: 84
                            height: 84
                            property real turn: 0
                            Timer { running: win.open && Media.playing; interval: 33; repeat: true; onTriggered: art.turn = (art.turn + 360 / 14 / 30) % 360 }
                            Art { anchors.fill: parent; rotation: art.turn; url: Media.player?.trackArtUrl ?? ""; step: 5 }
                            Rectangle {
                                anchors.fill: parent
                                color: "transparent"
                                border { width: 1; color: Theme.accent }
                            }
                        }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 142
                            Text {
                                width: parent.width
                                wrapMode: Text.Wrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                                text: Media.player?.trackTitle || "Nothing on"
                                textFormat: Text.PlainText
                                font { family: Theme.mono; pixelSize: 14; bold: true }
                                color: Theme.hazard
                            }
                            Text { textFormat: Text.PlainText; width: parent.width; elide: Text.ElideRight; text: Media.player?.trackArtist ?? ""; font { family: Theme.mono; pixelSize: 11 } color: Theme.grey }
                        }
                    }
                    Item { width: 1; height: 16 }
                    // Progress bar (some players like Firefox do not report total track duration)
                    Seg { width: parent.width; height: 6; n: 20; f: Media.player?.lengthSupported && Media.player.length > 0 ? Media.position / Media.player.length : 0 }
                    Item {
                        width: parent.width
                        height: 26
                        visible: !!Media.player
                        Lb { y: 8; text: Media.time(Media.position); px: 11 }
                        Lb { y: 8; anchors.right: parent.right; visible: !!Media.player?.lengthSupported; text: Media.time(Media.player?.length); px: 11 }
                    }
                    Item { width: 1; height: 8 }
                    Controls { anchors.horizontalCenter: parent.horizontalCenter; size: 20; play: 48 }
                }
            }

            // MAGI Supercomputer Tri-Cluster & Eva Synchronicity Section
            Component {
                id: magiC
                Column {
                    width: 220
                    Lb { width: parent.width; text: "magi · consensus 3/3"; px: 11; font.bold: true; color: Theme.hazard }
                    Item { width: 1; height: 8 }

                    // Tri-Cluster voting cards
                    Column {
                        width: parent.width
                        spacing: 4
                        Repeater {
                            model: [
                                { name: "MELCHIOR-1", role: "SCIENTIST", code: "CODE 474", vote: "AFFIRMATIVE" },
                                { name: "BALTHASAR-2", role: "MOTHER", code: "CODE 474", vote: "AFFIRMATIVE" },
                                { name: "CASPAR-3", role: "WOMAN", code: "CODE 474", vote: "AFFIRMATIVE" }
                            ]
                            Rectangle {
                                required property var modelData
                                width: parent.width
                                height: 32
                                radius: 0
                                color: Theme.s2
                                border { width: 1; color: Theme.line }

                                Row {
                                    anchors { left: parent.left; leftMargin: 8; right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                                    spacing: 6
                                    Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 4; height: 16; color: Theme.accent }
                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter
                                        Text {
                                            text: parent.parent.parent.modelData.name
                                            font { family: Theme.mono; pixelSize: 10; bold: true }
                                            color: Theme.hazard
                                        }
                                        Text {
                                            text: parent.parent.parent.modelData.role + " // " + parent.parent.parent.modelData.code
                                            font { family: Theme.mono; pixelSize: 8 }
                                            color: Theme.mute
                                        }
                                    }
                                    Item { width: 1; height: 1 }
                                    Text {
                                        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                                        text: "[ AGREE ]"
                                        font { family: Theme.mono; pixelSize: 9; bold: true }
                                        color: Theme.crimson
                                    }
                                }
                            }
                        }
                    }

                    Item { width: 1; height: 10 }

                    // Eva Synch Ratio readout
                    Rectangle {
                        width: parent.width
                        height: 56
                        radius: 0
                        color: Theme.s2
                        border { width: 1; color: Theme.accent }

                        Column {
                            anchors { fill: parent; margins: 6 }
                            spacing: 4
                            Row {
                                width: parent.width
                                Text {
                                    text: "EVA-01 SYNCH"
                                    font { family: Theme.mono; pixelSize: 9; bold: true }
                                    color: Theme.hazard
                                }
                                Text {
                                    anchors.right: parent.right
                                    text: "88.5%"
                                    font { family: Theme.mono; pixelSize: 11; bold: true }
                                    color: Theme.crimson
                                }
                            }
                            // Segmented bar for synch
                            Seg { width: parent.width; height: 6; n: 16; f: 0.885; on: Theme.crimson; off: Theme.s3 }
                            Text {
                                text: "HARMONIC DISTORTION: ±0.012% [STABLE]"
                                font { family: Theme.mono; pixelSize: 8 }
                                color: Theme.mute
                            }
                        }
                    }
                }
            }
        }
    }

    // Radial gauge with centered value and label; dots animate in on panel reveal
    component Gauge: Column {
        id: g
        property real f
        property bool on
        property string label
        spacing: 8
        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 88
            height: 88
            Ring { anchors.fill: parent; n: 32; dot: 4; f: g.on ? g.f : 0 }
            Num { anchors.centerIn: parent; text: Math.round(g.f * 100); font.pixelSize: 30 }
        }
        Lb { anchors.horizontalCenter: parent.horizontalCenter; text: g.label; px: 10 }
    }
    // Bandwidth rate indicator: icon, Doto numeric value, and unit label
    component Speed: Row {
        id: sp
        property string icon
        property real b
        readonly property var v: SysStats.rate(b).split(" ")
        spacing: 8
        Icon { anchors.verticalCenter: parent.verticalCenter; text: sp.icon; font.pixelSize: 18 }
        Num { anchors.verticalCenter: parent.verticalCenter; text: sp.v[0]; font.pixelSize: 44 }
        Lb { anchors.verticalCenter: parent.verticalCenter; text: sp.v[1]; px: 11 }
    }
    component Meta: Row {
        id: m
        property string icon
        property string text
        spacing: 8
        Icon { anchors.verticalCenter: parent.verticalCenter; text: m.icon; font.pixelSize: 16 }
        Lb { anchors.verticalCenter: parent.verticalCenter; text: m.text; px: 11 }
    }
}

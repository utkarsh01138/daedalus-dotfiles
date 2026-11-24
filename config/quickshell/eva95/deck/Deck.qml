import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Networking
import Quickshell.Services.UPower
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

    // When open, enable detailed polling for CPU/memory/network stats & Cava audio visualizer
    Binding { target: Sys; property: "deckOpen"; value: root.on !== null }
    Binding { target: SysStats; property: "perf"; value: root.on !== null }
    Binding { target: Cava; property: "active"; value: root.on !== null && Media.playing }

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
            WlrLayershell.namespace: "eva95-deck"
            mask: Region {
                y: win.open ? 0 : win.height - 4
                width: win.width
                height: win.open ? win.height : 4
            }

            Timer { id: dwell; interval: 150; onTriggered: root.on = win.modelData }
            Timer { id: leave; interval: 300; onTriggered: if (win.open && !root.pinned) root.on = null }

            // 15% subtle warm black scrim covers the entire screen, click dismisses deck
            Rectangle {
                anchors.fill: parent
                color: "#000000"
                opacity: 0.15 * win.t
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
                        height: 26
                        color: Theme.accent
                        Row {
                            anchors.centerIn: parent
                            spacing: 8
                            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 5; height: 5; color: "#08080A" }
                            Text {
                                text: "■ 特務機関 NERV // 戦術診断コンソール // MAGI-01 TRICLUSTER DECK"
                                font { family: Theme.mono; pixelSize: 10; bold: true; letterSpacing: 1.2 }
                                color: "#08080A"
                            }
                            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 5; height: 5; color: "#08080A" }
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
                        // Authentic Real-Time CRT Segmented Audio Spectrum Visualizer (Cava)
                        Rectangle {
                            width: 84
                            height: 84
                            radius: 0
                            color: Theme.s2
                            border { width: 1; color: Media.playing ? Theme.accent : Theme.line }

                            Row {
                                anchors.centerIn: parent
                                spacing: 3
                                Repeater {
                                    model: 8
                                    Column {
                                        id: freqCol
                                        required property int index
                                        readonly property real val: Math.min(1.0, Math.max(0.0, Cava.bars[index] ?? 0))
                                        spacing: 2
                                        Repeater {
                                            model: 12
                                            Rectangle {
                                                id: segRect
                                                required property int index
                                                readonly property real thresh: (11 - index) / 12
                                                readonly property bool lit: Media.playing && freqCol.val > thresh
                                                width: 7
                                                height: 4
                                                radius: 0
                                                color: lit
                                                    ? (index < 3 ? Theme.hazard : index < 7 ? Theme.amber : Theme.phosphor)
                                                    : Theme.s3
                                                opacity: lit ? 1.0 : 0.25
                                            }
                                        }
                                    }
                                }
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
                                text: Media.player?.trackTitle || "Terminal Dogma Audio"
                                textFormat: Text.PlainText
                                font { family: Theme.mono; pixelSize: 13; bold: true }
                                color: Theme.hazard
                            }
                            Text { textFormat: Text.PlainText; width: parent.width; elide: Text.ElideRight; text: Media.player?.trackArtist ?? "MAGI Acoustic Bus"; font { family: Theme.mono; pixelSize: 10 } color: Theme.grey }
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
                    id: magiCol
                    width: 236

                    // Live hardware-linked decisions for the 3 MAGI nodes:
                    // MELCHIOR-1 (Scientist): Kernel, CPU thread load and thermal headroom
                    readonly property bool mAgree: SysStats.cpu < 0.85 && SysStats.cpuTemp < 82
                    readonly property string mSub: `CPU ${Math.round(SysStats.cpu * 100)}% · ${Math.round(SysStats.cpuTemp)}°C`
                    readonly property string mVote: mAgree ? "[ NOMINAL ]" : "[ OVERLOAD ]"

                    // BALTHASAR-2 (Mother): System preservation, Memory buffer, and Battery/AC umbilical
                    readonly property bool bAgree: SysStats.mem < 0.90 && (!UPower.displayDevice?.present || (UPower.displayDevice?.percentage ?? 100) > 15 || UPower.displayDevice?.state === 1)
                    readonly property string bSub: `MEM ${SysStats.memUsed.toFixed(1)}G · ${UPower.displayDevice?.present ? Math.round(UPower.displayDevice.percentage) + "%" : "AC"}`
                    readonly property string bVote: bAgree ? "[ PROTECT ]" : "[ CRITICAL ]"

                    // CASPAR-3 (Woman): Communication bus, active network link, and data throughput
                    readonly property bool cAgree: (SysStats.rx + SysStats.tx > 50) || Networking.connectivity === NetworkConnectivity.Full || (SysStats.iface && SysStats.iface !== "")
                    readonly property string cSub: `${SysStats.iface || "OFFLINE"} · ↓${Math.round(SysStats.rx / 1024)}K ↑${Math.round(SysStats.tx / 1024)}K`
                    readonly property string cVote: cAgree ? "[ LINK OK ]" : "[ SEVERED ]"

                    // Tri-Cluster Consensus Count
                    readonly property int consensus: (mAgree ? 1 : 0) + (bAgree ? 1 : 0) + (cAgree ? 1 : 0)

                    // Eva-01 Synchronicity Ratio: dynamically modulated by CPU frequency and load
                    readonly property real synchVal: Math.min(0.999, Math.max(0.680, 0.85 + (SysStats.cpuFreq / 4.4) * 0.10 - SysStats.cpu * 0.08))

                    Row {
                        width: parent.width
                        spacing: 8
                        AnimatedImage {
                            width: 20
                            height: 20
                            anchors.verticalCenter: parent.verticalCenter
                            source: Quickshell.shellPath("assets/gifs/opt/ja_fuel_bundle_hex_reactor_2x.gif")
                            fillMode: Image.PreserveAspectFit
                            playing: win.open
                        }
                        Lb {
                            anchors.verticalCenter: parent.verticalCenter
                            text: `magi · consensus ${magiCol.consensus}/3`
                            px: 11
                            font.bold: true
                            color: magiCol.consensus === 3 ? Theme.hazard : magiCol.consensus === 2 ? Theme.amber : Theme.red
                        }
                    }
                    Item { width: 1; height: 8 }

                    // Tri-Cluster voting cards
                    Column {
                        width: parent.width
                        spacing: 4

                        // Melchior-1 (Scientist)
                        Rectangle {
                            width: parent.width
                            height: 32
                            radius: 0
                            color: Theme.s2
                            border { width: 1; color: magiCol.mAgree ? Theme.line : Theme.red }

                            Row {
                                anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
                                spacing: 6
                                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 4; height: 16; color: magiCol.mAgree ? Theme.phosphor : Theme.red }
                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    Text {
                                        text: "MELCHIOR-1 // SCIENTIST"
                                        font { family: Theme.mono; pixelSize: 9; bold: true }
                                        color: magiCol.mAgree ? Theme.phosphor : Theme.red
                                    }
                                    Text {
                                        text: magiCol.mSub
                                        font { family: Theme.mono; pixelSize: 8 }
                                        color: Theme.mute
                                    }
                                }
                            }
                            Text {
                                anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                                text: magiCol.mVote
                                font { family: Theme.mono; pixelSize: 9; bold: true }
                                color: magiCol.mAgree ? Theme.phosphor : Theme.red
                            }
                        }

                        // Balthasar-2 (Mother)
                        Rectangle {
                            width: parent.width
                            height: 32
                            radius: 0
                            color: Theme.s2
                            border { width: 1; color: magiCol.bAgree ? Theme.line : Theme.red }

                            Row {
                                anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
                                spacing: 6
                                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 4; height: 16; color: magiCol.bAgree ? Theme.phosphor : Theme.red }
                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    Text {
                                        text: "BALTHASAR-2 // MOTHER"
                                        font { family: Theme.mono; pixelSize: 9; bold: true }
                                        color: magiCol.bAgree ? Theme.phosphor : Theme.red
                                    }
                                    Text {
                                        text: magiCol.bSub
                                        font { family: Theme.mono; pixelSize: 8 }
                                        color: Theme.mute
                                    }
                                }
                            }
                            Text {
                                anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                                text: magiCol.bVote
                                font { family: Theme.mono; pixelSize: 9; bold: true }
                                color: magiCol.bAgree ? Theme.phosphor : Theme.red
                            }
                        }

                        // Caspar-3 (Woman)
                        Rectangle {
                            width: parent.width
                            height: 32
                            radius: 0
                            color: Theme.s2
                            border { width: 1; color: magiCol.cAgree ? Theme.line : Theme.red }

                            Row {
                                anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
                                spacing: 6
                                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 4; height: 16; color: magiCol.cAgree ? Theme.phosphor : Theme.red }
                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    Text {
                                        text: "CASPAR-3 // WOMAN"
                                        font { family: Theme.mono; pixelSize: 9; bold: true }
                                        color: magiCol.cAgree ? Theme.phosphor : Theme.red
                                    }
                                    Text {
                                        text: magiCol.cSub
                                        font { family: Theme.mono; pixelSize: 8 }
                                        color: Theme.mute
                                    }
                                }
                            }
                            Text {
                                anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                                text: magiCol.cVote
                                font { family: Theme.mono; pixelSize: 9; bold: true }
                                color: magiCol.cAgree ? Theme.phosphor : Theme.red
                            }
                        }
                    }

                    Item { width: 1; height: 10 }

                    // Eva Synch Ratio readout with Animated Harmonic Oscilloscope Waveform
                    Rectangle {
                        width: parent.width
                        height: 64
                        radius: 0
                        color: Theme.s2
                        border { width: 1; color: Theme.accent }
                        clip: true

                        AnimatedImage {
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectCrop
                            source: Quickshell.shellPath("assets/gifs/opt/synch_harmonics_oscilloscope_2x.gif")
                            opacity: 0.35
                            playing: win.open
                        }

                        Column {
                            anchors { fill: parent; margins: 6 }
                            spacing: 4
                            Item {
                                width: parent.width
                                height: 16
                                Text {
                                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                                    text: "EVA-01 SYNCH"
                                    font { family: Theme.mono; pixelSize: 9; bold: true }
                                    color: Theme.hazard
                                }
                                Text {
                                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                                    text: (magiCol.synchVal * 100).toFixed(1) + "%"
                                    font { family: Theme.mono; pixelSize: 11; bold: true }
                                    color: Theme.amber
                                }
                            }
                            // Segmented bar for synch
                            Seg { width: parent.width; height: 6; n: 16; f: magiCol.synchVal; on: Theme.amber; off: Theme.s3 }
                            Text {
                                text: `HARMONIC DISTORTION: ±0.0${Math.floor(SysStats.cpu * 35 + 8)}% [${SysStats.cpu > 0.8 ? "DRIFT" : "STABLE"}]`
                                font { family: Theme.mono; pixelSize: 8 }
                                color: Theme.chalk
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

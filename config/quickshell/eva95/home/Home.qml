import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Hyprland
import Quickshell.Services.UPower
import Quickshell.Wayland
import qs
import qs.components
import qs.services

// =============================================================================
// EVA-95 CENTRAL DOGMA MAIN TACTICAL COMMAND CONSOLE (1995 NGE TV SERIES STYLE)
// =============================================================================
// Ultra-Maximalist Hideaki Anno / Gainax CRT Terminal UI:
// - Heavy solid amber/red header banners with inverted black Japanese text
// - Animated MAGI PCB & memory buses (magi_amber_pcb_bus, magi_memory_bus_green)
// - Terminal Dogma energy spectrum & Geofront subterranean core display
// - DUMMY PLUG SYSTEM (Rei 00) backup protocol module
// - 3D Topological synch waveforms & A-10 neural telemetry
// - Tactical ordnance rack & combat equipment readiness
// - Diagonal emergency hazard chevrons (/// /// ///)
// - Solid inverted status stamps (【 承 認 】, 【 外部電源接続中 】, 【 活動限界 】, 【 全会一致 】)
// - Tripartite MAGI-01 deliberation blades (Melchior-1, Balthasar-2, Caspar-3)
// - Bio-metric pilot vitals grid (Pulse, EEG, LCL pressure, Psyche contamination)
// - Dual Extreme-Flank Layout: Panels sit exclusively at x: 20 and anchors.right: 20 (width: 360)
//   leaving the entire 1160px center completely open and unobstructed for the Lilith artwork.
PanelWindow {
    id: root

    anchors { left: true; right: true; top: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "eva95-home"

    function idle(s) { return (Hyprland.monitorFor(s)?.activeWorkspace?.toplevels.values.length ?? 0) === 0; }
    readonly property bool home: visible && idle(screen)
    readonly property var homes: Quickshell.screens.filter(s => Theme.scr(s.name, "home") && idle(s))
    readonly property bool larp: Theme.state.larp ?? true

    Binding { target: SysStats; property: "detailed"; value: (root.homes.length > 0 && root.larp) || Sys.deckOpen }
    Binding { target: Cava; property: "active"; value: ((root.homes.length > 0 && root.larp) || Sys.deckOpen) && Media.playing }

    SystemClock { id: clock; precision: SystemClock.Seconds }
    readonly property var en: Qt.locale("en_US")
    readonly property var bat: UPower.displayDevice
    readonly property var player: Media.player

    // Blinking colon indicator (500ms cycle)
    property bool dim: false
    Timer { running: root.home && Theme.state.blink; interval: 500; repeat: true; onTriggered: root.dim = !root.dim }

    // Frantic centisecond ticker for battery countdown (67ms cycle)
    property int centisec: 28
    Timer { running: root.home; interval: 67; repeat: true; onTriggered: root.centisec = Math.floor(Math.random() * 90 + 10) }

    // System Alert State (>85% CPU or >80°C or battery < 15%)
    readonly property bool isAlert: SysStats.cpu > 0.85 || SysStats.cpuTemp > 80 || (bat.onBattery && bat.percentage < 0.15)

    // Hardware-modulated Eva-01 Synchronicity Ratio
    readonly property real synchRatio: Math.min(0.999, Math.max(0.680, 0.85 + (SysStats.cpuFreq / 4.4) * 0.10 - SysStats.cpu * 0.08))

    // Dynamic Pilot Bio-telemetry tied directly to live system stress:
    // Pulse: baseline 68 bpm + CPU workload * 32 + thermal stress
    readonly property int pilotBpm: Math.round(68 + SysStats.cpu * 32 + Math.max(0, SysStats.cpuTemp - 55) * 1.2)
    // EEG (Brainwave): Alpha (8-13Hz) in resting state, shifts to Beta (14-30Hz) under computation
    readonly property real pilotEeg: Math.min(28.5, 9.8 + (SysStats.cpuFreq / 4.4) * 6.5 + SysStats.cpu * 8.2)
    // LCL Pressure: Modulated by system memory usage
    readonly property real lclPressure: 1.00 + SysStats.mem * 0.12
    // Psyche Contamination: Spikes when temperature > 80C, swap is active, or alert state
    readonly property real contamination: Math.min(99.9, (SysStats.cpuTemp > 80 ? (SysStats.cpuTemp - 80) * 1.8 : 0) + (SysStats.swapUsed > 0 ? (SysStats.swapUsed / (SysStats.swapTotal || 1)) * 12 : 0) + (root.isAlert ? 8.4 : 0))

    // Reusable Component: 1995 Evangelion Diagonal Hazard Warning Tape
    component HazardTape: Canvas {
        property color stripeColor: Theme.accent
        property color bg: "#08080A"
        height: 4
        onPaint: {
            var ctx = getContext("2d");
            ctx.fillStyle = bg;
            ctx.fillRect(0, 0, width, height);
            ctx.fillStyle = stripeColor;
            for (var x = -height * 2; x < width + height * 2; x += 8) {
                ctx.beginPath();
                ctx.moveTo(x, height);
                ctx.lineTo(x + 4, height);
                ctx.lineTo(x + 7, 0);
                ctx.lineTo(x + 3, 0);
                ctx.closePath();
                ctx.fill();
            }
        }
        onStripeColorChanged: requestPaint()
        onWidthChanged: requestPaint()
    }

    // Reusable Component: CRT Technical Corner Reticles
    component CornerReticles: Item {
        anchors.fill: parent
        property color reticleColor: Theme.hazard
        Rectangle { x: -1; y: -1; width: 6; height: 1; color: reticleColor }
        Rectangle { x: -1; y: -1; width: 1; height: 6; color: reticleColor }
        Rectangle { anchors.right: parent.right; anchors.rightMargin: -1; y: -1; width: 6; height: 1; color: reticleColor }
        Rectangle { anchors.right: parent.right; anchors.rightMargin: -1; y: -1; width: 1; height: 6; color: reticleColor }
        Rectangle { x: -1; anchors.bottom: parent.bottom; anchors.bottomMargin: -1; width: 6; height: 1; color: reticleColor }
        Rectangle { x: -1; anchors.bottom: parent.bottom; anchors.bottomMargin: -1; width: 1; height: 6; color: reticleColor }
        Rectangle { anchors.right: parent.right; anchors.rightMargin: -1; anchors.bottom: parent.bottom; anchors.bottomMargin: -1; width: 6; height: 1; color: reticleColor }
        Rectangle { anchors.right: parent.right; anchors.rightMargin: -1; anchors.bottom: parent.bottom; anchors.bottomMargin: -1; width: 1; height: 6; color: reticleColor }
    }

    Stage {
        id: stage
        x: 0
        y: 0

        // =========================================================================
        // LEFT FLANK: NERV COMMAND POST & VITALS (Extreme Left Edge: x: 20, width: 360)
        // =========================================================================
        Column {
            x: 20
            y: 44
            width: 360
            spacing: 8

            // ---------------------------------------------------------------------
            // CARD 1: 戦術標準時 // Chrono Telemetry & Pilot Biological Registry
            // ---------------------------------------------------------------------
            Rectangle {
                width: parent.width
                height: 180
                radius: 0
                color: root.larp ? Qt.rgba(0.06, 0.05, 0.04, 0.88) : "transparent"
                border { width: root.larp ? 1 : 0; color: Theme.accent }

                CornerReticles { visible: root.larp }

                Column {
                    anchors.fill: parent

                    // 1995 TV Show Solid Amber Header Banner
                    Rectangle {
                        visible: root.larp
                        width: parent.width
                        height: 22
                        radius: 0
                        color: Theme.accent

                        Row {
                            anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
                            spacing: 6
                            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 5; height: 5; color: "#08080A" }
                            Text {
                                text: "■ CHRONO TELEMETRY // ネルフ中央作戦司令所"
                                font { family: Theme.mono; pixelSize: 9; bold: true; letterSpacing: 0.8 }
                                color: "#08080A"
                            }
                        }

                        // Status Stamp (Right Header)
                        Rectangle {
                            anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                            height: 15
                            width: 60
                            radius: 0
                            color: "#08080A"
                            Text {
                                anchors.centerIn: parent
                                text: "【 正常稼働 】"
                                font { family: Theme.eva; pixelSize: 8; bold: true }
                                color: Theme.phosphor
                            }
                        }
                    }

                    // Emergency Hazard Tape
                    HazardTape {
                        visible: root.larp
                        width: parent.width
                        stripeColor: Theme.accent
                    }

                    Column {
                        anchors { left: parent.left; right: parent.right; margins: 10 }
                        spacing: 3

                        // Giant Evangelion Mincho Clock Digits with Running Seconds
                        Row {
                            spacing: 4
                            Num { text: Theme.hh(clock.date); font.pixelSize: 42; color: Theme.fg }
                            Num { text: ":"; font.pixelSize: 42; color: Theme.hazard; opacity: root.dim ? 0.25 : 1 }
                            Num { text: Qt.formatTime(clock.date, "mm"); font.pixelSize: 42; color: Theme.fg }
                            Num { text: ":"; font.pixelSize: 42; color: Theme.hazard; opacity: root.dim ? 0.25 : 1 }
                            Num { text: Qt.formatTime(clock.date, "ss"); font.pixelSize: 42; color: Theme.chalk }
                        }

                        Text {
                            text: `DATE: ${Qt.formatDate(clock.date, "yyyy.MM.dd")} [${root.en.toString(clock.date, "dddd").toUpperCase()}] // A.D. 2026`
                            font { family: Theme.mono; pixelSize: 9; bold: true; letterSpacing: 0.8 }
                            color: Theme.chalk
                        }

                        Text {
                            text: `OPERATOR: ${(Theme.state.name || Quickshell.env("USER")).toUpperCase()} // PILOT: THIRD CHILDREN`
                            font { family: Theme.mono; pixelSize: 8; bold: true }
                            color: Theme.mute
                            elide: Text.ElideRight
                            width: parent.width
                        }

                        // Pilot Biological Telemetry Grid (Live Hardware Modulation)
                        Row {
                            spacing: 4
                            Rectangle {
                                width: 78; height: 16; color: Theme.s2; border { width: 1; color: root.pilotBpm > 95 ? Theme.hazard : Theme.line }
                                Text { anchors.centerIn: parent; text: `心拍 ${root.pilotBpm} bpm`; font { family: Theme.mono; pixelSize: 8; bold: true } color: root.pilotBpm > 95 ? Theme.hazard : Theme.phosphor }
                            }
                            Rectangle {
                                width: 84; height: 16; color: Theme.s2; border { width: 1; color: Theme.line }
                                Text { anchors.centerIn: parent; text: `脳波 ${root.pilotEeg > 13 ? "β" : "α"} ${root.pilotEeg.toFixed(1)}Hz`; font { family: Theme.mono; pixelSize: 8; bold: true } color: Theme.chalk }
                            }
                            Rectangle {
                                width: 86; height: 16; color: Theme.s2; border { width: 1; color: Theme.line }
                                Text { anchors.centerIn: parent; text: `LCL ${root.lclPressure.toFixed(2)} atm`; font { family: Theme.mono; pixelSize: 8; bold: true } color: Theme.hazard }
                            }
                            Rectangle {
                                width: 80; height: 16; color: Theme.s2; border { width: 1; color: root.contamination > 1 ? Theme.red : Theme.line }
                                Text { anchors.centerIn: parent; text: `汚染度 ${root.contamination.toFixed(2)}%`; font { family: Theme.mono; pixelSize: 8; bold: true } color: root.contamination > 1 ? Theme.red : Theme.phosphor }
                            }
                        }

                        Row {
                            spacing: 6
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                height: 15
                                width: 110
                                color: root.contamination > 5.0 ? Theme.red : root.pilotBpm > 95 ? Theme.hazard : Theme.phosphor
                                Text {
                                    anchors.centerIn: parent
                                    text: root.contamination > 5.0 ? "【 精神汚染警戒 】" : root.pilotBpm > 95 ? "【 心拍数上昇中 】" : "【 心拍・脳波: 正常 】"
                                    font { family: Theme.eva; pixelSize: 8; bold: true }
                                    color: "#08080A"
                                }
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "ENTRY PLUG NO. 01 // A-10 OK"
                                font { family: Theme.mono; pixelSize: 8; bold: true }
                                color: Theme.chalk
                            }
                        }
                    }
                }
            }

            // ---------------------------------------------------------------------
            // CARD 2: 活動限界 // Evangelion Umbilical Cable & Battery (LARP Mode)
            // ---------------------------------------------------------------------
            Rectangle {
                visible: root.larp
                width: parent.width
                height: 175
                radius: 0
                color: Qt.rgba(0.06, 0.05, 0.04, 0.88)
                border { width: 1; color: !bat.onBattery ? Theme.accent : bat.percentage < 0.2 ? Theme.red : Theme.hazard }

                CornerReticles { reticleColor: !bat.onBattery ? Theme.accent : Theme.red }

                Column {
                    anchors.fill: parent

                    // 1995 TV Show Solid Header Banner
                    Rectangle {
                        width: parent.width
                        height: 22
                        radius: 0
                        color: !bat.onBattery ? Theme.accent : Theme.red

                        Row {
                            anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
                            spacing: 6
                            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 5; height: 5; color: "#08080A" }
                            Text {
                                text: !bat.onBattery ? "■ 外部電源接続中 // UMBILICAL POWER FEED" : "■ 活動限界 COUNTDOWN // 内部電源作動"
                                font { family: Theme.mono; pixelSize: 9; bold: true; letterSpacing: 0.8 }
                                color: "#08080A"
                            }
                        }
                    }

                    // Hazard Tape
                    HazardTape {
                        width: parent.width
                        stripeColor: !bat.onBattery ? Theme.accent : Theme.red
                    }

                    Column {
                        anchors { left: parent.left; right: parent.right; margins: 10 }
                        spacing: 5

                        // 1995 TV Show Status Stamp Block
                        Row {
                            spacing: 8
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                height: 18
                                width: 110
                                radius: 0
                                color: !bat.onBattery ? Theme.phosphor : Theme.red
                                Text {
                                    anchors.centerIn: parent
                                    text: !bat.onBattery ? "【 外部電源接続中 】" : "【 内部電源作動 】"
                                    font { family: Theme.eva; pixelSize: 8; bold: true }
                                    color: "#08080A"
                                }
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: !bat.onBattery ? "供給電圧: 正常 (100V AC // 50Hz)" : "活動限界まで (TIME REMAINING)"
                                font { family: Theme.eva; pixelSize: 8; bold: true }
                                color: !bat.onBattery ? Theme.phosphor : Theme.hazard
                            }
                        }

                        // Massive 1995 TV Show Countdown Digits with Frantic Centiseconds
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: {
                                if (!bat.onBattery) return "ACTIVE [UNLIMITED]";
                                const sec = bat.timeToEmpty > 0 ? bat.timeToEmpty : Math.round(bat.percentage * 300);
                                const m = Math.floor(sec / 60);
                                const s = Math.floor(sec % 60);
                                return `0${m}:${s < 10 ? "0" : ""}${s}.${root.centisec}`;
                            }
                            font { family: Theme.mono; pixelSize: 26; bold: true; letterSpacing: 2 }
                            color: !bat.onBattery ? Theme.phosphor : bat.percentage < 0.2 ? Theme.red : Theme.hazard
                        }

                        // 24-Segment Chunky Phosphor Discharge Gauge
                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 3
                            Repeater {
                                model: 24
                                Rectangle {
                                    required property int index
                                    width: 10
                                    height: 12
                                    radius: 0
                                    color: (index / 24) < bat.percentage
                                        ? (!bat.onBattery ? Theme.phosphor : bat.percentage < 0.2 ? Theme.red : Theme.accent)
                                        : Theme.s2
                                    border { width: 1; color: Theme.s3 }
                                }
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: `電力残量: ${Math.round(bat.percentage * 100)}% // DISCHARGE: ${bat.onBattery ? "ACTIVE [INTERNAL CELL]" : "ZERO [GRID LOCK]"}`
                            font { family: Theme.mono; pixelSize: 8; bold: true }
                            color: Theme.mute
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "PRIMARY UMBILICAL: LOCKED // AUXILIARY CABLE: STANDBY"
                            font { family: Theme.mono; pixelSize: 7; bold: true }
                            color: Theme.chalk
                        }
                    }
                }
            }

            // ---------------------------------------------------------------------
            // CARD 3: 主電算制御 // Host Kernel Telemetry (LARP Mode)
            // ---------------------------------------------------------------------
            Rectangle {
                visible: root.larp
                width: parent.width
                height: 185
                radius: 0
                color: Qt.rgba(0.06, 0.05, 0.04, 0.88)
                border { width: 1; color: Theme.accent }

                CornerReticles {}

                Column {
                    anchors.fill: parent

                    // 1995 TV Show Solid Header Banner
                    Rectangle {
                        width: parent.width
                        height: 22
                        radius: 0
                        color: Theme.accent

                        Row {
                            anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
                            spacing: 6
                            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 5; height: 5; color: "#08080A" }
                            Text {
                                text: "■ 主電算制御 // HOST SYSTEM HARDWARE TELEMETRY"
                                font { family: Theme.mono; pixelSize: 9; bold: true; letterSpacing: 0.8 }
                                color: "#08080A"
                            }
                        }
                    }

                    // Hazard Tape
                    HazardTape {
                        width: parent.width
                        stripeColor: Theme.accent
                    }

                    Column {
                        anchors { left: parent.left; right: parent.right; margins: 10 }
                        spacing: 5

                        // 4 Inverted Solid Telemetry Chips (1995 Anime Console Style)
                        Row {
                            spacing: 6
                            Rectangle {
                                width: 75; height: 22; radius: 0; color: Theme.s2; border { width: 1; color: Theme.line }
                                Text { anchors.centerIn: parent; text: `CPU ${Math.round(SysStats.cpu * 100)}%`; font { family: Theme.mono; pixelSize: 9; bold: true } color: Theme.fg }
                            }
                            Rectangle {
                                width: 85; height: 22; radius: 0; color: Theme.s2; border { width: 1; color: Theme.line }
                                Text { anchors.centerIn: parent; text: `RAM ${SysStats.memUsed.toFixed(1)}G`; font { family: Theme.mono; pixelSize: 9; bold: true } color: Theme.fg }
                            }
                            Rectangle {
                                width: 85; height: 22; radius: 0; color: Theme.s2; border { width: 1; color: Theme.line }
                                Text { anchors.centerIn: parent; text: `${SysStats.cpuFreq.toFixed(1)} GHz`; font { family: Theme.mono; pixelSize: 9; bold: true } color: Theme.chalk }
                            }
                            Rectangle {
                                width: 73; height: 22; radius: 0; color: Theme.s2; border { width: 1; color: Theme.line }
                                Text { anchors.centerIn: parent; text: `${Math.round(SysStats.cpuTemp)}°C`; font { family: Theme.mono; pixelSize: 9; bold: true } color: SysStats.cpuTemp > 80 ? Theme.red : Theme.phosphor }
                            }
                        }

                        // Mini Thread Oscillograph Matrix (16 cores)
                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 3
                            Repeater {
                                model: Math.min(16, SysStats.cores.length || 8)
                                Rectangle {
                                    required property int index
                                    readonly property real ld: SysStats.cores[index] ?? SysStats.cpu
                                    width: 17
                                    height: 16
                                    radius: 0
                                    color: ld > 0.85 ? Theme.red : ld > 0.6 ? Theme.hazard : Theme.s2
                                    border { width: 1; color: ld > 0.6 ? Theme.accent : Theme.s3 }
                                }
                            }
                        }

                        // Live Hex Addressing Sub-stream
                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 8
                            Text { text: "ADDR: 0x7FFF00"; font { family: Theme.mono; pixelSize: 8 } color: Theme.hazard }
                            Text { text: "RAW: A4B1 8F09 6C2D"; font { family: Theme.mono; pixelSize: 8 } color: Theme.chalk }
                            Text { text: "BUS: NOMINAL"; font { family: Theme.mono; pixelSize: 8; bold: true } color: Theme.phosphor }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: `通信回線: 正常接続 [${SysStats.iface || "ONLINE"}] // AMD RYZEN 7 5800HS`
                            font { family: Theme.mono; pixelSize: 8; bold: true }
                            color: Theme.mute
                        }
                    }
                }
            }

            // ---------------------------------------------------------------------
            // CARD 4: ジオフロント地下構造 // Terminal Dogma Core Energy Spectrum
            // ---------------------------------------------------------------------
            Rectangle {
                visible: root.larp
                width: parent.width
                height: 195
                radius: 0
                color: Qt.rgba(0.06, 0.05, 0.04, 0.88)
                border { width: 1; color: Theme.accent }

                CornerReticles {}

                Column {
                    anchors.fill: parent

                    // 1995 TV Show Solid Header Banner
                    Rectangle {
                        width: parent.width
                        height: 22
                        radius: 0
                        color: Theme.accent

                        Row {
                            anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
                            spacing: 6
                            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 5; height: 5; color: "#08080A" }
                            Text {
                                text: "■ ジオフロント地下構造 // TERMINAL DOGMA CORE MONITOR"
                                font { family: Theme.mono; pixelSize: 9; bold: true; letterSpacing: 0.8 }
                                color: "#08080A"
                            }
                        }
                    }

                    // Hazard Tape
                    HazardTape {
                        width: parent.width
                        stripeColor: Theme.accent
                    }

                    Column {
                        anchors { left: parent.left; right: parent.right; margins: 10 }
                        spacing: 5

                        // CRT Display: Terminal Dogma Energy Spectrum GIF
                        Rectangle {
                            width: parent.width
                            height: 95
                            color: Theme.s2
                            border { width: 1; color: Theme.line }
                            clip: true

                            AnimatedImage {
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectCrop
                                source: Quickshell.shellPath("assets/gifs/opt/terminal_dogma_energy_spectrum_2x.gif")
                                playing: true
                                opacity: 0.88
                            }

                            // Overlay Micro-Tag
                            Rectangle {
                                anchors { left: parent.left; top: parent.top; margins: 4 }
                                width: 90
                                height: 14
                                color: Qt.rgba(0, 0, 0, 0.75)
                                Text {
                                    anchors.centerIn: parent
                                    text: "B322F ENERGY FLUX"
                                    font { family: Theme.mono; pixelSize: 7; bold: true }
                                    color: Theme.amber
                                }
                            }
                        }

                        Row {
                            spacing: 6
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                height: 16
                                width: 125
                                color: Theme.phosphor
                                Text {
                                    anchors.centerIn: parent
                                    text: "【 LCL深度: -3,220m 】"
                                    font { family: Theme.eva; pixelSize: 8; bold: true }
                                    color: "#08080A"
                                }
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "集中防護隔壁 NO.01-24 全閉鎖"
                                font { family: Theme.mono; pixelSize: 8; bold: true }
                                color: Theme.chalk
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "使徒迎撃専用 兵装ビル群: 展開完了 // 地上戦備態勢"
                            font { family: Theme.mono; pixelSize: 7; bold: true }
                            color: Theme.mute
                        }
                    }
                }
            }

            // ---------------------------------------------------------------------
            // CARD 5: 特務機関 DUMMY PLUG PROTOCOL // Rei-00 Backup Control
            // ---------------------------------------------------------------------
            Rectangle {
                visible: root.larp
                width: parent.width
                height: 160
                radius: 0
                color: Qt.rgba(0.06, 0.05, 0.04, 0.88)
                border { width: 1; color: Theme.accent }

                CornerReticles {}

                Column {
                    anchors.fill: parent

                    // 1995 TV Show Solid Header Banner
                    Rectangle {
                        width: parent.width
                        height: 22
                        radius: 0
                        color: Theme.accent

                        Row {
                            anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
                            spacing: 6
                            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 5; height: 5; color: "#08080A" }
                            Text {
                                text: "■ 特務機関 DUMMY PLUG PROTOCOL // 予備制御システム"
                                font { family: Theme.mono; pixelSize: 9; bold: true; letterSpacing: 0.8 }
                                color: "#08080A"
                            }
                        }
                    }

                    // Hazard Tape
                    HazardTape {
                        width: parent.width
                        stripeColor: Theme.accent
                    }

                    Column {
                        anchors { left: parent.left; right: parent.right; margins: 10 }
                        spacing: 4

                        // CRT Display: Rei-00 Dummy Plug Warning GIF
                        Rectangle {
                            width: parent.width
                            height: 75
                            color: Theme.s2
                            border { width: 1; color: Theme.line }
                            clip: true

                            AnimatedImage {
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectCrop
                                source: Quickshell.shellPath("assets/gifs/opt/dummyplug_rei00_warning_2x.gif")
                                playing: true
                                opacity: 0.88
                            }
                        }

                        Row {
                            spacing: 6
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                height: 16
                                width: 135
                                color: Theme.hazard
                                Text {
                                    anchors.centerIn: parent
                                    text: "【 DUMMY PLUG: STANDBY 】"
                                    font { family: Theme.eva; pixelSize: 8; bold: true }
                                    color: "#08080A"
                                }
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "思考パターン: REI-00"
                                font { family: Theme.eva; pixelSize: 8; bold: true }
                                color: Theme.chalk
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "PROTOCOL: CODE-666 // SYNCH RESTRICTION: OVERRIDDEN"
                            font { family: Theme.mono; pixelSize: 7; bold: true }
                            color: Theme.mute
                        }
                    }
                }
            }

            // ---------------------------------------------------------------------
            // CARD 6: 特務機関 NERV Security Classification Badge (LARP Mode)
            // ---------------------------------------------------------------------
            Rectangle {
                visible: root.larp
                width: parent.width
                height: 44
                radius: 0
                color: root.isAlert ? Qt.rgba(0.25, 0.02, 0.02, 0.85) : Qt.rgba(0.06, 0.05, 0.04, 0.88)
                border { width: 1; color: root.isAlert ? Theme.red : Theme.accent }

                CornerReticles { reticleColor: root.isAlert ? Theme.red : Theme.hazard }

                Column {
                    anchors.centerIn: parent
                    spacing: 2

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 6
                        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 5; height: 5; color: root.isAlert ? Theme.red : Theme.phosphor }
                        Text {
                            text: root.isAlert ? "【 非常事態宣言 // 第一種警戒態勢発令中 】" : "【 特務機関 NERV // SECURITY CLEARANCE: LEVEL-A 】"
                            font { family: Theme.eva; pixelSize: 8; bold: true; letterSpacing: 0.8 }
                            color: root.isAlert ? Theme.red : Theme.hazard
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "\"GOD'S IN HIS HEAVEN, ALL'S RIGHT WITH THE WORLD.\""
                        font { family: Theme.mono; pixelSize: 7; bold: true; letterSpacing: 0.8 }
                        color: Theme.chalk
                    }
                }
            }
        }

        // =========================================================================
        // RIGHT FLANK: MAGI SUPERCOMPUTER & TACTICAL SENSORS (Extreme Right: x: 1540)
        // =========================================================================
        Column {
            visible: root.larp
            anchors.right: parent.right
            anchors.rightMargin: 20
            y: 44
            width: 360
            spacing: 8

            // ---------------------------------------------------------------------
            // CARD 1: 三位一体 審議システム // MAGI-01 Tripartite Cluster with Live Buses
            // ---------------------------------------------------------------------
            Rectangle {
                width: parent.width
                height: 290
                radius: 0
                color: Qt.rgba(0.06, 0.05, 0.04, 0.88)
                border { width: 1; color: root.isAlert ? Theme.red : Theme.accent }

                CornerReticles { reticleColor: root.isAlert ? Theme.red : Theme.hazard }

                Column {
                    anchors.fill: parent

                    // 1995 TV Show Solid Header Banner with Animated Hex Reactor GIF
                    Rectangle {
                        width: parent.width
                        height: 22
                        radius: 0
                        color: root.isAlert ? Theme.red : Theme.accent

                        Row {
                            anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
                            spacing: 6
                            AnimatedImage {
                                width: 14
                                height: 14
                                anchors.verticalCenter: parent.verticalCenter
                                source: Quickshell.shellPath("assets/gifs/opt/ja_fuel_bundle_hex_reactor_2x.gif")
                                fillMode: Image.PreserveAspectFit
                                playing: true
                            }
                            Text {
                                text: root.isAlert ? "■ MAGI-01 // 非常事態コード601発令" : "■ MAGI-01 TRICLUSTER // 三位一体 審議システム"
                                font { family: Theme.mono; pixelSize: 9; bold: true; letterSpacing: 0.8 }
                                color: "#08080A"
                            }
                        }
                    }

                    // Hazard Tape
                    HazardTape {
                        width: parent.width
                        stripeColor: root.isAlert ? Theme.red : Theme.accent
                    }

                    Column {
                        anchors { left: parent.left; right: parent.right; margins: 10 }
                        spacing: 4

                        // Giant Consensus Verdict Banner (TV Show Style)
                        Rectangle {
                            width: parent.width
                            height: 24
                            radius: 0
                            color: root.isAlert ? Theme.red : Theme.phosphor
                            Text {
                                anchors.centerIn: parent
                                text: root.isAlert ? "【 非 常 事 態 // EMERGENCY CODE: 601 】" : "【 全 会 一 致 // 3/3 CONSENSUS ACHIEVED 】"
                                font { family: Theme.eva; pixelSize: 10; bold: true; letterSpacing: 1.1 }
                                color: "#08080A"
                            }
                        }

                        // Blade 1: MELCHIOR-1 (Dr. Naoko Akagi — Scientist) with Live Amber PCB Bus GIF
                        Rectangle {
                            width: parent.width
                            height: 64
                            radius: 0
                            color: Theme.s2
                            border { width: 1; color: SysStats.cpu < 0.85 ? Theme.line : Theme.red }
                            clip: true

                            AnimatedImage {
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectCrop
                                source: Quickshell.shellPath("assets/gifs/opt/magi_amber_pcb_bus_2x.gif")
                                opacity: 0.22
                                playing: true
                            }

                            Row {
                                anchors { fill: parent; margins: 6 }
                                spacing: 8
                                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 4; height: parent.height - 4; color: Theme.phosphor }
                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 2
                                    width: 195
                                    Text { text: "MELCHIOR-1 // 科学者"; font { family: Theme.eva; pixelSize: 10; bold: true } color: Theme.hazard }
                                    Text { text: `CPU ${Math.round(SysStats.cpu * 100)}% · TEMP ${Math.round(SysStats.cpuTemp)}°C · CODE: 601`; font { family: Theme.mono; pixelSize: 8 } color: Theme.chalk }
                                }
                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 105
                                    height: 24
                                    color: SysStats.cpu < 0.85 ? Theme.phosphor : Theme.red
                                    Text {
                                        anchors.centerIn: parent
                                        text: SysStats.cpu < 0.85 ? "【 承 認 】" : "【 拒 絶 】"
                                        font { family: Theme.eva; pixelSize: 9; bold: true }
                                        color: "#08080A"
                                    }
                                }
                            }
                        }

                        // Blade 2: BALTHASAR-2 (Dr. Naoko Akagi — Mother) with Live Green Memory Bus GIF
                        Rectangle {
                            width: parent.width
                            height: 64
                            radius: 0
                            color: Theme.s2
                            border { width: 1; color: SysStats.mem < 0.90 ? Theme.line : Theme.red }
                            clip: true

                            AnimatedImage {
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectCrop
                                source: Quickshell.shellPath("assets/gifs/opt/magi_memory_bus_green_2x.gif")
                                opacity: 0.22
                                playing: true
                            }

                            Row {
                                anchors { fill: parent; margins: 6 }
                                spacing: 8
                                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 4; height: parent.height - 4; color: Theme.phosphor }
                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 2
                                    width: 195
                                    Text { text: "BALTHASAR-2 // 母"; font { family: Theme.eva; pixelSize: 10; bold: true } color: Theme.hazard }
                                    Text { text: `RAM ${SysStats.memUsed.toFixed(1)}GB · PWR ${bat.onBattery ? Math.round(bat.percentage*100)+"%" : "AC"}`; font { family: Theme.mono; pixelSize: 8 } color: Theme.chalk }
                                }
                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 105
                                    height: 24
                                    color: SysStats.mem < 0.90 ? Theme.phosphor : Theme.red
                                    Text {
                                        anchors.centerIn: parent
                                        text: SysStats.mem < 0.90 ? "【 保 護 】" : "【 危 機 】"
                                        font { family: Theme.eva; pixelSize: 9; bold: true }
                                        color: "#08080A"
                                    }
                                }
                            }
                        }

                        // Blade 3: CASPAR-3 (Dr. Naoko Akagi — Woman) with Live Reactor Animation
                        Rectangle {
                            width: parent.width
                            height: 64
                            radius: 0
                            color: Theme.s2
                            border { width: 1; color: Theme.line }
                            clip: true

                            AnimatedImage {
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectCrop
                                source: Quickshell.shellPath("assets/gifs/opt/ja_fuel_bundle_hex_reactor_2x.gif")
                                opacity: 0.18
                                playing: true
                            }

                            Row {
                                anchors { fill: parent; margins: 6 }
                                spacing: 8
                                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 4; height: parent.height - 4; color: Theme.phosphor }
                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 2
                                    width: 195
                                    Text { text: "CASPAR-3 // 女"; font { family: Theme.eva; pixelSize: 10; bold: true } color: Theme.hazard }
                                    Text { text: `NET ${SysStats.iface || "ETH0"} · ↑${Math.round(SysStats.tx/1024)}K ↓${Math.round(SysStats.rx/1024)}K`; font { family: Theme.mono; pixelSize: 8 } color: Theme.chalk }
                                }
                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 105
                                    height: 24
                                    color: Theme.phosphor
                                    Text {
                                        anchors.centerIn: parent
                                        text: "【 連 携 】"
                                        font { family: Theme.eva; pixelSize: 9; bold: true }
                                        color: "#08080A"
                                    }
                                }
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "審議完了: ３対０ // CODE: 601 // PRIORITY: AAA // FIREWALL: 100%"
                            font { family: Theme.mono; pixelSize: 7; bold: true }
                            color: Theme.chalk
                        }
                    }
                }
            }

            // ---------------------------------------------------------------------
            // CARD 2: 生体波形解析・音響観測 // Real Cava Audio Spectrum Station
            // ---------------------------------------------------------------------
            Rectangle {
                width: parent.width
                height: 165
                radius: 0
                color: Qt.rgba(0.06, 0.05, 0.04, 0.88)
                border { width: 1; color: Theme.accent }

                CornerReticles {}

                Column {
                    anchors.fill: parent

                    // 1995 TV Show Solid Header Banner
                    Rectangle {
                        width: parent.width
                        height: 22
                        radius: 0
                        color: Theme.accent

                        Row {
                            anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
                            spacing: 6
                            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 5; height: 5; color: "#08080A" }
                            Text {
                                text: "■ 生体波形解析 // ACOUSTIC OBSERVATION DATA"
                                font { family: Theme.mono; pixelSize: 9; bold: true; letterSpacing: 0.8 }
                                color: "#08080A"
                            }
                        }
                    }

                    // Hazard Tape
                    HazardTape {
                        width: parent.width
                        stripeColor: Theme.accent
                    }

                    Column {
                        anchors { left: parent.left; right: parent.right; margins: 10 }
                        spacing: 4

                        // 16 Real Cava Audio Columns
                        Rectangle {
                            width: parent.width
                            height: 65
                            radius: 0
                            color: Qt.rgba(0.03, 0.02, 0.02, 0.85)
                            border { width: 1; color: Theme.line }

                            Row {
                                anchors.centerIn: parent
                                spacing: 3
                                Repeater {
                                    model: 16
                                    Column {
                                        id: cCol
                                        required property int index
                                        readonly property real binPos: index * 7 / 15
                                        readonly property int b0: Math.floor(binPos)
                                        readonly property int b1: Math.min(7, b0 + 1)
                                        readonly property real frac: binPos - b0
                                        readonly property real rawVal: (Cava.bars[b0] ?? 0) * (1 - frac) + (Cava.bars[b1] ?? 0) * frac
                                        readonly property real ambientVal: Math.min(0.85, (SysStats.cores[index % Math.max(1, SysStats.cores.length)] ?? SysStats.cpu) * 0.7 + Math.sin(clock.date.getTime() / 350 + index * 0.45) * 0.12 + 0.10)
                                        readonly property real val: Media.playing ? Math.min(1.0, Math.max(0.0, rawVal)) : ambientVal
                                        spacing: 2

                                        Repeater {
                                            model: 9
                                            Rectangle {
                                                required property int index
                                                readonly property real thresh: (8 - index) / 9
                                                readonly property bool lit: cCol.val > thresh
                                                width: 16
                                                height: 4
                                                radius: 0
                                                color: lit ? (index < 2 ? Theme.hazard : index < 5 ? Theme.amber : Theme.phosphor) : Theme.s3
                                                opacity: lit ? 1.0 : 0.2
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Media Metadata
                        Text {
                            width: parent.width
                            elide: Text.ElideRight
                            text: root.player?.trackTitle || `Central Dogma Subterranean Resonance [${Math.round(SysStats.cpu * 100)}% CPU]`
                            font { family: Theme.mono; pixelSize: 10; bold: true }
                            color: Theme.chalk
                        }
                        Text {
                            width: parent.width
                            elide: Text.ElideRight
                            text: root.player?.trackArtist ? `${root.player.trackArtist} — ${root.player.identity}` : `MAGI Acoustic Synthesizer // RX ${Math.round(SysStats.rx/1024)}K TX ${Math.round(SysStats.tx/1024)}K`
                            font { family: Theme.mono; pixelSize: 8 }
                            color: Theme.mute
                        }

                        Seg {
                            width: parent.width
                            height: 4
                            n: 20
                            f: root.player?.lengthSupported && root.player.length > 0 ? Media.position / root.player.length : 0
                            on: Theme.amber
                            off: Theme.s3
                        }
                    }
                }
            }

            // ---------------------------------------------------------------------
            // CARD 3: 思考形態同期 // EVA-01 Synchronicity & Cage Telemetry
            // ---------------------------------------------------------------------
            Rectangle {
                width: parent.width
                height: 175
                radius: 0
                color: Qt.rgba(0.06, 0.05, 0.04, 0.88)
                border { width: 1; color: Theme.accent }

                CornerReticles {}

                Column {
                    anchors.fill: parent

                    // 1995 TV Show Solid Header Banner
                    Rectangle {
                        width: parent.width
                        height: 22
                        radius: 0
                        color: Theme.accent

                        Row {
                            anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
                            spacing: 6
                            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 5; height: 5; color: "#08080A" }
                            Text {
                                text: "■ 思考形態同期 // EVA-01 HARMONIC TELEMETRY"
                                font { family: Theme.mono; pixelSize: 9; bold: true; letterSpacing: 0.8 }
                                color: "#08080A"
                            }
                        }
                    }

                    // Hazard Tape
                    HazardTape {
                        width: parent.width
                        stripeColor: Theme.accent
                    }

                    Column {
                        anchors { left: parent.left; right: parent.right; margins: 10 }
                        spacing: 4

                        // Dual CRT Telemetry Displays
                        Row {
                            width: parent.width
                            height: 80
                            spacing: 6

                            // Left: EVA-01 Cage Silhouette
                            Rectangle {
                                width: (parent.width - 6) / 2
                                height: parent.height
                                color: Theme.s2
                                border { width: 1; color: Theme.line }
                                clip: true
                                AnimatedImage {
                                    anchors.fill: parent
                                    fillMode: Image.PreserveAspectCrop
                                    source: Quickshell.shellPath("assets/gifs/opt/eva01_cage_telemetry_2x.gif")
                                    playing: true
                                    opacity: 0.85
                                }
                            }

                            // Right: Synch Waveform Oscilloscope Curves
                            Rectangle {
                                width: (parent.width - 6) / 2
                                height: parent.height
                                color: Theme.s2
                                border { width: 1; color: Theme.line }
                                clip: true
                                AnimatedImage {
                                    anchors.fill: parent
                                    fillMode: Image.PreserveAspectCrop
                                    source: Quickshell.shellPath("assets/gifs/opt/synch_harmonics_oscilloscope_2x.gif")
                                    playing: true
                                    opacity: 0.85
                                }
                            }
                        }

                        Text {
                            text: `同期率: ${(root.synchRatio * 100).toFixed(2)}% [OPTIMAL] // 正常同期`
                            font { family: Theme.eva; pixelSize: 10; bold: true }
                            color: Theme.amber
                        }

                        Seg {
                            width: parent.width
                            height: 4
                            n: 22
                            f: root.synchRatio
                            on: Theme.phosphor
                            off: Theme.s3
                        }
                    }
                }
            }

            // ---------------------------------------------------------------------
            // CARD 4: 神経接続波形 // 3D Topological Synch Waveforms
            // ---------------------------------------------------------------------
            Rectangle {
                width: parent.width
                height: 195
                radius: 0
                color: Qt.rgba(0.06, 0.05, 0.04, 0.88)
                border { width: 1; color: Theme.accent }

                CornerReticles {}

                Column {
                    anchors.fill: parent

                    // 1995 TV Show Solid Header Banner
                    Rectangle {
                        width: parent.width
                        height: 22
                        radius: 0
                        color: Theme.accent

                        Row {
                            anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
                            spacing: 6
                            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 5; height: 5; color: "#08080A" }
                            Text {
                                text: "■ 神経接続波形 // 3D TOPOLOGICAL SYNCH WAVEFORMS"
                                font { family: Theme.mono; pixelSize: 9; bold: true; letterSpacing: 0.8 }
                                color: "#08080A"
                            }
                        }
                    }

                    // Hazard Tape
                    HazardTape {
                        width: parent.width
                        stripeColor: Theme.accent
                    }

                    Column {
                        anchors { left: parent.left; right: parent.right; margins: 10 }
                        spacing: 4

                        // CRT Display: 3D Topological Synch Waveforms GIF
                        Rectangle {
                            width: parent.width
                            height: 95
                            color: Theme.s2
                            border { width: 1; color: Theme.line }
                            clip: true

                            AnimatedImage {
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectCrop
                                source: Quickshell.shellPath("assets/gifs/opt/topological_synch_waveforms_2x.gif")
                                playing: true
                                opacity: 0.88
                            }
                        }

                        Row {
                            spacing: 6
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                height: 16
                                width: 120
                                color: Theme.phosphor
                                Text {
                                    anchors.centerIn: parent
                                    text: "【 A-10神経: 安定 】"
                                    font { family: Theme.eva; pixelSize: 8; bold: true }
                                    color: "#08080A"
                                }
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "インパルス伝播遅延: 0.0012 ms"
                                font { family: Theme.mono; pixelSize: 8; bold: true }
                                color: Theme.chalk
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "精神汚染境界線: 正常域 (NOMINAL) // 自我境界: 安定保持"
                            font { family: Theme.mono; pixelSize: 7; bold: true }
                            color: Theme.mute
                        }
                    }
                }
            }

            // ---------------------------------------------------------------------
            // CARD 5: 兵装管制 // Tactical Ordnance & Weapons Rack Status
            // ---------------------------------------------------------------------
            Rectangle {
                width: parent.width
                height: 155
                radius: 0
                color: Qt.rgba(0.06, 0.05, 0.04, 0.88)
                border { width: 1; color: Theme.accent }

                CornerReticles {}

                Column {
                    anchors.fill: parent

                    // 1995 TV Show Solid Header Banner
                    Rectangle {
                        width: parent.width
                        height: 22
                        radius: 0
                        color: Theme.accent

                        Row {
                            anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
                            spacing: 6
                            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 5; height: 5; color: "#08080A" }
                            Text {
                                text: "■ 兵装管制 // TACTICAL ORDNANCE & WEAPONS RACK"
                                font { family: Theme.mono; pixelSize: 9; bold: true; letterSpacing: 0.8 }
                                color: "#08080A"
                            }
                        }
                    }

                    // Hazard Tape
                    HazardTape {
                        width: parent.width
                        stripeColor: Theme.accent
                    }

                    Column {
                        anchors { left: parent.left; right: parent.right; margins: 10 }
                        spacing: 4

                        Row {
                            spacing: 6
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                height: 16
                                width: 130
                                color: Theme.phosphor
                                Text {
                                    anchors.centerIn: parent
                                    text: "【 迎撃準備完了 // READY 】"
                                    font { family: Theme.eva; pixelSize: 8; bold: true }
                                    color: "#08080A"
                                }
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "ARMAMENT: PALLET & PROG"
                                font { family: Theme.mono; pixelSize: 8; bold: true }
                                color: Theme.chalk
                            }
                        }

                        // Weapons Table
                        Column {
                            width: parent.width
                            spacing: 2
                            Row {
                                spacing: 8
                                Text { text: "PK-01 PROG KNIFE:"; font { family: Theme.mono; pixelSize: 8; bold: true } color: Theme.amber }
                                Text { text: "LOCKED [L-SHOULDER RACK]"; font { family: Theme.mono; pixelSize: 8 } color: Theme.chalk }
                            }
                            Row {
                                spacing: 8
                                Text { text: "PR-55 PALLET RIFLE:"; font { family: Theme.mono; pixelSize: 8; bold: true } color: Theme.amber }
                                Text { text: `STANDBY [AMMO: ${Math.round((1 - SysStats.mem) * 120)}/120]`; font { family: Theme.mono; pixelSize: 8 } color: Theme.chalk }
                            }
                            Row {
                                spacing: 8
                                Text { text: "POSITRON RIFLE:"; font { family: Theme.mono; pixelSize: 8; bold: true } color: Theme.amber }
                                Text { text: !bat.onBattery ? "CHARGED 100% [AC LOCK]" : `CHARGING ${Math.round(bat.percentage * 100)}% // STANDBY`; font { family: Theme.mono; pixelSize: 8 } color: Theme.phosphor }
                            }
                        }

                        Seg {
                            width: parent.width
                            height: 4
                            n: 20
                            f: bat.percentage
                            on: Theme.phosphor
                            off: Theme.s3
                        }
                    }
                }
            }
        }
    }
}

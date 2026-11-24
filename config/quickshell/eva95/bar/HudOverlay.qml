import QtQuick
import Quickshell
import Quickshell.Wayland
import qs

// =============================================================================
// EVA-95 CENTRAL DOGMA TACTICAL HUD SCREEN FRAMING & TELECINE MASTER OVERLAY
// =============================================================================
// Faithful 1995 Neon Genesis Evangelion Hideaki Anno / Gainax Telecine Aesthetic:
// - Optical coordinate rulers along X and Y axes framing the central viewport
// - 24fps SMPTE production timecode counter with blinking REC tally
// - Subterranean Geofront atmospheric readouts (Barometric pressure, temperature, micro-seismic activity)
// - Tactical target acquisition envelope with azimuth, elevation, and Doppler telemetry
// - Bottom teletype status marquee for Central Dogma bulkheads & MAGI state
// - Sits EXCLUSIVELY in the central 1160px viewport (between x: 380 and 1540), completely avoiding
//   any overlap with the Left and Right Flank operational consoles.
// - 100% click-through (mask: Region {}) so desktop clicks are never intercepted
PanelWindow {
    id: root

    anchors { left: true; right: true; top: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "eva95-hud"

    // Empty input mask: guarantees 100% click-through for desktop clicks and interactions
    mask: Region {}

    readonly property color hudColor: Theme.isLightWall ? Qt.rgba(0.05, 0.05, 0.08, 0.9) : Qt.rgba(1.0, 0.55, 0.0, 0.85)
    readonly property color hudSubColor: Theme.isLightWall ? Qt.rgba(0.05, 0.05, 0.08, 0.75) : Qt.rgba(1.0, 0.55, 0.0, 0.65)
    readonly property color hexColor: Theme.isLightWall ? Qt.rgba(0.05, 0.05, 0.08, 0.35) : Qt.rgba(1.0, 0.55, 0.0, 0.30)
    readonly property color ringColor: Theme.isLightWall ? Qt.rgba(0.05, 0.05, 0.08, 0.25) : Qt.rgba(1.0, 0.55, 0.0, 0.20)
    readonly property bool larp: Theme.state.larp ?? true

    SystemClock { id: clock; precision: SystemClock.Seconds }

    // Live 24fps Production Film / Broadcast Frame Counter (00..23)
    property int frame: 0
    Timer {
        interval: 41
        running: true
        repeat: true
        onTriggered: root.frame = (root.frame + 1) % 24
    }

    Item {
        anchors.fill: parent
        visible: root.larp

        // Corner Targeting Reticles
        component Reticle: Item {
            property bool flipX: false
            property bool flipY: false
            width: 36
            height: 36

            // Horizontal crossline
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                x: flipX ? parent.width - width : 0
                width: 24
                height: 1
                color: Theme.amber
            }
            // Vertical crossline
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                y: flipY ? parent.height - height : 0
                width: 1
                height: 24
                color: Theme.amber
            }
            // Corner angle bracket
            Rectangle {
                x: flipX ? parent.width - width : 0
                y: flipY ? parent.height - height : 0
                width: 8
                height: 8
                color: "transparent"
                border {
                    width: 1
                    color: Theme.hazard
                }
            }
            // Center point
            Rectangle {
                anchors.centerIn: parent
                width: 3
                height: 3
                color: Theme.hazard
            }
        }

        // =====================================================================
        // CENTRAL VIEWPORT TELECINE FRAMING (Cleanly bounded inside x: 385..1535)
        // =====================================================================

        // Top Left of Central Viewport: Reticle & 24fps Telecine Recording Timecode
        Reticle { x: 386; y: 46 }
        Row {
            x: 426
            y: 50
            spacing: 8

            // Flashing REC indicator
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 7
                height: 7
                radius: 4
                color: Theme.red
                SequentialAnimation on opacity {
                    running: true
                    loops: Animation.Infinite
                    NumberAnimation { from: 1.0; to: 0.15; duration: 500 }
                    NumberAnimation { from: 0.15; to: 1.0; duration: 500 }
                }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: `REC ● [${Qt.formatTime(clock.date, "hh:mm:ss")}:${root.frame < 10 ? "0" : ""}${root.frame}]`
                font { family: Theme.mono; pixelSize: 9; bold: true }
                color: Theme.red
            }
            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 1; height: 10; color: Theme.s3 }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "CAM-01 [CENTRAL DOGMA] // NTSC-J"
                font { family: Theme.mono; pixelSize: 8; bold: true; letterSpacing: 0.8 }
                color: root.hudColor
            }
        }

        // Top Right of Central Viewport: Remaster Digital Master Marker & Reticle
        Reticle { x: 1534 - 36; y: 46; flipX: true }
        Row {
            anchors.right: parent.right
            anchors.rightMargin: 395
            y: 50
            spacing: 8
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "DIGITAL REMASTER // 1080p TELECINE // MAGI-01"
                font { family: Theme.mono; pixelSize: 8; bold: true; letterSpacing: 0.8 }
                color: root.hudColor
            }
            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 4; height: 8; color: Theme.hazard }
        }

        // Bottom Left of Central Viewport: Reticle & Telemetry Coordinates
        Reticle { x: 386; anchors.bottom: parent.bottom; anchors.bottomMargin: 32; flipY: true }
        Row {
            x: 426
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 36
            spacing: 6
            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 4; height: 8; color: Theme.amber }
            Text {
                text: "POS: 35°14'45\"N 139°01'22\"E // GEOFRONT TOKYO-3 // B322F"
                font { family: Theme.mono; pixelSize: 8; bold: true; letterSpacing: 0.8 }
                color: root.hudSubColor
            }
        }

        // Bottom Right of Central Viewport: Reticle & MAGI Tri-Cluster State
        Reticle { x: 1534 - 36; anchors.bottom: parent.bottom; anchors.bottomMargin: 32; flipX: true; flipY: true }
        Row {
            anchors.right: parent.right
            anchors.rightMargin: 395
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 36
            spacing: 6
            Text {
                text: "SYNC: 89.89% // AT-FIELD: DEPLOYED // MAGI BUS: NOMINAL"
                font { family: Theme.mono; pixelSize: 8; bold: true; letterSpacing: 0.8 }
                color: root.hudSubColor
            }
            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 4; height: 8; color: Theme.phosphor }
        }

        // =====================================================================
        // VIEWPORT OPTICAL COORDINATE RULERS (Y-AXIS RULERS FRAMING VIEWPORT)
        // =====================================================================
        // Left Flank Inner Boundary Ruler (x: 385, bracketing Left Flank)
        Item {
            x: 385
            y: 50
            width: 30
            height: parent.height - 100

            // Continuous vertical datum hairline
            Rectangle {
                x: 0
                y: 0
                width: 1
                height: parent.height
                color: root.hexColor
            }

            // Ticks and labels every 100 pixels
            Repeater {
                model: 11
                Item {
                    required property int index
                    x: 0
                    y: index * 100
                    width: 30
                    height: 12

                    // Major horizontal tick
                    Rectangle {
                        x: 0
                        y: 0
                        width: 6
                        height: 1
                        color: Theme.hazard
                    }
                    // Minor horizontal tick at +50px
                    Rectangle {
                        x: 0
                        y: 50
                        width: 3
                        height: 1
                        color: root.hexColor
                    }
                    Text {
                        x: 8
                        y: -5
                        text: `+${String(index * 100).padStart(4, "0")}`
                        font { family: Theme.mono; pixelSize: 8 }
                        color: root.hexColor
                    }
                }
            }
        }

        // Right Flank Inner Boundary Ruler (x: 1535, bracketing Right Flank)
        Item {
            x: 1535
            y: 50
            width: 30
            height: parent.height - 100

            // Continuous vertical datum hairline
            Rectangle {
                x: 0
                y: 0
                width: 1
                height: parent.height
                color: root.hexColor
            }

            // Ticks and labels every 100 pixels
            Repeater {
                model: 11
                Item {
                    required property int index
                    x: -24
                    y: index * 100
                    width: 30
                    height: 12

                    // Major horizontal tick
                    Rectangle {
                        x: 24
                        y: 0
                        width: 6
                        height: 1
                        color: Theme.hazard
                    }
                    // Minor horizontal tick at +50px
                    Rectangle {
                        x: 24
                        y: 50
                        width: 3
                        height: 1
                        color: root.hexColor
                    }
                    Text {
                        x: -10
                        y: -5
                        text: `-${String(index * 100).padStart(4, "0")}`
                        font { family: Theme.mono; pixelSize: 8 }
                        color: root.hexColor
                    }
                }
            }
        }

        // =====================================================================
        // VIEWPORT OPTICAL COORDINATE RULERS (X-AXIS RULERS TOP & BOTTOM)
        // =====================================================================
        // Top Horizontal Coordinate Line (y: 44, between x: 390 and 1530)
        Item {
            x: 390
            y: 44
            width: 1140
            height: 16

            Rectangle {
                anchors.top: parent.top
                width: parent.width
                height: 1
                color: root.hexColor
            }

            Repeater {
                model: [400, 500, 600, 700, 800, 900, 1000, 1100, 1200, 1300, 1400, 1500]
                Item {
                    required property int modelData
                    x: (modelData - 400) * (1140 / 1100)
                    y: 0
                    Rectangle { width: 1; height: 4; color: Theme.hazard }
                    Text {
                        x: -12
                        y: 5
                        text: String(modelData)
                        font { family: Theme.mono; pixelSize: 7 }
                        color: root.hexColor
                    }
                }
            }
        }

        // =====================================================================
        // SUBTERRANEAN GEOFRONT SENSOR PILL (TOP CENTER: y: 48)
        // =====================================================================
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 48
            width: geoRow.width + 16
            height: 18
            radius: 0
            color: Qt.rgba(0.06, 0.05, 0.04, 0.82)
            border { width: 1; color: Qt.rgba(1.0, 0.55, 0.0, 0.4) }

            Row {
                id: geoRow
                anchors.centerIn: parent
                spacing: 10

                Row {
                    spacing: 4
                    Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 4; height: 4; color: Theme.phosphor }
                    Text { text: "ジオフロント 気圧: 1013.25 hPa"; font { family: Theme.mono; pixelSize: 8; bold: true } color: Theme.chalk }
                }
                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 1; height: 10; color: Theme.s3 }
                Row {
                    spacing: 4
                    Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 4; height: 4; color: Theme.hazard }
                    Text { text: "地下気温: 19.8°C"; font { family: Theme.mono; pixelSize: 8; bold: true } color: Theme.chalk }
                }
                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 1; height: 10; color: Theme.s3 }
                Row {
                    spacing: 4
                    Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 4; height: 4; color: Theme.phosphor }
                    Text { text: "地殻変動率: 0.002 gal"; font { family: Theme.mono; pixelSize: 8; bold: true } color: Theme.chalk }
                }
                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 1; height: 10; color: Theme.s3 }
                Row {
                    spacing: 4
                    Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 4; height: 4; color: Theme.cyan }
                    Text { text: "LCL純度: 99.98%"; font { family: Theme.mono; pixelSize: 8; bold: true } color: Theme.chalk }
                }
                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 1; height: 10; color: Theme.s3 }
                Row {
                    spacing: 4
                    Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 4; height: 4; color: Theme.phosphor }
                    Text { text: "MAGI-01: 正常稼働"; font { family: Theme.mono; pixelSize: 8; bold: true } color: Theme.phosphor }
                }
            }
        }

        // =====================================================================
        // AUTHENTIC EVANGELION AT-FIELD (ABSOLUTE TERROR FIELD) - TRANSPARENT
        // =====================================================================
        Item {
            id: atField
            visible: root.larp
            anchors.centerIn: parent
            width: 480
            height: 480

            // Target Acquisition Envelope Callout (Above AT-Field)
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                y: -36
                text: "【 目標識別: 使徒 (PATTERNS: BLOOD-TYPE BLUE) // CODE: 601 】"
                font { family: Theme.eva; pixelSize: 10; bold: true; letterSpacing: 1.1 }
                color: Theme.amber
            }

            // Radiating Phase Wave 1
            Image {
                anchors.centerIn: parent
                width: 460
                height: 460
                sourceSize: Qt.size(width, height)
                source: Qt.resolvedUrl("atfield_pulse.svg")
                NumberAnimation on scale {
                    running: root.larp
                    from: 0.6
                    to: 1.45
                    duration: 2200
                    loops: Animation.Infinite
                }
                NumberAnimation on opacity {
                    running: root.larp
                    from: 0.85
                    to: 0.0
                    duration: 2200
                    loops: Animation.Infinite
                }
            }

            // Radiating Phase Wave 2 (offset)
            Image {
                anchors.centerIn: parent
                width: 460
                height: 460
                sourceSize: Qt.size(width, height)
                source: Qt.resolvedUrl("atfield_pulse.svg")
                SequentialAnimation {
                    running: root.larp
                    loops: Animation.Infinite
                    PauseAnimation { duration: 1100 }
                    ParallelAnimation {
                        NumberAnimation { property: "scale"; from: 0.6; to: 1.45; duration: 2200 }
                        NumberAnimation { property: "opacity"; from: 0.85; to: 0.0; duration: 2200 }
                    }
                }
            }

            // Core Concentric Octagons (Clean vector wireframe, fill="none")
            Image {
                anchors.centerIn: parent
                width: 360
                height: 360
                sourceSize: Qt.size(width, height)
                source: Qt.resolvedUrl("atfield.svg")
                opacity: 0.85
                SequentialAnimation on scale {
                    running: root.larp
                    loops: Animation.Infinite
                    NumberAnimation { from: 0.96; to: 1.04; duration: 1400; easing.type: Easing.InOutQuad }
                    NumberAnimation { from: 1.04; to: 0.96; duration: 1400; easing.type: Easing.InOutQuad }
                }
            }
            Image {
                anchors.centerIn: parent
                width: 250
                height: 250
                sourceSize: Qt.size(width, height)
                source: Qt.resolvedUrl("atfield.svg")
                opacity: 0.95
                SequentialAnimation on scale {
                    running: root.larp
                    loops: Animation.Infinite
                    NumberAnimation { from: 1.03; to: 0.97; duration: 1100; easing.type: Easing.InOutQuad }
                    NumberAnimation { from: 0.97; to: 1.03; duration: 1100; easing.type: Easing.InOutQuad }
                }
            }

            // Target Telemetry Callout (Below AT-Field)
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                y: parent.height + 22
                text: "AZIMUTH: 184.22° // ELEVATION: -14.05° // RANGE: 0420m // DOPPLER: +0.02c"
                font { family: Theme.mono; pixelSize: 9; bold: true; letterSpacing: 1.2 }
                color: Theme.hazard
            }
        }

        // Center Target Lock Ring & Delicate Radar Sweep
        Item {
            anchors.centerIn: parent
            width: 360
            height: 360

            // Sweeping Radar Beam (Low opacity 0.35 so Lilith remains pristine)
            Item {
                visible: root.larp
                anchors.centerIn: parent
                width: parent.width
                height: parent.height
                Rectangle {
                    x: parent.width / 2
                    y: parent.height / 2
                    width: parent.width / 2
                    height: 1.5
                    color: Theme.hazard
                    opacity: 0.35
                    transformOrigin: Item.TopLeft
                    RotationAnimation on rotation {
                        running: root.larp
                        loops: Animation.Infinite
                        from: 0
                        to: 360
                        duration: 6000
                    }
                }
            }

            // Radar Ring Outer Ticks
            Rectangle {
                anchors.centerIn: parent
                width: parent.width
                height: parent.height
                radius: width / 2
                color: "transparent"
                border {
                    width: 1
                    color: root.ringColor
                }
            }

            // Rangefinder crosshair lines
            Rectangle {
                anchors.centerIn: parent
                width: parent.width + 40
                height: 1
                color: root.ringColor
            }
            Rectangle {
                anchors.centerIn: parent
                width: 1
                height: parent.height + 40
                color: root.ringColor
            }
        }

        // =====================================================================
        // BOTTOM TELETYPE TACTICAL MARQUEE BAR (y: parent.height - 18)
        // =====================================================================
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 10
            width: 1140
            height: 18
            radius: 0
            color: Qt.rgba(0.06, 0.05, 0.04, 0.85)
            border { width: 1; color: Qt.rgba(1.0, 0.55, 0.0, 0.4) }

            Row {
                anchors.centerIn: parent
                spacing: 8

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 5
                    height: 5
                    color: Theme.hazard
                    SequentialAnimation on opacity {
                        running: true
                        loops: Animation.Infinite
                        NumberAnimation { from: 1.0; to: 0.2; duration: 400 }
                        NumberAnimation { from: 0.2; to: 1.0; duration: 400 }
                    }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "NERV HQ TOKYO-3 // B322F CENTRAL DOGMA // DEFENSE BULKHEADS NO.01-NO.24: LOCKED // MAGI-01 NOMINAL // AT-FIELD ACTIVE // \"GOD'S IN HIS HEAVEN, ALL'S RIGHT WITH THE WORLD.\""
                    font { family: Theme.mono; pixelSize: 8; bold: true; letterSpacing: 1.1 }
                    color: Theme.chalk
                }
            }
        }
    }
}

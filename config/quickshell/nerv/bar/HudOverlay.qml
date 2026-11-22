import QtQuick
import Quickshell
import Quickshell.Wayland
import qs

// NERV Tactical HUD Screen Framing & Corner Reticles:
// Renders authentic Evangelion targeting crosses, coordinate axes, and classification tape on desktop layer
PanelWindow {
    id: root

    anchors { left: true; right: true; top: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "nerv-hud"

    // Empty input mask: guarantees 100% click-through for desktop clicks and interactions
    mask: Region {}

    readonly property color hudColor: Theme.isLightWall ? Qt.rgba(0.05, 0.05, 0.08, 0.9) : Qt.rgba(0.9, 0.11, 0.14, 0.75)
    readonly property color hudSubColor: Theme.isLightWall ? Qt.rgba(0.05, 0.05, 0.08, 0.75) : Qt.rgba(0.9, 0.11, 0.14, 0.65)
    readonly property color hexColor: Theme.isLightWall ? Qt.rgba(0.05, 0.05, 0.08, 0.35) : Qt.rgba(0.9, 0.11, 0.14, 0.25)
    readonly property color ringColor: Theme.isLightWall ? Qt.rgba(0.05, 0.05, 0.08, 0.25) : Qt.rgba(0.9, 0.11, 0.14, 0.18)
    readonly property bool larp: Theme.state.larp ?? false

    Item {
        anchors.fill: parent

        // Corner Targeting Reticles
        component Reticle: Item {
            property bool flipX: false
            property bool flipY: false
            width: 48
            height: 48

            // Horizontal crossline
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                x: flipX ? parent.width - width : 0
                width: 32
                height: 1
                color: Theme.crimson
            }
            // Vertical crossline
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                y: flipY ? parent.height - height : 0
                width: 1
                height: 32
                color: Theme.crimson
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

        // Top Left Reticle & Tactical Identification
        Reticle { x: 12; y: 46 }
        Row {
            x: 52
            y: 52
            spacing: 8
            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 4; height: 10; color: Theme.crimson }
            Text {
                text: "NERV TACTICAL HUD // TERMINAL HAL-16X // DISP 01"
                font.family: Theme.mono
                font.pixelSize: 9
                font.bold: true
                color: root.hudColor
                font.letterSpacing: 1.2
            }
        }

        // Top Right Reticle & Security Classification
        Reticle { anchors.right: parent.right; anchors.rightMargin: 12; y: 46; flipX: true }
        Row {
            anchors.right: parent.right
            anchors.rightMargin: 52
            y: 52
            spacing: 8
            Text {
                text: "RESTRICTED ACCESS // LEVEL-A CLEARANCE // MAGI OVERRIDE 666"
                font.family: Theme.mono
                font.pixelSize: 9
                font.bold: true
                color: root.hudColor
                font.letterSpacing: 1.2
            }
            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 4; height: 10; color: Theme.hazard }
        }

        // Bottom Left Reticle & Telemetry Coordinates
        Reticle { x: 12; anchors.bottom: parent.bottom; anchors.bottomMargin: 12; flipY: true }
        Row {
            x: 52
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 16
            spacing: 8
            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 4; height: 10; color: Theme.crimson }
            Text {
                text: "POS: 35°14'45\"N 139°01'22\"E // GEOFRONT TOKYO-3 // B22F CENTRAL DOGMA"
                font.family: Theme.mono
                font.pixelSize: 9
                font.bold: true
                color: root.hudSubColor
                font.letterSpacing: 1.2
            }
        }

        // Bottom Right Reticle & MAGI Tri-Cluster State
        Reticle { anchors.right: parent.right; anchors.rightMargin: 12; anchors.bottom: parent.bottom; anchors.bottomMargin: 12; flipX: true; flipY: true }
        Row {
            anchors.right: parent.right
            anchors.rightMargin: 52
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 16
            spacing: 8
            Text {
                text: "SYNC RATIO: 99.8% // AT-FIELD: DEPLOYED // MAGI BUS: NOMINAL"
                font.family: Theme.mono
                font.pixelSize: 9
                font.bold: true
                color: root.hudSubColor
                font.letterSpacing: 1.2
            }
            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 4; height: 10; color: Theme.crimson }
        }

        // Left Edge Hexadecimal Memory Offsets
        Column {
            x: 14
            anchors.verticalCenter: parent.verticalCenter
            spacing: 24
            Repeater {
                model: ["0x7FFF00", "0x7FFF20", "0x7FFF40", "0x7FFF60", "0x7FFF80", "0x7FFFA0", "0x7FFFC0"]
                Text {
                    required property string modelData
                    text: modelData
                    font.family: Theme.mono
                    font.pixelSize: 8
                    color: root.hexColor
                }
            }
        }

        // Right Edge Hexadecimal Memory Offsets
        Column {
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            spacing: 24
            Repeater {
                model: ["0x8FFF00", "0x8FFF20", "0x8FFF40", "0x8FFF60", "0x8FFF80", "0x8FFFA0", "0x8FFFC0"]
                Text {
                    required property string modelData
                    text: modelData
                    font.family: Theme.mono
                    font.pixelSize: 8
                    color: root.hexColor
                }
            }
        }

        // LARP Combat Status Banner
        Rectangle {
            visible: root.larp
            anchors.horizontalCenter: parent.horizontalCenter
            y: 48
            width: 460
            height: 22
            radius: 0
            color: Theme.accent
            border { width: 1; color: Theme.hazard }
            Row {
                anchors.centerIn: parent
                spacing: 8
                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 6; height: 6; color: "#FFFFFF" }
                Text {
                    text: "EMERGENCY // ANGEL DETECTED: CODE BLUE // OVERRIDE ACTIVE"
                    font.family: Theme.mono
                    font.pixelSize: 9
                    font.bold: true
                    font.letterSpacing: 1.2
                    color: "#FFFFFF"
                }
                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 6; height: 6; color: "#FFFFFF" }
            }
            SequentialAnimation on opacity {
                running: root.larp
                loops: Animation.Infinite
                NumberAnimation { from: 1.0; to: 0.25; duration: 500 }
                NumberAnimation { from: 0.25; to: 1.0; duration: 500 }
            }
        }

        // LARP: Authentic Evangelion AT-Field (Absolute Terror Field)
        Item {
            id: atField
            visible: root.larp
            anchors.centerIn: parent
            width: 500
            height: 500

            // Radiating Phase Wave 1
            Image {
                anchors.centerIn: parent
                width: 480
                height: 480
                sourceSize: Qt.size(width, height)
                source: Qt.resolvedUrl("atfield_pulse.svg")
                NumberAnimation on scale {
                    running: root.larp
                    from: 0.6
                    to: 1.5
                    duration: 2200
                    loops: Animation.Infinite
                }
                NumberAnimation on opacity {
                    running: root.larp
                    from: 0.9
                    to: 0.0
                    duration: 2200
                    loops: Animation.Infinite
                }
            }

            // Radiating Phase Wave 2 (offset)
            Image {
                anchors.centerIn: parent
                width: 480
                height: 480
                sourceSize: Qt.size(width, height)
                source: Qt.resolvedUrl("atfield_pulse.svg")
                SequentialAnimation {
                    running: root.larp
                    loops: Animation.Infinite
                    PauseAnimation { duration: 1100 }
                    ParallelAnimation {
                        NumberAnimation { property: "scale"; from: 0.6; to: 1.5; duration: 2200 }
                        NumberAnimation { property: "opacity"; from: 0.9; to: 0.0; duration: 2200 }
                    }
                }
            }

            // Core Concentric Octagons
            Image {
                anchors.centerIn: parent
                width: 380
                height: 380
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
                width: 260
                height: 260
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

            // Center Phase Status Label
            Rectangle {
                anchors.centerIn: parent
                width: 260
                height: 20
                radius: 0
                color: Qt.rgba(0.05, 0.05, 0.08, 0.85)
                border { width: 1; color: Theme.hazard }
                Text {
                    anchors.centerIn: parent
                    text: "AT-FIELD // PHASE: 432.8 THz [ACTIVE]"
                    font { family: Theme.mono; pixelSize: 9; bold: true; letterSpacing: 1.1 }
                    color: Theme.hazard
                }
            }
        }

        // Center Target Lock Ring Framing
        Item {
            anchors.centerIn: parent
            width: 380
            height: 380

            // LARP: Sweeping Radar Beam
            Item {
                visible: root.larp
                anchors.centerIn: parent
                width: parent.width
                height: parent.height
                Rectangle {
                    x: parent.width / 2
                    y: parent.height / 2
                    width: parent.width / 2
                    height: 2
                    color: Theme.hazard
                    opacity: 0.7
                }
                RotationAnimation on rotation {
                    running: root.larp
                    from: 0
                    to: 360
                    duration: 3500
                    loops: Animation.Infinite
                }
            }

            // LARP: Inner Counter-Rotating Reticle Ring
            Item {
                visible: root.larp
                anchors.centerIn: parent
                width: 240
                height: 240
                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: "transparent"
                    border { width: 1; color: Theme.hazard }
                    opacity: 0.4
                }
                // 4 inner reticle ticks
                Rectangle { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; width: 14; height: 2; color: Theme.hazard }
                Rectangle { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; width: 14; height: 2; color: Theme.hazard }
                Rectangle { anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter; width: 2; height: 14; color: Theme.hazard }
                Rectangle { anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter; width: 2; height: 14; color: Theme.hazard }

                RotationAnimation on rotation {
                    running: root.larp
                    from: 360
                    to: 0
                    duration: 20000
                    loops: Animation.Infinite
                }
            }

            // Main Rotating reticle ring
            Item {
                anchors.fill: parent
                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: "transparent"
                    border { width: 1; color: root.ringColor }
                }

                // Range and azimuth stamping
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: -18
                    text: "TARGET ACQUISITION // RNG: 0420m // AZM: 184.2°"
                    font.family: Theme.mono
                    font.pixelSize: 9
                    font.bold: true
                    color: root.hudSubColor
                    font.letterSpacing: 1.2
                }

                // Target cross tick lines
                Rectangle { anchors.left: parent.left; anchors.leftMargin: -12; anchors.verticalCenter: parent.verticalCenter; width: 24; height: 1; color: root.hudSubColor }
                Rectangle { anchors.right: parent.right; anchors.rightMargin: -12; anchors.verticalCenter: parent.verticalCenter; width: 24; height: 1; color: root.hudSubColor }
                Rectangle { anchors.top: parent.top; anchors.topMargin: -12; anchors.horizontalCenter: parent.horizontalCenter; width: 1; height: 24; color: root.hudSubColor }
                Rectangle { anchors.bottom: parent.bottom; anchors.bottomMargin: -12; anchors.horizontalCenter: parent.horizontalCenter; width: 1; height: 24; color: root.hudSubColor }

                // Outer 4 corner brackets
                Rectangle { x: 40; y: 40; width: 16; height: 1; color: root.hudSubColor }
                Rectangle { x: 40; y: 40; width: 1; height: 16; color: root.hudSubColor }
                Rectangle { anchors.right: parent.right; anchors.rightMargin: 40; y: 40; width: 16; height: 1; color: root.hudSubColor }
                Rectangle { anchors.right: parent.right; anchors.rightMargin: 40; y: 40; width: 1; height: 16; color: root.hudSubColor }
                Rectangle { x: 40; anchors.bottom: parent.bottom; anchors.bottomMargin: 40; width: 16; height: 1; color: root.hudSubColor }
                Rectangle { x: 40; anchors.bottom: parent.bottom; anchors.bottomMargin: 40; width: 1; height: 16; color: root.hudSubColor }
                Rectangle { anchors.right: parent.right; anchors.rightMargin: 40; anchors.bottom: parent.bottom; anchors.bottomMargin: 40; width: 16; height: 1; color: root.hudSubColor }
                Rectangle { anchors.right: parent.right; anchors.rightMargin: 40; anchors.bottom: parent.bottom; anchors.bottomMargin: 40; width: 1; height: 16; color: root.hudSubColor }

                RotationAnimation on rotation {
                    from: 0
                    to: 360
                    duration: 120000
                    loops: Animation.Infinite
                }
            }
        }
    }
}

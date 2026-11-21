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
                color: Qt.rgba(0.9, 0.11, 0.14, 0.75)
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
                color: Qt.rgba(0.9, 0.11, 0.14, 0.75)
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
                color: Qt.rgba(0.9, 0.11, 0.14, 0.65)
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
                color: Qt.rgba(0.9, 0.11, 0.14, 0.65)
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
                    color: Qt.rgba(0.9, 0.11, 0.14, 0.25)
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
                    color: Qt.rgba(0.9, 0.11, 0.14, 0.25)
                }
            }
        }

        // Center Target Lock Ring Framing
        Item {
            anchors.centerIn: parent
            width: 380
            height: 380

            // Rotating reticle ring
            Item {
                anchors.fill: parent
                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: "transparent"
                    border { width: 1; color: Qt.rgba(0.9, 0.11, 0.14, 0.12) }
                }

                // Range and azimuth stamping
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: -18
                    text: "TARGET ACQUISITION // RNG: 0420m // AZM: 184.2°"
                    font.family: Theme.mono
                    font.pixelSize: 9
                    font.bold: true
                    color: Qt.rgba(0.9, 0.11, 0.14, 0.45)
                    font.letterSpacing: 1.2
                }

                // Target cross tick lines
                Rectangle { anchors.left: parent.left; anchors.leftMargin: -12; anchors.verticalCenter: parent.verticalCenter; width: 24; height: 1; color: Qt.rgba(0.9, 0.11, 0.14, 0.4) }
                Rectangle { anchors.right: parent.right; anchors.rightMargin: -12; anchors.verticalCenter: parent.verticalCenter; width: 24; height: 1; color: Qt.rgba(0.9, 0.11, 0.14, 0.4) }
                Rectangle { anchors.top: parent.top; anchors.topMargin: -12; anchors.horizontalCenter: parent.horizontalCenter; width: 1; height: 24; color: Qt.rgba(0.9, 0.11, 0.14, 0.4) }
                Rectangle { anchors.bottom: parent.bottom; anchors.bottomMargin: -12; anchors.horizontalCenter: parent.horizontalCenter; width: 1; height: 24; color: Qt.rgba(0.9, 0.11, 0.14, 0.4) }

                // Outer 4 corner brackets
                Rectangle { x: 40; y: 40; width: 16; height: 1; color: Qt.rgba(0.9, 0.11, 0.14, 0.35) }
                Rectangle { x: 40; y: 40; width: 1; height: 16; color: Qt.rgba(0.9, 0.11, 0.14, 0.35) }
                Rectangle { anchors.right: parent.right; anchors.rightMargin: 40; y: 40; width: 16; height: 1; color: Qt.rgba(0.9, 0.11, 0.14, 0.35) }
                Rectangle { anchors.right: parent.right; anchors.rightMargin: 40; y: 40; width: 1; height: 16; color: Qt.rgba(0.9, 0.11, 0.14, 0.35) }
                Rectangle { x: 40; anchors.bottom: parent.bottom; anchors.bottomMargin: 40; width: 16; height: 1; color: Qt.rgba(0.9, 0.11, 0.14, 0.35) }
                Rectangle { x: 40; anchors.bottom: parent.bottom; anchors.bottomMargin: 40; width: 1; height: 16; color: Qt.rgba(0.9, 0.11, 0.14, 0.35) }
                Rectangle { anchors.right: parent.right; anchors.rightMargin: 40; anchors.bottom: parent.bottom; anchors.bottomMargin: 40; width: 16; height: 1; color: Qt.rgba(0.9, 0.11, 0.14, 0.35) }
                Rectangle { anchors.right: parent.right; anchors.rightMargin: 40; anchors.bottom: parent.bottom; anchors.bottomMargin: 40; width: 1; height: 16; color: Qt.rgba(0.9, 0.11, 0.14, 0.35) }

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

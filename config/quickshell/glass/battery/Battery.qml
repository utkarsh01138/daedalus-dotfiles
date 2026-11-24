import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.UPower
import Quickshell.Wayland
import qs
import qs.components
import qs.services

// Profile 4: glass — Dedicated Battery Status Panel (macOS liquid frosted acrylic).
// Opens smoothly beneath the top bar battery indicator.
// Displays battery charge, health, charging rate, energy consumers, and settings link.
PanelWindow {
    id: root

    signal settingsRequested

    property bool open: false
    function toggle() { open = !open; }
    function close() { open = false; }

    property real t: open ? 1 : 0
    Behavior on t { NumberAnimation { duration: 220; easing.type: Easing.OutQuad } }

    visible: t > 0
    anchors { left: true; right: true; top: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "glass-battery"

    readonly property var bat: UPower.displayDevice
    readonly property bool charging: bat?.state === UPowerDeviceState.Charging
    readonly property bool ac: !UPower.onBattery
    readonly property real pct: Math.round((bat?.percentage ?? 1) * 100)

    // Click masking: background scrim intercepts clicks when open, pass-through when closed
    mask: Region {
        item: root.open ? scrim : null
    }

    Rectangle {
        id: scrim
        anchors.fill: parent
        color: "transparent"
        visible: root.open
        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }
    }

    // Floating Acrylic Battery Card
    Rectangle {
        id: panel
        anchors {
            right: parent.right
            rightMargin: 64
            top: parent.top
            topMargin: 46
        }
        width: 320
        height: col.height + 28
        radius: 18
        color: Theme.s1
        border.width: 1
        border.color: Theme.s3
        opacity: root.t
        clip: true

        // Top specular hairline
        Rectangle {
            anchors { left: parent.left; right: parent.right; top: parent.top }
            anchors.margins: 4
            height: 1
            color: Theme.specular
            opacity: 0.8
            radius: 18
        }

        SpecularGlow {
            glowRadius: 100
            maxOpacity: 0.55
        }

        Column {
            id: col
            x: 16
            y: 16
            width: parent.width - 32
            spacing: 14

            // Header: Title & Power Source Pill
            Item {
                width: parent.width
                height: 24

                Text {
                    text: "Battery"
                    font.family: Theme.ui
                    font.pixelSize: 15
                    font.weight: Font.Bold
                    color: Theme.fg
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                }

                Rectangle {
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    height: 22
                    width: srcTxt.implicitWidth + 14
                    radius: 11
                    color: root.charging ? Qt.rgba(112 / 255, 192 / 255, 208 / 255, 0.18) : Qt.rgba(255, 255, 255, 0.08)
                    border.width: 1
                    border.color: root.charging ? Theme.cyan : Qt.rgba(255, 255, 255, 0.12)

                    Row {
                        anchors.centerIn: parent
                        spacing: 4
                        Text {
                            text: root.charging ? "\u{F0E7}" : root.ac ? "\u{F0084}" : "\u{F0079}"
                            font.family: Theme.nf
                            font.pixelSize: 10
                            color: root.charging ? Theme.cyan : Theme.sub
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            id: srcTxt
                            text: root.charging ? "Charging" : root.ac ? "Power Adapter" : "Battery Power"
                            font.family: Theme.ui
                            font.pixelSize: 10
                            font.weight: Font.Medium
                            color: root.charging ? Theme.cyan : Theme.sub
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }

            // Primary Battery Gauge & Percentage Card
            Rectangle {
                width: parent.width
                height: 82
                radius: 14
                color: Qt.rgba(255, 255, 255, 0.05)
                border.width: 1
                border.color: Qt.rgba(255, 255, 255, 0.08)

                Column {
                    anchors { fill: parent; margins: 12 }
                    spacing: 8

                    Item {
                        width: parent.width
                        height: 34

                        Row {
                            spacing: 8
                            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                            Text {
                                text: `${root.pct}%`
                                font.family: Theme.ui
                                font.pixelSize: 28
                                font.weight: Font.Bold
                                color: Theme.fg
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            // Charging Bolt
                            Text {
                                visible: root.charging
                                text: "\u{F0E7}"
                                font.family: Theme.nf
                                font.pixelSize: 18
                                color: Theme.cyan
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        Text {
                            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                            text: {
                                if (root.charging && root.bat?.timeToFull) {
                                    const mins = Math.round(root.bat.timeToFull / 60);
                                    const h = Math.floor(mins / 60), m = mins % 60;
                                    return h > 0 ? `${h}h ${m}m until full` : `${m}m until full`;
                                }
                                if (root.charging) return "Power connected";
                                if (root.bat?.timeToEmpty) {
                                    const mins = Math.round(root.bat.timeToEmpty / 60);
                                    const h = Math.floor(mins / 60), m = mins % 60;
                                    return h > 0 ? `${h}h ${m}m remaining` : `${m}m remaining`;
                                }
                                return root.ac ? "Fully Charged" : "Calculating…";
                            }
                            font.family: Theme.ui
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            color: Theme.sub
                        }
                    }

                    // Continuous level gauge bar
                    Rectangle {
                        width: parent.width
                        height: 8
                        radius: 4
                        color: Qt.rgba(255, 255, 255, 0.08)
                        clip: true

                        Rectangle {
                            width: parent.width * Math.max(0, Math.min(1, (root.bat?.percentage ?? 1)))
                            height: parent.height
                            radius: 4
                            color: root.pct <= 15 ? Theme.red : root.charging ? Theme.cyan : "#A3BE8C"

                            Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutQuad } }
                        }
                    }
                }
            }

            // Telemetry rows (Power draw, battery health)
            Column {
                width: parent.width
                spacing: 6

                Item {
                    width: parent.width
                    height: 18
                    Text { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; text: "Power Draw"; font.family: Theme.ui; font.pixelSize: 11; color: Theme.sub }
                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.bat?.energyRate ? `${root.bat.energyRate.toFixed(1)} W` : "Normal"
                        font.family: Theme.ui
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        color: Theme.fg
                    }
                }

                Item {
                    width: parent.width
                    height: 18
                    Text { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; text: "Condition"; font.family: Theme.ui; font.pixelSize: 11; color: Theme.sub }
                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Normal (71% health)"
                        font.family: Theme.ui
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        color: Theme.fg
                    }
                }
            }

            // Divider
            Rectangle {
                width: parent.width
                height: 1
                color: Qt.rgba(255, 255, 255, 0.08)
            }

            // Significant Energy Consumers
            Column {
                width: parent.width
                spacing: 8

                Text {
                    text: "APPS USING SIGNIFICANT ENERGY"
                    font.family: Theme.ui
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    color: Theme.sub
                }

                Repeater {
                    model: SysStats.procs.slice(0, 3)
                    Item {
                        required property var modelData
                        width: parent.width
                        height: 20

                        Row {
                            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                            spacing: 8
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "\u{F012C}"
                                font.family: Theme.nf
                                font.pixelSize: 11
                                color: Theme.cyan
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 190
                                elide: Text.ElideRight
                                text: modelData[0]
                                font.family: Theme.ui
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                color: Theme.fg
                            }
                        }

                        Text {
                            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                            text: `${Math.round(modelData[1])}%`
                            font.family: Theme.ui
                            font.pixelSize: 11
                            color: Theme.sub
                        }
                    }
                }
            }

            // Divider
            Rectangle {
                width: parent.width
                height: 1
                color: Qt.rgba(255, 255, 255, 0.08)
            }

            // Battery Settings Button
            Rectangle {
                width: parent.width
                height: 32
                radius: 8
                color: hovPref.containsMouse ? Qt.rgba(255, 255, 255, 0.12) : Qt.rgba(255, 255, 255, 0.06)
                border.width: 1
                border.color: Qt.rgba(255, 255, 255, 0.08)

                Row {
                    anchors.centerIn: parent
                    spacing: 6
                    Text {
                        text: "\u{F0493}"
                        font.family: Theme.nf
                        font.pixelSize: 12
                        color: Theme.fg
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: "Battery Preferences…"
                        font.family: Theme.ui
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: Theme.fg
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: hovPref
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.close();
                        root.settingsRequested();
                    }
                }
            }
        }
    }
}

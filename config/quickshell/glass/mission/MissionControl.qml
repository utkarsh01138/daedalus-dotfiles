import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs
import qs.components

// Profile 4: glass — Mission Control / Exposé (macOS Sonoma / visionOS liquid frosted acrylic).
// Fullscreen overview grid of all active windows across all workspaces.
// Supports direct window focus, closing windows, workspace switching, and instant search filtering.
PanelWindow {
    id: root

    property bool open: false
    property string filterQuery: ""

    function toggle() {
        if (open) close();
        else show();
    }

    function show() {
        open = true;
        filterQuery = "";
        searchField.text = "";
        searchField.forceActiveFocus();
    }

    function close() {
        open = false;
        filterQuery = "";
    }

    visible: t > 0
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "glass-mission"

    property real t: open ? 1 : 0
    Behavior on t { NumberAnimation { duration: Theme.t; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.glide } }

    function getAppIcon(cls) {
        return Quickshell.iconPath((cls || "application-x-executable").toLowerCase(), "application-x-executable");
    }

    // Active workspaces sorted by id
    readonly property var activeWorkspaces: {
        const ws = Hyprland.workspaces.values.slice();
        return ws.sort((a, b) => a.id - b.id);
    }

    // Active windows across all workspaces, filtered by query
    readonly property var activeWindows: {
        const tops = Hyprland.toplevels.values.filter(t => {
            const cls = (t.lastIpcObject?.class ?? "").toLowerCase();
            const title = (t.title ?? "").toLowerCase();
            const wsId = t.workspace?.id ?? 0;
            if (wsId <= 0 || cls === "" || cls.includes("quickshell")) return false;
            if (!root.filterQuery) return true;
            const q = root.filterQuery.toLowerCase();
            return cls.includes(q) || title.includes(q);
        });

        // Sort by workspace, then title
        return tops.sort((a, b) => {
            const wa = a.workspace?.id ?? 99;
            const wb = b.workspace?.id ?? 99;
            if (wa !== wb) return wa - wb;
            return (a.title ?? "").localeCompare(b.title ?? "");
        });
    }

    // Dark frosted acrylic scrim backdrop
    Rectangle {
        id: scrim
        anchors.fill: parent
        color: Qt.rgba(13 / 255, 16 / 255, 23 / 255, 0.75 * root.t)
        opacity: root.t

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }

        // --- Top Workspace Strip (Desktop 1, Desktop 2...) ---
        Rectangle {
            id: topBar
            anchors { top: parent.top; topMargin: 16; horizontalCenter: parent.horizontalCenter }
            height: 48
            width: Math.min(parent.width - 60, wsRow.implicitWidth + 32)
            radius: 24
            color: Theme.s1
            border.width: 1
            border.color: Theme.s3

            // Top specular hairline
            Rectangle {
                anchors { left: parent.left; right: parent.right; top: parent.top }
                anchors.margins: 4
                height: 1
                color: Theme.specular
                opacity: 0.8
                radius: 24
            }

            Row {
                id: wsRow
                anchors.centerIn: parent
                spacing: 8

                Repeater {
                    model: root.activeWorkspaces
                    Rectangle {
                        id: wsPill
                        required property var modelData
                        height: 32
                        width: wsPillContent.implicitWidth + 24
                        radius: 16
                        readonly property bool isCurrent: modelData.id === (Hyprland.focusedMonitor?.activeWorkspace?.id ?? -1)
                        color: isCurrent ? Qt.rgba(112 / 255, 192 / 255, 208 / 255, 0.22) : hovWs.containsMouse ? Qt.rgba(255, 255, 255, 0.12) : Qt.rgba(255, 255, 255, 0.05)
                        border.width: 1
                        border.color: isCurrent ? Theme.cyan : Qt.rgba(255, 255, 255, 0.10)

                        Row {
                            id: wsPillContent
                            anchors.centerIn: parent
                            spacing: 6
                            Text {
                                text: `Desktop ${wsPill.modelData.id}`
                                font.family: Theme.ui
                                font.pixelSize: 12
                                font.weight: wsPill.isCurrent ? Font.Bold : Font.Medium
                                color: wsPill.isCurrent ? Theme.cyan : Theme.fg
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: hovWs
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Quickshell.execDetached(["hyprctl", "dispatch", "workspace", `${wsPill.modelData.id}`]);
                            }
                        }
                    }
                }
            }
        }

        // --- Center Window Grid ---
        Item {
            id: gridArea
            anchors {
                top: topBar.bottom
                topMargin: 24
                bottom: bottomBar.top
                bottomMargin: 16
                left: parent.left
                right: parent.right
                leftMargin: 40
                rightMargin: 40
            }

            ScrollView {
                anchors.fill: parent
                clip: true

                Flow {
                    id: flowGrid
                    width: gridArea.width
                    spacing: 24

                    Repeater {
                        model: root.activeWindows
                        Rectangle {
                            id: winCard
                            required property var modelData
                            required property int index

                            // Responsive squircle card: 3 columns on typical display
                            width: Math.max(280, (gridArea.width - 48) / Math.min(3, Math.max(1, root.activeWindows.length)))
                            height: 190
                            radius: 16
                            color: Theme.s2
                            border.width: hovWin.containsMouse ? 1.5 : 1
                            border.color: hovWin.containsMouse ? Theme.cyan : Theme.s3

                            scale: hovWin.containsMouse ? 1.03 : 1.0
                            Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }
                            Behavior on border.color { ColorAnimation { duration: 180 } }

                            // Top specular catch
                            Rectangle {
                                anchors { left: parent.left; right: parent.right; top: parent.top }
                                anchors.margins: 2
                                height: 1
                                color: Theme.specular
                                opacity: 0.9
                                radius: 16
                            }

                            // Card Header: Traffic Light close + App icon + class + workspace badge
                            Rectangle {
                                id: cardHeader
                                anchors { top: parent.top; left: parent.left; right: parent.right }
                                height: 42
                                radius: 16
                                color: Qt.rgba(255, 255, 255, 0.04)

                                Row {
                                    anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                                    spacing: 8

                                    // Red traffic light close dot
                                    Rectangle {
                                        width: 12
                                        height: 12
                                        radius: 6
                                        color: Theme.red
                                        anchors.verticalCenter: parent.verticalCenter

                                        Text {
                                            anchors.centerIn: parent
                                            visible: hovCloseWin.containsMouse
                                            text: "\u{F00D}"
                                            font.family: Theme.nf
                                            font.pixelSize: 8
                                            color: Qt.rgba(0, 0, 0, 0.6)
                                        }

                                        MouseArea {
                                            id: hovCloseWin
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                Quickshell.execDetached(["hyprctl", "dispatch", "closewindow", "address:" + winCard.modelData.address]);
                                            }
                                        }
                                    }

                                    // App Icon
                                    Image {
                                        width: 20
                                        height: 20
                                        source: root.getAppIcon(winCard.modelData.lastIpcObject?.class)
                                        fillMode: Image.PreserveAspectFit
                                        smooth: true
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    // App Name / Class
                                    Text {
                                        text: winCard.modelData.lastIpcObject?.class || "Window"
                                        font.family: Theme.ui
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                        color: Theme.fg
                                        elide: Text.ElideRight
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }

                                // Workspace pill on the right
                                Rectangle {
                                    anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                                    height: 20
                                    width: wsBadgeText.implicitWidth + 10
                                    radius: 10
                                    color: Qt.rgba(255, 255, 255, 0.08)

                                    Text {
                                        id: wsBadgeText
                                        anchors.centerIn: parent
                                        text: `Desktop ${winCard.modelData.workspace?.id ?? 1}`
                                        font.family: Theme.ui
                                        font.pixelSize: 9
                                        font.weight: Font.Medium
                                        color: Theme.sub
                                    }
                                }
                            }

                            // Card Body: Window Title
                            Item {
                                anchors { top: cardHeader.bottom; left: parent.left; right: parent.right; bottom: parent.bottom; margins: 14 }

                                Column {
                                    anchors.centerIn: parent
                                    width: parent.width
                                    spacing: 6

                                    Text {
                                        width: parent.width
                                        text: winCard.modelData.title || winCard.modelData.lastIpcObject?.class || "Untitled"
                                        font.family: Theme.title
                                        font.pixelSize: 14
                                        font.weight: Font.Bold
                                        color: Theme.fg
                                        wrapMode: Text.Wrap
                                        maximumLineCount: 3
                                        elide: Text.ElideRight
                                        horizontalAlignment: Text.AlignHCenter
                                    }

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "Click to focus"
                                        font.family: Theme.ui
                                        font.pixelSize: 10
                                        color: Theme.mute
                                    }
                                }
                            }

                            MouseArea {
                                id: hovWin
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Quickshell.execDetached(["hyprctl", "dispatch", "focuswindow", "address:" + winCard.modelData.address]);
                                    root.close();
                                }
                            }
                        }
                    }
                }
            }

            // Empty state if no windows are open
            Column {
                anchors.centerIn: parent
                visible: root.activeWindows.length === 0
                spacing: 12

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "\u{F031E}"
                    font.family: Theme.nf
                    font.pixelSize: 42
                    color: Theme.mute
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "No open windows on this display"
                    font.family: Theme.title
                    font.pixelSize: 16
                    font.weight: Font.Bold
                    color: Theme.mute
                }
            }
        }

        // --- Bottom Helper & Search Strip ---
        Row {
            id: bottomBar
            anchors { bottom: parent.bottom; bottomMargin: 20; horizontalCenter: parent.horizontalCenter }
            spacing: 16

            // Search pill to filter windows
            Rectangle {
                width: 240
                height: 34
                radius: 17
                color: Theme.s1
                border.width: 1
                border.color: Theme.s3

                Row {
                    anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                    spacing: 8

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "\u{F002}"
                        font.family: Theme.nf
                        font.pixelSize: 11
                        color: Theme.mute
                    }

                    TextInput {
                        id: searchField
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 24
                        font.family: Theme.ui
                        font.pixelSize: 12
                        color: Theme.fg
                        clip: true
                        onTextChanged: root.filterQuery = text

                        Text {
                            anchors.fill: parent
                            visible: !searchField.text
                            text: "Type to filter windows..."
                            font: parent.font
                            color: Theme.mute
                        }
                    }
                }
            }

            // Keyboard hints
            Rectangle {
                height: 34
                width: hintText.implicitWidth + 24
                radius: 17
                color: Theme.s1
                border.width: 1
                border.color: Theme.s3

                Text {
                    id: hintText
                    anchors.centerIn: parent
                    text: "↵ Click to focus · Esc to dismiss"
                    font.family: Theme.ui
                    font.pixelSize: 11
                    color: Theme.sub
                }
            }
        }
    }

    // Dismiss on Escape
    Shortcut {
        sequence: "Escape"
        enabled: root.open
        onActivated: root.close()
    }
}

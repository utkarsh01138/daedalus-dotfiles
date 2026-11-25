import QtQuick
import Quickshell
import Quickshell.Wayland
import qs

// Profile 4: glass — Hot Corners Sensor (macOS style).
// Monitors 4 screen corners with 200ms dwell detection.
// Uses Region mask so only the tiny 10x10 corner zones intercept events.
PanelWindow {
    id: root

    signal triggered(string action)

    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "glass-corners"

    // Only intercept events inside the 4 corner sensors
    mask: Region {
        item: sensorContainer
    }

    Item {
        id: sensorContainer
        anchors.fill: parent

        // Corner 1: Top-Left
        Item {
            id: cTopLeft
            anchors { top: parent.top; left: parent.left }
            width: 10
            height: 10

            HoverHandler {
                id: hovTL
                onHoveredChanged: {
                    if (hovered) dwellTL.restart();
                    else dwellTL.stop();
                }
            }
            Timer {
                id: dwellTL
                interval: 220
                onTriggered: {
                    if (hovTL.hovered) {
                        const act = Theme.state.hotCorners?.topLeft ?? "none";
                        if (act && act !== "none") root.triggered(act);
                    }
                }
            }
        }

        // Corner 2: Top-Right
        Item {
            id: cTopRight
            anchors { top: parent.top; right: parent.right }
            width: 10
            height: 10

            HoverHandler {
                id: hovTR
                onHoveredChanged: {
                    if (hovered) dwellTR.restart();
                    else dwellTR.stop();
                }
            }
            Timer {
                id: dwellTR
                interval: 220
                onTriggered: {
                    if (hovTR.hovered) {
                        const act = Theme.state.hotCorners?.topRight ?? "none";
                        if (act && act !== "none") root.triggered(act);
                    }
                }
            }
        }

        // Corner 3: Bottom-Left
        Item {
            id: cBottomLeft
            anchors { bottom: parent.bottom; left: parent.left }
            width: 10
            height: 10

            HoverHandler {
                id: hovBL
                onHoveredChanged: {
                    if (hovered) dwellBL.restart();
                    else dwellBL.stop();
                }
            }
            Timer {
                id: dwellBL
                interval: 220
                onTriggered: {
                    if (hovBL.hovered) {
                        const act = Theme.state.hotCorners?.bottomLeft ?? "none";
                        if (act && act !== "none") root.triggered(act);
                    }
                }
            }
        }

        // Corner 4: Bottom-Right
        Item {
            id: cBottomRight
            anchors { bottom: parent.bottom; right: parent.right }
            width: 10
            height: 10

            HoverHandler {
                id: hovBR
                onHoveredChanged: {
                    if (hovered) dwellBR.restart();
                    else dwellBR.stop();
                }
            }
            Timer {
                id: dwellBR
                interval: 220
                onTriggered: {
                    if (hovBR.hovered) {
                        const act = Theme.state.hotCorners?.bottomRight ?? "none";
                        if (act && act !== "none") root.triggered(act);
                    }
                }
            }
        }
    }
}

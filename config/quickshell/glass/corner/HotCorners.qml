import QtQuick
import Quickshell
import Quickshell.Wayland
import qs

// Profile 4: glass — Hot Corners Sensor (macOS style).
// Creates 4 independent 8x8px corner micro-windows on Wayland Overlay.
// Only the exact 8x8px pixel bounds at each monitor corner receive events;
// 100% of the rest of the screen is completely untouched with zero mouse interception.
Scope {
    id: root

    property var screen: null
    signal triggered(string action)

    // Corner 1: Top-Left (8x8px)
    PanelWindow {
        screen: root.screen
        anchors { top: true; left: true }
        implicitWidth: 8
        implicitHeight: 8
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "glass-corners"
        visible: (Theme.state.hotCorners?.topLeft ?? "none") !== "none"

        HoverHandler {
            id: hovTL
            onHoveredChanged: hovered ? dwellTL.restart() : dwellTL.stop()
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

    // Corner 2: Top-Right (8x8px)
    PanelWindow {
        screen: root.screen
        anchors { top: true; right: true }
        implicitWidth: 8
        implicitHeight: 8
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "glass-corners"
        visible: (Theme.state.hotCorners?.topRight ?? "none") !== "none"

        HoverHandler {
            id: hovTR
            onHoveredChanged: hovered ? dwellTR.restart() : dwellTR.stop()
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

    // Corner 3: Bottom-Left (8x8px)
    PanelWindow {
        screen: root.screen
        anchors { bottom: true; left: true }
        implicitWidth: 8
        implicitHeight: 8
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "glass-corners"
        visible: (Theme.state.hotCorners?.bottomLeft ?? "none") !== "none"

        HoverHandler {
            id: hovBL
            onHoveredChanged: hovered ? dwellBL.restart() : dwellBL.stop()
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

    // Corner 4: Bottom-Right (8x8px)
    PanelWindow {
        screen: root.screen
        anchors { bottom: true; right: true }
        implicitWidth: 8
        implicitHeight: 8
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "glass-corners"
        visible: (Theme.state.hotCorners?.bottomRight ?? "none") !== "none"

        HoverHandler {
            id: hovBR
            onHoveredChanged: hovered ? dwellBR.restart() : dwellBR.stop()
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

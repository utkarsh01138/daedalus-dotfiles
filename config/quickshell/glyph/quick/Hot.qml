import QtQuick
import Quickshell
import Quickshell.Wayland
import qs

// Hot edge: Hovering cursor along the right edge reveals Quick Settings (Quick.peek).
// A 2px strip covering the lower 80% of the screen height avoids accidental triggers near window corners or scrollbars.
PanelWindow {
    id: root

    signal triggered

    visible: Theme.state.quickHover
    anchors { right: true; bottom: true }
    implicitWidth: 2
    implicitHeight: Math.round(screen.height * 0.8)
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "glyph-hot"

    HoverHandler { id: hov; onHoveredChanged: hovered ? dwell.restart() : dwell.stop() }
    Timer { id: dwell; interval: 150; onTriggered: if (hov.hovered) root.triggered() }
}

import QtQuick
import QtQuick.Shapes
import qs

// Dynamic Specular Cursor Glow (Obsidian Section 5.5).
// Projects a soft, subtle radial specular light highlight beneath the mouse pointer,
// simulating light refracting through real frosted acrylic plate.
Item {
    id: root
    anchors.fill: parent
    clip: true

    property real glowRadius: 110
    property color glowColor: Theme.specular
    property real maxOpacity: 0.9
    property bool active: hover.hovered

    property real mx: width / 2
    property real my: height / 2

    HoverHandler {
        id: hover
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onPointChanged: {
            root.mx = point.position.x;
            root.my = point.position.y;
        }
    }

    Shape {
        id: shape
        anchors.fill: parent
        opacity: root.active ? root.maxOpacity : 0
        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutQuad } }

        ShapePath {
            strokeWidth: -1
            fillGradient: RadialGradient {
                centerX: root.mx
                centerY: root.my
                centerRadius: root.glowRadius
                focalX: root.mx
                focalY: root.my
                GradientStop { position: 0.0; color: root.glowColor }
                GradientStop { position: 0.45; color: Qt.rgba(root.glowColor.r, root.glowColor.g, root.glowColor.b, root.glowColor.a * 0.35) }
                GradientStop { position: 1.0; color: "transparent" }
            }
            PathRectangle { x: 0; y: 0; width: root.width; height: root.height }
        }
    }
}

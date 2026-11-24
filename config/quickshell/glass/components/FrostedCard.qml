import QtQuick
import qs

// FrostedCard: High-end frosted acrylic surface with liquid squircle curvature,
// top-edge specular light refraction hairline, and dynamic cursor specular glow.
Rectangle {
    id: root

    property bool specularGlow: true
    property real glowRadius: 110
    property color glowColor: Theme.specular
    property alias glowActive: glow.active

    color: Theme.card
    radius: 18
    border.width: 1
    border.color: Qt.rgba(1, 1, 1, 0.12)
    clip: true

    // Top-edge light refraction catch (specular hairline)
    Rectangle {
        anchors { left: parent.left; right: parent.right; top: parent.top }
        anchors.margins: 1
        height: 1
        radius: root.radius
        color: Theme.specular
        opacity: 0.65
    }

    // Dynamic Specular Cursor Glow
    SpecularGlow {
        id: glow
        visible: root.specularGlow
        glowRadius: root.glowRadius
        glowColor: root.glowColor
    }
}

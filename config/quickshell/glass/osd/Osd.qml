import QtQuick
import Quickshell
import Quickshell.Wayland
import qs
import qs.components
import qs.services

// Profile 4: glass — Floating Volume & Brightness OSD HUD (macOS / visionOS liquid frosted acrylic).
// Appears centered at the bottom of the screen upon hardware key press, smooth cyan fill bar & percentage.
PanelWindow {
    id: root

    property string kind: "vol" // "vol" | "bri"
    property real value: 0
    property bool shown: false
    property bool armed: false

    Timer { running: true; interval: 1200; onTriggered: root.armed = true }

    function trigger(k, v) {
        if (!armed) return;
        kind = k;
        value = Math.max(0, Math.min(1, v));
        shown = true;
        dismissT.restart();
    }

    Timer {
        id: dismissT
        interval: 1800
        onTriggered: root.shown = false
    }

    Connections {
        target: Sys.sink?.audio ?? null
        function onVolumeChanged() { root.trigger("vol", Sys.muted ? 0 : Sys.vol); }
        function onMutedChanged() { root.trigger("vol", Sys.muted ? 0 : Sys.vol); }
    }
    Connections {
        target: Sys
        function onBriChanged() { root.trigger("bri", Sys.bri); }
    }

    visible: root.shown
    anchors { bottom: true; left: true; right: true }
    implicitHeight: 120
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "glass-osd"
    mask: Region {} // 100% click-through

    Rectangle {
        id: hud
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 50
        width: 220
        height: 48
        radius: 16
        color: Theme.s1
        border.width: 1
        border.color: Theme.s3
        clip: true

        // Top specular hairline
        Rectangle {
            anchors { left: parent.left; right: parent.right; top: parent.top }
            anchors.margins: 4
            height: 1
            color: Theme.specular
            opacity: 0.8
            radius: 16
        }

        Row {
            anchors.centerIn: parent
            spacing: 12
            width: parent.width - 28

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.kind === "bri" ? "\u{F00E0}" : (Sys.muted || root.value === 0 ? "\u{F075F}" : "\u{F057E}")
                font.family: Theme.nf
                font.pixelSize: 16
                color: Theme.cyan
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 24 - 44
                height: 8
                radius: 4
                color: Qt.rgba(1, 1, 1, 0.14)
                clip: true

                Rectangle {
                    anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                    width: Math.max(8, parent.width * root.value)
                    radius: 4
                    color: Theme.cyan
                    Behavior on width { NumberAnimation { duration: 80 } }
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: `${Math.round(root.value * 100)}%`
                font.family: Theme.mono
                font.pixelSize: 11
                font.weight: Font.Bold
                color: Theme.fg
            }
        }
    }
}

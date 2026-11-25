import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris
import Quickshell.Services.UPower
import qs
import qs.components
import qs.services

// Profile 4: glass — Dynamic Island / Top Notch HUD (macOS / visionOS liquid frosted acrylic).
// Centered at the top beneath the floating menu bar.
// Fluidly morphs and expands for Volume, Brightness, Battery status changes, and Media playback changes.
PanelWindow {
    id: root

    property string mode: "vol" // "vol" | "bri" | "bat" | "media" | "mute"
    property real val: 0
    property bool shown: false
    property bool armed: false

    // Initial arming delay to prevent startup notification bursts
    Timer { running: true; interval: 1400; onTriggered: root.armed = true }

    Timer {
        id: dismissT
        interval: 2200
        onTriggered: root.shown = false
    }

    function trigger(m, v) {
        if (!armed) return;
        mode = m;
        val = Math.max(0, Math.min(1, v));
        shown = true;
        dismissT.restart();
    }

    // Hardware Audio & Brightness listeners
    Connections {
        target: Sys.sink?.audio ?? null
        function onVolumeChanged() { root.trigger("vol", Sys.muted ? 0 : Sys.vol); }
        function onMutedChanged() { root.trigger(Sys.muted ? "mute" : "vol", Sys.vol); }
    }
    Connections {
        target: Sys
        function onBriChanged() { root.trigger("bri", Sys.bri); }
    }

    // Battery / Power connection
    readonly property var bat: UPower.devices.values.find(d => d.isRechargeable) ?? null
    Connections {
        target: root.bat
        function onStateChanged() {
            if (!root.armed) return;
            root.trigger("bat", root.bat?.percentage ?? 1);
        }
    }

    // Media / Song change connection
    Connections {
        target: Media
        function onTrackChanged() {
            if (!root.armed || !Media.player || !Media.player.trackTitle) return;
            root.trigger("media", 1);
        }
    }

    visible: root.shown || island.opacity > 0
    anchors { top: true; left: true; right: true }
    implicitHeight: 90
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "glass-island"
    mask: Region {} // 100% click-through

    Rectangle {
        id: island
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.shown ? 12 : -50
        opacity: root.shown ? 1 : 0
        scale: root.shown ? 1 : 0.85

        width: {
            if (root.mode === "media") return 360;
            if (root.mode === "bat") return 260;
            if (root.mode === "mute") return 210;
            return 280; // vol, bri
        }
        height: root.mode === "media" ? 48 : 42
        radius: height / 2

        color: Theme.bg
        border.width: 1
        border.color: Theme.s3
        clip: true

        Behavior on y { NumberAnimation { duration: 320; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.16, 1, 0.3, 1] } }
        Behavior on opacity { NumberAnimation { duration: 240 } }
        Behavior on scale { NumberAnimation { duration: 320; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.16, 1, 0.3, 1] } }
        Behavior on width { NumberAnimation { duration: 320; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.16, 1, 0.3, 1] } }
        Behavior on height { NumberAnimation { duration: 320; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.16, 1, 0.3, 1] } }

        // Top specular hairline refraction catch
        Rectangle {
            anchors { left: parent.left; right: parent.right; top: parent.top }
            anchors.margins: 2
            height: 1
            color: Theme.specular
            opacity: 0.9
            radius: parent.radius
        }

        // --- 1. VOLUME / BRIGHTNESS HUD ---
        Row {
            visible: root.mode === "vol" || root.mode === "bri"
            anchors.centerIn: parent
            spacing: 12
            width: parent.width - 32

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.mode === "bri" ? "\u{F00E0}" : (Sys.muted || root.val === 0 ? "\u{F075F}" : root.val < 0.4 ? "\u{F057F}" : "\u{F057E}")
                font.family: Theme.nf
                font.pixelSize: 15
                color: root.mode === "bri" ? Theme.yellow : Theme.cyan
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 24 - 46
                height: 8
                radius: 4
                color: Qt.rgba(255, 255, 255, 0.12)
                clip: true

                Rectangle {
                    anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                    width: Math.max(6, parent.width * root.val)
                    radius: 4
                    color: root.mode === "bri" ? Theme.yellow : Theme.cyan

                    Behavior on width { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: `${Math.round(root.val * 100)}%`
                font.family: Theme.mono
                font.pixelSize: 11
                font.weight: Font.Bold
                color: Theme.fg
            }
        }

        // --- 2. BATTERY / POWER HUD ---
        Row {
            visible: root.mode === "bat"
            anchors.centerIn: parent
            spacing: 10

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.bat?.state === UPowerDeviceState.Charging ? "\u{F0E7}" : "\u{F0079}"
                font.family: Theme.nf
                font.pixelSize: 15
                color: root.bat?.state === UPowerDeviceState.Charging ? Theme.cyan : ((root.bat?.percentage ?? 1) <= 0.20 ? Theme.red : Theme.green)
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1

                Text {
                    text: root.bat?.state === UPowerDeviceState.Charging ? "Charging" : "On Battery"
                    font.family: Theme.ui
                    font.pixelSize: 12
                    font.weight: Font.Bold
                    color: Theme.fg
                }
                Text {
                    text: `${Math.round((root.bat?.percentage ?? 1) * 100)}% Available`
                    font.family: Theme.ui
                    font.pixelSize: 10
                    color: Theme.sub
                }
            }
        }

        // --- 3. MEDIA TRACK HUD ---
        Row {
            visible: root.mode === "media"
            anchors.centerIn: parent
            spacing: 10
            width: parent.width - 28

            // Album art thumbnail or vinyl icon
            Rectangle {
                width: 32
                height: 32
                radius: 6
                color: Qt.rgba(255, 255, 255, 0.10)
                clip: true
                anchors.verticalCenter: parent.verticalCenter

                Image {
                    anchors.fill: parent
                    source: Media.player?.trackArtUrl ?? ""
                    fillMode: Image.PreserveAspectCrop
                    visible: status === Image.Ready
                }
                Text {
                    anchors.centerIn: parent
                    visible: parent.children[0].status !== Image.Ready
                    text: "\u{F0025}"
                    font.family: Theme.nf
                    font.pixelSize: 16
                    color: Theme.lavender
                }
            }

            // Track & Artist Info
            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 32 - 40 - parent.spacing * 2
                clip: true

                Text {
                    width: parent.width
                    text: Media.player?.trackTitle || "Unknown Track"
                    font.family: Theme.ui
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    color: Theme.fg
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width
                    text: Media.player?.trackArtist || "Unknown Artist"
                    font.family: Theme.ui
                    font.pixelSize: 10
                    color: Theme.sub
                    elide: Text.ElideRight
                }
            }

            // Animated mini equalizer bars
            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                Repeater {
                    model: 4
                    Rectangle {
                        required property int index
                        width: 3
                        height: 6 + (index === 1 ? 10 : index === 2 ? 14 : index === 3 ? 8 : 4)
                        radius: 1.5
                        color: Theme.cyan
                        anchors.verticalCenter: parent.verticalCenter

                        SequentialAnimation on height {
                            running: Media.playing
                            loops: Animation.Infinite
                            NumberAnimation { from: 4; to: 16 - index * 2; duration: 250 + index * 60; easing.type: Easing.InOutQuad }
                            NumberAnimation { from: 16 - index * 2; to: 4; duration: 250 + index * 60; easing.type: Easing.InOutQuad }
                        }
                    }
                }
            }
        }

        // --- 4. MUTE HUD ---
        Row {
            visible: root.mode === "mute"
            anchors.centerIn: parent
            spacing: 8

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "\u{F075F}"
                font.family: Theme.nf
                font.pixelSize: 15
                color: Theme.red
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Audio Muted"
                font.family: Theme.ui
                font.pixelSize: 12
                font.weight: Font.Bold
                color: Theme.fg
            }
        }
    }
}

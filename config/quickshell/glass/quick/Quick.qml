import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.Notifications
import Quickshell.Services.Pipewire
import Quickshell.Wayland
import qs
import qs.components
import qs.settings
import qs.services

// Profile 4: glass — Control Center (macOS / visionOS modular acrylic tiles).
// Floating compact card anchored at top-right without desktop-dimming scrim.
// Features prominent Wi-Fi & Bluetooth tiles, Focus, Caffeine, Display & Sound sliders, Media card.
PanelWindow {
    id: root

    signal powerRequested
    signal settingsRequested

    property bool open: false
    property bool peeked: false
    function toggle() { peeked = false; open = !open; }
    function close() { open = false; pick = ""; }
    function pin() { peeked = false; }
    function peek() {
        if (open) return;
        peeked = true;
        open = true;
    }
    function openWith(k) {
        pick = k;
        open = true;
    }

    property string pick: "" // "wifi" | "bt" | ""

    property real t: open ? 1 : 0
    Behavior on t { NumberAnimation { duration: 220; easing.type: Easing.OutQuad } }

    visible: t > 0
    anchors { left: true; right: true; top: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open && !peeked ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "glass-quick"

    readonly property var wifi: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var net: wifi?.networks.values.find(n => n.connected) ?? null
    readonly property var bt: Bluetooth.defaultAdapter
    readonly property var btDev: Bluetooth.devices.values.find(d => d.connected) ?? null

    // Click masking: background scrim intercepts clicks when open, 100% pass-through when closed
    mask: Region {
        item: root.open ? scrim : null
    }

    // Dismiss when clicking outside the panel (100% transparent backdrop)
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

    // Floating Control Center Panel
    Rectangle {
        id: panel
        anchors {
            right: parent.right
            rightMargin: 12
            top: parent.top
            topMargin: 46
        }
        width: 350
        height: Math.min(parent.height - 60, col.height + 28)
        radius: 20
        color: Theme.s1
        border.width: 1
        border.color: Theme.s3
        opacity: root.t
        clip: true

        // Top specular hairline
        Rectangle {
            anchors { left: parent.left; right: parent.right; top: parent.top }
            anchors.margins: 6
            height: 1
            color: Theme.specular
            opacity: 0.8
            radius: 20
        }

        // Dynamic Specular Glow across the panel
        SpecularGlow {
            glowRadius: 130
            maxOpacity: 0.55
        }

        Flickable {
            id: flick
            anchors { fill: parent; margins: 14 }
            contentHeight: col.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: col
                width: parent.width
                spacing: 10

                // Top Header: Title & Quick Utilities
                Item {
                    width: parent.width
                    height: 24

                    Text {
                        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                        text: "Control Center"
                        font.family: Theme.ui
                        font.pixelSize: 13
                        font.weight: Font.Bold
                        color: Theme.fg
                    }

                    Row {
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                        spacing: 8

                        // Night Light / Blue Light Toggle
                        Rectangle {
                            width: 24
                            height: 24
                            radius: 12
                            color: Sys.night ? Theme.cyan : Qt.rgba(1, 1, 1, 0.10)
                            Text {
                                anchors.centerIn: parent
                                text: "\u{F0599}"
                                font.family: Theme.nf
                                font.pixelSize: 11
                                color: Sys.night ? "#0D1017" : Theme.fg
                            }
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Sys.toggleNight()
                            }
                        }

                        // Settings Icon
                        Rectangle {
                            width: 24
                            height: 24
                            radius: 12
                            color: hovSet.containsMouse ? Qt.rgba(1, 1, 1, 0.20) : Qt.rgba(1, 1, 1, 0.10)
                            Text {
                                anchors.centerIn: parent
                                text: "\u{F0493}"
                                font.family: Theme.nf
                                font.pixelSize: 11
                                color: Theme.fg
                            }
                            MouseArea {
                                id: hovSet
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.close();
                                    root.settingsRequested();
                                }
                            }
                        }

                        // Power Menu Icon
                        Rectangle {
                            width: 24
                            height: 24
                            radius: 12
                            color: hovPwr.containsMouse ? Qt.rgba(1, 1, 1, 0.20) : Qt.rgba(1, 1, 1, 0.10)
                            Text {
                                anchors.centerIn: parent
                                text: "\u{F0425}"
                                font.family: Theme.nf
                                font.pixelSize: 11
                                color: Theme.fg
                            }
                            MouseArea {
                                id: hovPwr
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.close();
                                    root.powerRequested();
                                }
                            }
                        }
                    }
                }

                // Wi-Fi Primary Capsule Tile
                Rectangle {
                    width: parent.width
                    height: 52
                    radius: 16
                    color: root.pick === "wifi" ? Qt.rgba(112 / 255, 192 / 255, 208 / 255, 0.16) : Theme.s2
                    border.width: 1
                    border.color: root.pick === "wifi" ? Theme.cyan : Qt.rgba(1, 1, 1, 0.10)
                    clip: true

                    SpecularGlow { glowRadius: 80; maxOpacity: 0.6 }

                    Row {
                        anchors { fill: parent; margins: 8 }
                        spacing: 10

                        // Wi-Fi Round Power Toggle
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 36
                            height: 36
                            radius: 18
                            color: Networking.wifiEnabled ? Theme.cyan : Qt.rgba(1, 1, 1, 0.12)

                            Text {
                                anchors.centerIn: parent
                                text: Networking.wifiEnabled ? "\u{F05A9}" : "\u{F05AA}"
                                font.family: Theme.nf
                                font.pixelSize: 15
                                color: Networking.wifiEnabled ? "#0D1017" : Theme.fg
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
                            }
                        }

                        // Wi-Fi Status Information
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 36 - 32 - 20
                            spacing: 1

                            Text {
                                text: "Wi-Fi"
                                font.family: Theme.ui
                                font.pixelSize: 12
                                font.weight: Font.Bold
                                color: Theme.fg
                            }
                            Text {
                                width: parent.width
                                elide: Text.ElideRight
                                text: !Networking.wifiEnabled ? "Off" : (root.net?.name ?? "Disconnected")
                                font.family: Theme.ui
                                font.pixelSize: 11
                                color: Networking.wifiEnabled && root.net ? Theme.cyan : Theme.sub
                            }
                        }

                        // Expand Chevron Button
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 32
                            height: 32
                            radius: 16
                            color: hovWifiExp.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: root.pick === "wifi" ? "\u{F0140}" : "\u{F0142}"
                                font.family: Theme.nf
                                font.pixelSize: 13
                                color: Theme.fg
                            }

                            MouseArea {
                                id: hovWifiExp
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.pick = (root.pick === "wifi" ? "" : "wifi")
                            }
                        }
                    }
                }

                // Bluetooth Primary Capsule Tile
                Rectangle {
                    width: parent.width
                    height: 52
                    radius: 16
                    color: root.pick === "bt" ? Qt.rgba(112 / 255, 192 / 255, 208 / 255, 0.16) : Theme.s2
                    border.width: 1
                    border.color: root.pick === "bt" ? Theme.cyan : Qt.rgba(1, 1, 1, 0.10)
                    clip: true

                    SpecularGlow { glowRadius: 80; maxOpacity: 0.6 }

                    Row {
                        anchors { fill: parent; margins: 8 }
                        spacing: 10

                        // Bluetooth Round Power Toggle
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 36
                            height: 36
                            radius: 18
                            color: root.bt?.enabled ? Theme.cyan : Qt.rgba(1, 1, 1, 0.12)

                            Text {
                                anchors.centerIn: parent
                                text: root.bt?.enabled ? "\u{F00AF}" : "\u{F00B2}"
                                font.family: Theme.nf
                                font.pixelSize: 15
                                color: root.bt?.enabled ? "#0D1017" : Theme.fg
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (root.bt) root.bt.enabled = !root.bt.enabled
                            }
                        }

                        // Bluetooth Status Information
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 36 - 32 - 20
                            spacing: 1

                            Text {
                                text: "Bluetooth"
                                font.family: Theme.ui
                                font.pixelSize: 12
                                font.weight: Font.Bold
                                color: Theme.fg
                            }
                            Text {
                                width: parent.width
                                elide: Text.ElideRight
                                text: !root.bt?.enabled ? "Off" : (root.btDev?.name ?? "On")
                                font.family: Theme.ui
                                font.pixelSize: 11
                                color: root.bt?.enabled && root.btDev ? Theme.cyan : Theme.sub
                            }
                        }

                        // Expand Chevron Button
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 32
                            height: 32
                            radius: 16
                            color: hovBtExp.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: root.pick === "bt" ? "\u{F0140}" : "\u{F0142}"
                                font.family: Theme.nf
                                font.pixelSize: 13
                                color: Theme.fg
                            }

                            MouseArea {
                                id: hovBtExp
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.pick = (root.pick === "bt" ? "" : "bt")
                            }
                        }
                    }
                }

                // 2-Column Row: Focus / DND + Caffeine
                Row {
                    width: parent.width
                    spacing: 8

                    // Do Not Disturb / Focus Card
                    Rectangle {
                        width: (parent.width - 8) / 2
                        height: 54
                        radius: 16
                        color: Theme.state.dnd ? Theme.lavender : Theme.s2
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.10)
                        clip: true

                        SpecularGlow { glowRadius: 70; maxOpacity: 0.6 }

                        Row {
                            anchors.centerIn: parent
                            spacing: 8
                            Rectangle {
                                width: 28
                                height: 28
                                radius: 14
                                color: Theme.state.dnd ? "#0D1017" : Qt.rgba(1, 1, 1, 0.12)
                                Text {
                                    anchors.centerIn: parent
                                    text: "\u{F0060}"
                                    font.family: Theme.nf
                                    font.pixelSize: 12
                                    color: Theme.state.dnd ? Theme.lavender : Theme.fg
                                }
                            }
                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                Text {
                                    text: "Focus"
                                    font.family: Theme.ui
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                    color: Theme.state.dnd ? "#0D1017" : Theme.fg
                                }
                                Text {
                                    text: Theme.state.dnd ? "Active" : "Off"
                                    font.family: Theme.ui
                                    font.pixelSize: 10
                                    color: Theme.state.dnd ? "#161B26" : Theme.sub
                                }
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Theme.state.dnd = !Theme.state.dnd
                        }
                    }

                    // Caffeine / Idle Inhibit Card
                    Rectangle {
                        width: (parent.width - 8) / 2
                        height: 54
                        radius: 16
                        color: Sys.caffeine ? Theme.cyan : Theme.s2
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.10)
                        clip: true

                        SpecularGlow { glowRadius: 70; maxOpacity: 0.6 }

                        Row {
                            anchors.centerIn: parent
                            spacing: 8
                            Rectangle {
                                width: 28
                                height: 28
                                radius: 14
                                color: Sys.caffeine ? "#0D1017" : Qt.rgba(1, 1, 1, 0.12)
                                Text {
                                    anchors.centerIn: parent
                                    text: "\u{F0745}"
                                    font.family: Theme.nf
                                    font.pixelSize: 12
                                    color: Sys.caffeine ? Theme.cyan : Theme.fg
                                }
                            }
                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                Text {
                                    text: "Caffeine"
                                    font.family: Theme.ui
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                    color: Sys.caffeine ? "#0D1017" : Theme.fg
                                }
                                Text {
                                    text: Sys.caffeine ? "Awake" : "Normal"
                                    font.family: Theme.ui
                                    font.pixelSize: 10
                                    color: Sys.caffeine ? "#161B26" : Theme.sub
                                }
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Sys.toggleCaffeine()
                        }
                    }
                }

                // Sub-Menu Picker (Wi-Fi or Bluetooth inline list)
                Picker {
                    width: parent.width
                    kind: root.pick
                    onTouched: root.pin()
                }

                // Display Brightness Card (Continuous Glowing Slider)
                Rectangle {
                    width: parent.width
                    height: 60
                    radius: 16
                    color: Theme.s2
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.10)
                    clip: true

                    SpecularGlow { glowRadius: 90; maxOpacity: 0.6 }

                    Column {
                        anchors { fill: parent; margins: 10 }
                        spacing: 6

                        Item {
                            width: parent.width
                            height: 14
                            Text {
                                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                                text: "Display"
                                font.family: Theme.ui
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                color: Theme.fg
                            }
                            Text {
                                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                                text: `${Math.round(Sys.bri * 100)}%`
                                font.family: Theme.mono
                                font.pixelSize: 10
                                color: Theme.sub
                            }
                        }

                        // Glowing Slider Track
                        Rectangle {
                            id: briTrack
                            width: parent.width
                            height: 20
                            radius: 10
                            color: Qt.rgba(1, 1, 1, 0.12)
                            clip: true

                            Rectangle {
                                anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                                width: Math.max(20, briTrack.width * Sys.bri)
                                radius: 10
                                color: Theme.fg

                                Text {
                                    anchors { left: parent.left; leftMargin: 6; verticalCenter: parent.verticalCenter }
                                    text: "\u{F00E0}"
                                    font.family: Theme.nf
                                    font.pixelSize: 12
                                    color: "#0D1017"
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                property bool dragging: false
                                function setBri(e) {
                                    root.pin();
                                    const v = Math.max(0.05, Math.min(1.0, e.x / briTrack.width));
                                    Sys.setBri(v);
                                }
                                onPressed: e => { dragging = true; setBri(e); }
                                onPositionChanged: e => { if (dragging) setBri(e); }
                                onReleased: dragging = false
                            }
                        }
                    }
                }

                // Sound Volume Card (Continuous Glowing Slider)
                Rectangle {
                    width: parent.width
                    height: 60
                    radius: 16
                    color: Theme.s2
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.10)
                    clip: true

                    SpecularGlow { glowRadius: 90; maxOpacity: 0.6 }

                    Column {
                        anchors { fill: parent; margins: 10 }
                        spacing: 6

                        Item {
                            width: parent.width
                            height: 14
                            Text {
                                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                                text: "Sound"
                                font.family: Theme.ui
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                color: Theme.fg
                            }
                            Text {
                                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                                text: Sys.muted ? "Muted" : `${Math.round(Sys.vol * 100)}%`
                                font.family: Theme.mono
                                font.pixelSize: 10
                                color: Theme.sub
                            }
                        }

                        // Glowing Slider Track
                        Rectangle {
                            id: volTrack
                            width: parent.width
                            height: 20
                            radius: 10
                            color: Qt.rgba(1, 1, 1, 0.12)
                            clip: true

                            Rectangle {
                                anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                                width: Math.max(20, volTrack.width * (Sys.muted ? 0 : Sys.vol))
                                radius: 10
                                color: Theme.fg

                                Text {
                                    anchors { left: parent.left; leftMargin: 6; verticalCenter: parent.verticalCenter }
                                    text: Sys.muted ? "\u{F075F}" : "\u{F057E}"
                                    font.family: Theme.nf
                                    font.pixelSize: 12
                                    color: "#0D1017"
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                property bool dragging: false
                                function setVol(e) {
                                    root.pin();
                                    const v = Math.max(0.0, Math.min(1.0, e.x / volTrack.width));
                                    Sys.setVol(v);
                                }
                                onPressed: e => { dragging = true; setVol(e); }
                                onPositionChanged: e => { if (dragging) setVol(e); }
                                onReleased: dragging = false
                            }
                        }
                    }
                }

                // Now Playing Media Card
                Rectangle {
                    width: parent.width
                    height: 64
                    radius: 16
                    color: Theme.s2
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.10)
                    clip: true

                    SpecularGlow { glowRadius: 90; maxOpacity: 0.6 }

                    Row {
                        anchors { fill: parent; margins: 8 }
                        spacing: 10

                        // Album Artwork
                        Rectangle {
                            width: 48
                            height: 48
                            radius: 10
                            color: Qt.rgba(1, 1, 1, 0.08)
                            clip: true

                            Image {
                                anchors.fill: parent
                                source: Media.player?.trackArtUrl ?? ""
                                fillMode: Image.PreserveAspectCrop
                                visible: !!Media.player?.trackArtUrl
                            }
                            Text {
                                anchors.centerIn: parent
                                visible: !Media.player?.trackArtUrl
                                text: "\u{F0022}"
                                font.family: Theme.nf
                                font.pixelSize: 18
                                color: Theme.mute
                            }
                        }

                        // Track Title & Artist
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 48 - 72 - 20
                            spacing: 2

                            Text {
                                width: parent.width
                                elide: Text.ElideRight
                                text: Media.player?.trackTitle || "Not Playing"
                                font.family: Theme.ui
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                                color: Theme.fg
                            }
                            Text {
                                width: parent.width
                                elide: Text.ElideRight
                                text: Media.player?.trackArtist || "Daedalus Music"
                                font.family: Theme.ui
                                font.pixelSize: 10
                                color: Theme.sub
                            }
                        }

                        // Playback Controls
                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 6

                            // Prev Track Button
                            Rectangle {
                                width: 28
                                height: 28
                                radius: 14
                                color: hovPrev.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : "transparent"
                                Text {
                                    anchors.centerIn: parent
                                    text: "\u{F04AE}"
                                    font.family: Theme.nf
                                    font.pixelSize: 11
                                    color: Theme.fg
                                }
                                MouseArea {
                                    id: hovPrev
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Media.player?.previous()
                                }
                            }

                            // Play / Pause Button
                            Rectangle {
                                width: 32
                                height: 32
                                radius: 16
                                color: Theme.cyan
                                Text {
                                    anchors.centerIn: parent
                                    text: Media.player?.playbackStatus === 1 ? "\u{F03E4}" : "\u{F040A}"
                                    font.family: Theme.nf
                                    font.pixelSize: 13
                                    color: "#0D1017"
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Media.player?.togglePlaying()
                                }
                            }

                            // Next Track Button
                            Rectangle {
                                width: 28
                                height: 28
                                radius: 14
                                color: hovNext.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : "transparent"
                                Text {
                                    anchors.centerIn: parent
                                    text: "\u{F04AD}"
                                    font.family: Theme.nf
                                    font.pixelSize: 11
                                    color: Theme.fg
                                }
                                MouseArea {
                                    id: hovNext
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Media.player?.next()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Hyprland
import Quickshell.Networking
import Quickshell.Services.UPower
import Quickshell.Wayland
import qs
import qs.components
import qs.services
import qs.settings

// Profile 4: glass — Floating Top Menu Bar (macOS / visionOS liquid frosted acrylic).
// Stretches to midpoint of window gap (exclusiveZone: 36px).
// Interactive Apple logo menu, File/Edit/View/Window/Help menus, and full window title shifted to the right.
PanelWindow {
    id: root

    signal markClicked
    signal trayClicked
    signal powerClicked
    signal clockClicked
    signal wifiClicked
    signal bluetoothClicked
    signal batteryClicked
    signal deckClicked
    signal clipClicked
    signal charmsClicked
    signal bindsClicked
    signal wallsClicked

    anchors { left: true; right: true; top: true }
    implicitHeight: 44
    exclusionMode: ExclusionMode.Normal
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "glass-bar"
    WlrLayershell.exclusiveZone: 36
    color: "transparent"

    property bool quickOpen: false
    property bool deckOpen: false
    property bool calOpen: false
    property string activeMenu: "" // "" | "apple" | "file" | "edit" | "view" | "window" | "help"

    readonly property var top: ToplevelManager.activeToplevel
    readonly property var bat: UPower.displayDevice
    readonly property var wifi: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var net: wifi?.networks.values.find(n => n.connected) ?? null
    readonly property var bt: Bluetooth.defaultAdapter
    readonly property var btDev: Bluetooth.devices.values.find(d => d.connected) ?? null

    SystemClock { id: clock; precision: SystemClock.Minutes }

    mask: Region {
        item: pill
    }

    // Floating pill top menu bar (detached by 10px from edges)
    Rectangle {
        id: pill
        x: 10
        y: 6
        width: parent.width - 20
        height: 32
        radius: 16
        color: Theme.s1
        border.width: 1
        border.color: Theme.s3
        clip: true

        // Top specular hairline (light refraction catch)
        Rectangle {
            anchors { left: parent.left; right: parent.right; top: parent.top }
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            height: 1
            color: Theme.specular
            opacity: 0.8
        }

        // Left section: Apple logo + File / Edit / View / Window / Help + Divider + Full Window Title
        Row {
            id: leftSection
            anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
            spacing: 2

            // Apple Menu Button
            Rectangle {
                id: appleBtn
                width: 28
                height: 24
                radius: 6
                color: root.activeMenu === "apple" ? Qt.rgba(1, 1, 1, 0.18) : hovApple.containsMouse ? Qt.rgba(1, 1, 1, 0.10) : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "\u{F0025}" // Apple glyph
                    font.family: Theme.nf
                    font.pixelSize: 14
                    color: Theme.fg
                }

                MouseArea {
                    id: hovApple
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.activeMenu = (root.activeMenu === "apple" ? "" : "apple")
                }
            }

            // macOS Menu Buttons: File, Edit, View, Window, Help
            Repeater {
                model: [
                    { id: "file", label: "File" },
                    { id: "edit", label: "Edit" },
                    { id: "view", label: "View" },
                    { id: "window", label: "Window" },
                    { id: "help", label: "Help" }
                ]

                Rectangle {
                    id: menuBtn
                    required property var modelData
                    height: 24
                    width: menuLbl.implicitWidth + 12
                    radius: 6
                    color: root.activeMenu === modelData.id ? Qt.rgba(1, 1, 1, 0.18) : btnArea.containsMouse ? Qt.rgba(1, 1, 1, 0.10) : "transparent"

                    Text {
                        id: menuLbl
                        anchors.centerIn: parent
                        text: menuBtn.modelData.label
                        font.family: Theme.ui
                        font.pixelSize: 12
                        font.weight: root.activeMenu === menuBtn.modelData.id ? Font.Bold : Font.Normal
                        color: btnArea.containsMouse || root.activeMenu === menuBtn.modelData.id ? Theme.fg : Theme.sub
                    }

                    MouseArea {
                        id: btnArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.activeMenu = (root.activeMenu === menuBtn.modelData.id ? "" : menuBtn.modelData.id)
                    }
                }
            }

            // Divider between menu buttons and active window name
            Item {
                width: 14
                height: 24
                Rectangle {
                    anchors.centerIn: parent
                    width: 1
                    height: 14
                    color: Qt.rgba(1, 1, 1, 0.18)
                }
            }

            // Active Application Name & Full Window Title (Shifted to the right of the buttons)
            Rectangle {
                height: 24
                width: Math.max(60, Math.min(appTxt.implicitWidth + 16, pill.width - rightSection.width - 340))
                radius: 6
                color: hovTitle.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                clip: true

                Text {
                    id: appTxt
                    anchors { left: parent.left; leftMargin: 6; right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
                    text: {
                        if (!root.top || !root.top.title) return "Finder";
                        return root.top.title.trim();
                    }
                    font.family: Theme.ui
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    color: Theme.fg
                    elide: Text.ElideRight
                }

                MouseArea {
                    id: hovTitle
                    anchors.fill: parent
                    hoverEnabled: true
                }
            }
        }

        // Right section: Battery pill, Wi-Fi, Bluetooth, Spotlight, Control Center, Clock
        Row {
            id: rightSection
            anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
            spacing: 4

            // Battery Pill & Charging Indicator
            Row {
                id: batSection
                spacing: 4
                anchors.verticalCenter: parent.verticalCenter

                // Charging Bolt indicator beside the battery bar (bigger, glowing cyan)
                Text {
                    id: chgBolt
                    visible: root.bat?.state === UPowerDeviceState.Charging
                    text: "\u{F0E7}"
                    font.family: Theme.nf
                    font.pixelSize: 14
                    color: Theme.cyan
                    anchors.verticalCenter: parent.verticalCenter

                    // Subtle breathing pulse animation while charging
                    SequentialAnimation on opacity {
                        running: chgBolt.visible
                        loops: Animation.Infinite
                        NumberAnimation { from: 0.6; to: 1.0; duration: 900; easing.type: Easing.InOutQuad }
                        NumberAnimation { from: 1.0; to: 0.6; duration: 900; easing.type: Easing.InOutQuad }
                    }
                }

                Rectangle {
                    id: batPill
                    height: 22
                    width: batRow.implicitWidth + 14
                    radius: 11
                    color: hovBat.containsMouse ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1
                    border.color: Theme.s3

                    Row {
                        id: batRow
                        anchors.centerIn: parent
                        spacing: 6

                        // Continuous mini battery horizontal level bar
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 20
                            height: 10
                            radius: 3
                            color: Qt.rgba(255, 255, 255, 0.10)
                            border.width: 1
                            border.color: Qt.rgba(255, 255, 255, 0.25)
                            clip: true

                            Rectangle {
                                anchors { left: parent.left; top: parent.top; bottom: parent.bottom; margins: 1 }
                                width: Math.max(2, (parent.width - 2) * Math.min(1, (root.bat?.percentage ?? 1)))
                                radius: 2
                                color: (root.bat?.percentage ?? 1) <= 0.15 ? Theme.red : root.bat?.state === UPowerDeviceState.Charging ? Theme.cyan : Theme.fg

                                Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: `${Math.round((root.bat?.percentage ?? 1) * 100)}%`
                            font.family: Theme.ui
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            color: Theme.fg
                        }
                    }

                    MouseArea {
                        id: hovBat
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.batteryClicked()
                    }
                }
            }

            // Wi-Fi Icon Button
            Rectangle {
                width: 26
                height: 22
                radius: 6
                color: hovWifi.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: Networking.wifiEnabled ? (root.net ? "\u{F05A9}" : "\u{F05AA}") : "\u{F05AA}"
                    font.family: Theme.nf
                    font.pixelSize: 12
                    color: Networking.wifiEnabled && root.net ? Theme.fg : Theme.mute
                }
                MouseArea {
                    id: hovWifi
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.wifiClicked()
                }
            }

            // Bluetooth Icon Button
            Rectangle {
                width: 26
                height: 22
                radius: 6
                color: hovBt.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: root.bt?.enabled ? "\u{F00AF}" : "\u{F00B2}"
                    font.family: Theme.nf
                    font.pixelSize: 12
                    color: root.bt?.enabled ? Theme.fg : Theme.mute
                }
                MouseArea {
                    id: hovBt
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.bluetoothClicked()
                }
            }

            // Spotlight Trigger Button
            Rectangle {
                width: 26
                height: 22
                radius: 6
                color: hovSpot.containsMouse ? Qt.rgba(1, 1, 1, 0.16) : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "\u{F002}" // Magnifying glass
                    font.family: Theme.nf
                    font.pixelSize: 11
                    color: Theme.fg
                }
                MouseArea {
                    id: hovSpot
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.markClicked()
                }
            }

            // Control Center Toggle Button
            Rectangle {
                width: 26
                height: 22
                radius: 6
                color: root.quickOpen ? Qt.rgba(1, 1, 1, 0.20) : hovQuick.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "\u{F013}" // Sliders / toggles
                    font.family: Theme.nf
                    font.pixelSize: 12
                    color: root.quickOpen ? Theme.cyan : Theme.fg
                }
                MouseArea {
                    id: hovQuick
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.trayClicked()
                }
            }

            // Clock / Date Button (ddd d MMM h:mm a)
            Rectangle {
                height: 22
                width: clkTxt.implicitWidth + 10
                radius: 6
                color: hovClk.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"

                Text {
                    id: clkTxt
                    anchors.centerIn: parent
                    text: Qt.formatDateTime(clock.date, "ddd d MMM  h:mm AP")
                    font.family: Theme.ui
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    color: Theme.fg
                }

                MouseArea {
                    id: hovClk
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.clockClicked()
                }
            }
        }
    }

    // Unified macOS Dropdown Menu Popover
    PopupWindow {
        id: menuPop
        visible: root.activeMenu !== ""
        anchor.item: pill
        anchor.rect: {
            if (root.activeMenu === "apple") return Qt.rect(8, pill.height + 4, 1, 1);
            if (root.activeMenu === "file") return Qt.rect(42, pill.height + 4, 1, 1);
            if (root.activeMenu === "edit") return Qt.rect(82, pill.height + 4, 1, 1);
            if (root.activeMenu === "view") return Qt.rect(124, pill.height + 4, 1, 1);
            if (root.activeMenu === "window") return Qt.rect(172, pill.height + 4, 1, 1);
            if (root.activeMenu === "help") return Qt.rect(234, pill.height + 4, 1, 1);
            return Qt.rect(8, pill.height + 4, 1, 1);
        }
        anchor.edges: Edges.Top | Edges.Left
        anchor.gravity: Edges.Bottom | Edges.Left
        implicitWidth: 220
        implicitHeight: menuCard.height
        color: "transparent"

        Rectangle {
            id: menuCard
            width: 220
            height: menuCol.height + 16
            radius: 14
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
                opacity: 0.7
            }

            Column {
                id: menuCol
                x: 8
                y: 8
                width: parent.width - 16
                spacing: 2

                Repeater {
                    model: {
                        if (root.activeMenu === "apple") {
                            return [
                                { label: "About Daedalus", icon: "\u{F0025}", action: () => Quickshell.execDetached(["kitty", "-e", "fastfetch"]) },
                                { isDiv: true },
                                { label: "System Preferences…", icon: "\u{F0493}", action: () => root.powerClicked() },
                                { isDiv: true },
                                { label: "Sleep", icon: "\u{F0060}", action: () => Quickshell.execDetached(["systemctl", "suspend"]) },
                                { label: "Restart…", icon: "\u{F0450}", action: () => Quickshell.execDetached(["systemctl", "reboot"]) },
                                { label: "Shut Down…", icon: "\u{F0425}", action: () => Quickshell.execDetached(["systemctl", "poweroff"]) },
                                { isDiv: true },
                                { label: "Lock Screen", icon: "\u{F033E}", badge: "⌃⌘Q", action: () => Quickshell.execDetached(["rice", "lock"]) }
                            ];
                        }
                        if (root.activeMenu === "file") {
                            return [
                                { label: "New Terminal Window", icon: "\u{F012C}", badge: "⌘T", action: () => Quickshell.execDetached(["kitty"]) },
                                { label: "New File Manager", icon: "\u{F024B}", badge: "⌘N", action: () => Quickshell.execDetached(["thunar"]) },
                                { label: "Spotlight Search…", icon: "\u{F002}", badge: "⌘Space", action: () => root.markClicked() },
                                { isDiv: true },
                                { label: "Take Screenshot", icon: "\u{F0100}", badge: "Print", action: () => Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.global(\"shell:shot\")"]) },
                                { isDiv: true },
                                { label: "Close Active Window", icon: "\u{F0156}", badge: "⌘W", action: () => Quickshell.execDetached(["hyprctl", "dispatch", "killactive"]) }
                            ];
                        }
                        if (root.activeMenu === "edit") {
                            return [
                                { label: "Clipboard History", icon: "\u{F00EC}", badge: "⌘V", action: () => root.clipClicked() },
                                { label: "Emoji & Symbols", icon: "\u{F04A0}", badge: "⌘.", action: () => root.charmsClicked() }
                            ];
                        }
                        if (root.activeMenu === "view") {
                            return [
                                { label: "Toggle Deck Dashboard", icon: "\u{F00A1}", badge: "Super", action: () => root.deckClicked() },
                                { label: "Toggle Desktop Bento", icon: "\u{F000E}", action: () => { Theme.state.home = !Theme.state.home; } },
                                { isDiv: true },
                                { label: "Wallpaper Picker…", icon: "\u{F022B}", badge: "⇧⌘W", action: () => root.wallsClicked() },
                                { label: "Game Mode (No Blur)", icon: "\u{F07B0}", action: () => { Rules.store.game = !Rules.store.game; } }
                            ];
                        }
                        if (root.activeMenu === "window") {
                            return [
                                { label: "Toggle Fullscreen", icon: "\u{F0210}", badge: "⌘F", action: () => Quickshell.execDetached(["hyprctl", "dispatch", "fullscreen"]) },
                                { label: "Toggle Floating", icon: "\u{F031E}", badge: "⌘Space", action: () => Quickshell.execDetached(["hyprctl", "dispatch", "togglefloating"]) },
                                { label: "Pin Window on Top", icon: "\u{F0403}", action: () => Quickshell.execDetached(["hyprctl", "dispatch", "pin"]) },
                                { isDiv: true },
                                { label: "Close Window", icon: "\u{F0156}", badge: "⌘Q", action: () => Quickshell.execDetached(["hyprctl", "dispatch", "killactive"]) }
                            ];
                        }
                        if (root.activeMenu === "help") {
                            return [
                                { label: "Daedalus Shortcuts…", icon: "\u{F02FD}", badge: "⌘?", action: () => root.bindsClicked() },
                                { label: "Rice Preferences…", icon: "\u{F0493}", badge: "⌘I", action: () => root.powerClicked() }
                            ];
                        }
                        return [];
                    }

                    Item {
                        required property var modelData
                        width: parent.width
                        height: modelData.isDiv ? 7 : 26

                        Rectangle {
                            visible: !!parent.modelData.isDiv
                            anchors.centerIn: parent
                            width: parent.width - 8
                            height: 1
                            color: Qt.rgba(1, 1, 1, 0.10)
                        }

                        Rectangle {
                            visible: !parent.modelData.isDiv
                            anchors.fill: parent
                            radius: 6
                            color: itemArea.containsMouse ? Theme.cyan : "transparent"

                            Item {
                                anchors { fill: parent; leftMargin: 8; rightMargin: 8 }

                                Row {
                                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                                    spacing: 8
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: parent.parent.parent.parent.modelData.icon || ""
                                        font.family: Theme.nf
                                        font.pixelSize: 12
                                        color: itemArea.containsMouse ? "#0D1017" : Theme.cyan
                                    }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: parent.parent.parent.parent.modelData.label || ""
                                        font.family: Theme.ui
                                        font.pixelSize: 12
                                        font.weight: Font.Medium
                                        color: itemArea.containsMouse ? "#0D1017" : Theme.fg
                                    }
                                }

                                Text {
                                    visible: !!parent.parent.parent.modelData.badge
                                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                                    text: parent.parent.parent.modelData.badge || ""
                                    font.family: Theme.ui
                                    font.pixelSize: 11
                                    color: itemArea.containsMouse ? "#0D1017" : Theme.mute
                                }
                            }

                            MouseArea {
                                id: itemArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    const act = parent.parent.modelData.action;
                                    root.activeMenu = "";
                                    if (act) act();
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

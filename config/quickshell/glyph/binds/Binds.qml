import QtQuick
import Quickshell
import Quickshell.Wayland
import qs
import qs.components

// Binds: Native Nothing OS-styled keyboard shortcuts helper panel.
// Toggled via Super+Shift+/ (or Super+?).
PanelWindow {
    id: root

    property bool shown: false
    property real t: shown ? 1 : 0
    Behavior on t { NumberAnimation { duration: Theme.t; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.glide } }

    function open() {
        input.text = "";
        tab = 0;
        sel = 0;
        shown = true;
    }
    function close() { shown = false; }
    function toggle() { shown ? close() : open(); }

    readonly property var tabs: ["ALL", "APPS", "WINDOW", "WORKSPACES", "SYSTEM"]
    property int tab: 0
    property int sel: 0
    readonly property string query: input.text.toLowerCase().trim()

    readonly property var allBinds: [
        // Apps & System Panels
        { cat: "APPS", key: "Super (Tap)", desc: "Rice Deck & Left Bar (Dashboard)", icon: "\u{F0150}" },
        { cat: "APPS", key: "Super + Space", desc: "App Launcher (Quickshell)", icon: "\u{F007A}" },
        { cat: "APPS", key: "Super + T", desc: "Terminal (Kitty)", icon: "\u{F0128}" },
        { cat: "APPS", key: "Super + E", desc: "File Manager (Thunar)", icon: "\u{F0214}" },
        { cat: "APPS", key: "Super + B", desc: "Web Browser (Chromium)", icon: "\u{F022D}" },
        { cat: "APPS", key: "Super + C", desc: "Code Editor (VS Code)", icon: "\u{F0169}" },
        { cat: "APPS", key: "Super + N", desc: "Notion", icon: "\u{F009A}" },
        { cat: "APPS", key: "Super + M", desc: "Music Player", icon: "\u{F075A}" },
        { cat: "APPS", key: "Ctrl + Alt + V", desc: "Audio Settings (Pavucontrol)", icon: "\u{F057E}" },

        // Window Actions
        { cat: "WINDOW", key: "Super + Q", desc: "Close Active Window", icon: "\u{F0156}" },
        { cat: "WINDOW", key: "Super + Shift + T", desc: "Toggle Floating Window", icon: "\u{F0795}" },
        { cat: "WINDOW", key: "Super + Shift + F", desc: "Toggle Fullscreen (Maximized)", icon: "\u{F0504}" },
        { cat: "WINDOW", key: "Super + F", desc: "Toggle Fullscreen (True)", icon: "\u{F0504}" },
        { cat: "WINDOW", key: "Super + P", desc: "Toggle Pseudo-Tile", icon: "\u{F031E}" },
        { cat: "WINDOW", key: "Super + J", desc: "Toggle Layout Split (Dwindle)", icon: "\u{F078E}" },
        { cat: "WINDOW", key: "Super + Left/Right/Up/Down", desc: "Focus Window Direction", icon: "\u{F0054}" },
        { cat: "WINDOW", key: "Super + Shift + Arrows", desc: "Move Window Direction", icon: "\u{F0055}" },
        { cat: "WINDOW", key: "Super + LMB (Left Click)", desc: "Drag / Move Window", icon: "\u{F037A}" },
        { cat: "WINDOW", key: "Super + RMB (Right Click)", desc: "Resize Window Drag", icon: "\u{F037A}" },
        { cat: "WINDOW", key: "Super + [ - / = ]", desc: "Resize Horizontally", icon: "\u{F004E}" },
        { cat: "WINDOW", key: "Super + Shift + [ - / = ]", desc: "Resize Vertically", icon: "\u{F004F}" },
        { cat: "WINDOW", key: "Super + Alt + Arrows", desc: "Resize Directional", icon: "\u{F004D}" },

        // Workspaces
        { cat: "WORKSPACES", key: "Super + [1 - 0]", desc: "Switch to Workspace 1-10", icon: "\u{F030C}" },
        { cat: "WORKSPACES", key: "Super + Shift + [1 - 0]", desc: "Move Window to Workspace 1-10", icon: "\u{F0056}" },
        { cat: "WORKSPACES", key: "Super + S", desc: "Toggle Special Workspace (Magic)", icon: "\u{F0079}" },
        { cat: "WORKSPACES", key: "Super + Shift + S", desc: "Move Window to Special Workspace", icon: "\u{F0079}" },
        { cat: "WORKSPACES", key: "Super + D", desc: "Peek Desktop (Toggle Clean Desktop)", icon: "\u{F0150}" },
        { cat: "WORKSPACES", key: "Super + Mouse Scroll", desc: "Next / Previous Workspace", icon: "\u{F078F}" },

        // System & Rice
        { cat: "SYSTEM", key: "Super + Shift + /", desc: "This Keybinds Helper", icon: "\u{F02D7}" },
        { cat: "SYSTEM", key: "Super + Shift + Q", desc: "Power Menu", icon: "\u{F0425}" },
        { cat: "SYSTEM", key: "Super + Escape", desc: "Power Menu (Alternative)", icon: "\u{F0425}" },
        { cat: "SYSTEM", key: "Super + L", desc: "Lock Screen", icon: "\u{F033E}" },
        { cat: "SYSTEM", key: "Super + V", desc: "Clipboard History", icon: "\u{F00EE}" },
        { cat: "SYSTEM", key: "Super + .", desc: "Emojis, Kaomoji & Symbols", icon: "\u{F0503}" },
        { cat: "SYSTEM", key: "Super + A", desc: "Quick Settings", icon: "\u{F0493}" },
        { cat: "SYSTEM", key: "Super + I", desc: "Rice Settings & Prefs", icon: "\u{F0493}" },
        { cat: "SYSTEM", key: "Super + Shift + W", desc: "Wallpaper Picker", icon: "\u{F03E9}" },
        { cat: "SYSTEM", key: "Super + Alt + P", desc: "VPN Panel (Clash Verge)", icon: "\u{F058F}" },
        { cat: "SYSTEM", key: "Print", desc: "Screenshot Tool & Editor", icon: "\u{F0100}" },
        { cat: "SYSTEM", key: "Super + Alt + R", desc: "Screen Recording", icon: "\u{F054B}" },
        { cat: "SYSTEM", key: "Super + Shift + C", desc: "Color Picker (Hyprpicker)", icon: "\u{F03D8}" },
        { cat: "SYSTEM", key: "Super + Shift + U", desc: "Kill Window (hyprctl kill)", icon: "\u{F0156}" },

        // Media & Hardware
        { cat: "SYSTEM", key: "Volume Up / Down", desc: "Adjust Volume (+/- 5%)", icon: "\u{F057E}" },
        { cat: "SYSTEM", key: "Volume Mute", desc: "Toggle Mute", icon: "\u{F0581}" },
        { cat: "SYSTEM", key: "Mic Mute", desc: "Toggle Mic Mute", icon: "\u{F036C}" },
        { cat: "SYSTEM", key: "Brightness Up / Down", desc: "Adjust Screen Brightness", icon: "\u{F0599}" },
        { cat: "SYSTEM", key: "Media Play / Pause", desc: "Play or Pause Track", icon: "\u{F040A}" },
        { cat: "SYSTEM", key: "Media Next / Prev", desc: "Skip to Next / Prev Track", icon: "\u{F04AD}" }
    ]

    readonly property var filteredBinds: allBinds.filter(function(b) {
        var matchTab = (tab === 0) || (b.cat === tabs[tab]);
        if (!matchTab) return false;
        if (!query) return true;
        return b.key.toLowerCase().includes(query) || b.desc.toLowerCase().includes(query);
    })

    onQueryChanged: sel = 0
    onTabChanged: sel = 0
    onVisibleChanged: if (visible) input.forceActiveFocus()

    visible: t > 0
    anchors { left: true; right: true; top: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "glyph-binds"

    Rectangle {
        anchors.fill: parent
        color: Theme.scrim
        opacity: root.t
        MouseArea { anchors.fill: parent; onClicked: root.close() }
    }

    Stage {
        id: stage

        Rectangle {
            id: panel
            anchors.centerIn: parent
            width: 860
            height: Math.min(stage.height - 140, 680)
            opacity: root.t
            radius: Theme.corner(44)
            color: Theme.s1
            border { width: 1; color: Theme.s2 }
            MouseArea { anchors.fill: parent } // click inside doesn't close

            Column {
                anchors { fill: parent; margins: 32 }
                spacing: 20

                // Header: Title + Dot indicator + Search bar
                Row {
                    width: parent.width
                    height: 52
                    spacing: 16

                    Rectangle {
                        width: 140
                        height: 50
                        radius: Theme.corner(25)
                        color: Theme.s2
                        anchors.verticalCenter: parent.verticalCenter

                        Row {
                            anchors.centerIn: parent
                            spacing: 8
                            Rectangle {
                                width: 8; height: 8; radius: 4
                                color: Theme.accent
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: "BINDS"
                                font { family: Theme.mono; pixelSize: 14; weight: Font.Bold }
                                color: Theme.fg
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }

                    // Search input
                    Rectangle {
                        id: searchBox
                        width: parent.width - 156
                        height: 50
                        radius: Theme.corner(25)
                        color: Theme.s2
                        anchors.verticalCenter: parent.verticalCenter

                        Icon {
                            id: lens
                            x: 20
                            anchors.verticalCenter: parent.verticalCenter
                            text: "\u{F0349}"
                            color: Theme.grey
                            font.pixelSize: 18
                        }

                        TextInput {
                            id: input
                            anchors {
                                left: lens.right
                                leftMargin: 12
                                right: countLabel.left
                                rightMargin: 12
                                verticalCenter: parent.verticalCenter
                            }
                            font { family: Theme.ui; pixelSize: 16 }
                            color: Theme.fg
                            selectionColor: Theme.s3
                            clip: true

                            cursorDelegate: Rectangle {
                                width: 2
                                color: Theme.accent
                                Timer { running: input.activeFocus; interval: 500; repeat: true; onTriggered: parent.opacity = 1 - parent.opacity }
                            }

                            Text {
                                visible: !input.text
                                text: "Search keybinds or actions..."
                                font: input.font
                                color: Theme.mute
                            }

                            Keys.onPressed: function(e) {
                                if (e.key === Qt.Key_Escape) root.close();
                                else if (e.key === Qt.Key_Tab) root.tab = (root.tab + 1) % root.tabs.length;
                                else if (e.key === Qt.Key_Backtab) root.tab = (root.tab + root.tabs.length - 1) % root.tabs.length;
                                else if (e.key === Qt.Key_Down) bindsList.flick(0, -200);
                                else if (e.key === Qt.Key_Up) bindsList.flick(0, 200);
                            }
                        }

                        Lb {
                            id: countLabel
                            anchors { right: parent.right; rightMargin: 20; verticalCenter: parent.verticalCenter }
                            text: root.filteredBinds.length + " binds"
                            color: Theme.grey
                            px: 12
                        }
                    }
                }

                // Category Chips
                Row {
                    spacing: 10
                    Repeater {
                        model: root.tabs
                        Rectangle {
                            required property string modelData
                            required property int index
                            readonly property bool active: root.tab === index
                            width: chipText.width + 24
                            height: 32
                            radius: Theme.corner(16)
                            color: active ? Theme.fg : Theme.s2

                            Text {
                                id: chipText
                                anchors.centerIn: parent
                                text: parent.modelData
                                font { family: Theme.mono; pixelSize: 11; weight: Font.Medium }
                                color: parent.active ? Theme.ink : Theme.grey
                            }

                            TapHandler { onTapped: root.tab = parent.index }
                            HoverHandler { cursorShape: Qt.PointingHandCursor }
                        }
                    }
                }

                // Divider dots
                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.s2
                }

                // List of Keybinds
                ListView {
                    id: bindsList
                    width: parent.width
                    height: panel.height - 220
                    clip: true
                    spacing: 8
                    model: root.filteredBinds

                    delegate: Rectangle {
                        id: rowCard
                        required property var modelData
                        required property int index
                        width: bindsList.width
                        height: 48
                        radius: Theme.corner(18)
                        color: Theme.s2
                        border { width: 1; color: Theme.s3 }

                        Row {
                            anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
                            spacing: 16

                            // Category icon
                            Icon {
                                text: rowCard.modelData.icon || "\u{F0128}"
                                font.pixelSize: 18
                                color: Theme.accent
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            // Key combination capsule
                            Rectangle {
                                width: keyText.width + 20
                                height: 30
                                radius: Theme.corner(12)
                                color: Theme.s1
                                border { width: 1; color: Theme.s3 }
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    id: keyText
                                    anchors.centerIn: parent
                                    text: rowCard.modelData.key
                                    font { family: Theme.mono; pixelSize: 12; weight: Font.Bold }
                                    color: Theme.fg
                                }
                            }

                            // Description
                            Text {
                                text: rowCard.modelData.desc
                                font { family: Theme.ui; pixelSize: 15; weight: Font.Medium }
                                color: Theme.fg
                                anchors.verticalCenter: parent.verticalCenter
                                elide: Text.ElideRight
                                width: rowCard.width - keyText.width - 150
                            }

                            // Category tag pill
                            Rectangle {
                                width: tagText.width + 14
                                height: 22
                                radius: Theme.corner(11)
                                color: "transparent"
                                border { width: 1; color: Theme.s3 }
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    id: tagText
                                    anchors.centerIn: parent
                                    text: rowCard.modelData.cat
                                    font { family: Theme.mono; pixelSize: 10 }
                                    color: Theme.grey
                                }
                            }
                        }
                    }

                    // Empty state
                    Lb {
                        anchors.centerIn: parent
                        visible: root.filteredBinds.length === 0
                        text: "No matching keybindings"
                        color: Theme.grey
                        px: 16
                    }
                }

                // Footer hint
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 24
                    Lb { text: "esc close"; color: Theme.mute; px: 11 }
                    Lb { text: "·"; color: Theme.s3; px: 11 }
                    Lb { text: "tab switch categories"; color: Theme.mute; px: 11 }
                    Lb { text: "·"; color: Theme.s3; px: 11 }
                    Lb { text: "type to filter"; color: Theme.mute; px: 11 }
                }
            }
        }
    }
}

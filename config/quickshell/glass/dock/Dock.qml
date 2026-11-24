import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs
import qs.components
import qs.settings

// Profile 4: glass — The macOS Floating Frosted Acrylic Dock.
// Dynamically replicates windows in the exact order of their workspaces.
// Robust auto-hide behavior with parabolic magnification.
PanelWindow {
    id: root

    signal launcherRequested
    signal quickRequested
    signal settingsRequested

    anchors { bottom: true; left: true; right: true }
    implicitHeight: 90
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "glass-dock"

    property bool revealed: false
    function show() { hideTimer.stop(); revealed = true; }
    function hide() { hideTimer.restart(); }

    Timer {
        id: hideTimer
        interval: 320
        onTriggered: root.revealed = false
    }

    // Failsafe watchdog timer: guarantees dock dismisses if mouse leaves surface without leave event
    Timer {
        id: watchdog
        interval: 1800
        repeat: true
        running: root.revealed
        onTriggered: {
            if (!dockHoverArea.containsMouse && !triggerHover.hovered) {
                root.revealed = false;
            }
        }
    }

    // Bottom edge hover trigger strip (4px height along screen bottom)
    Item {
        id: triggerStrip
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 6

        HoverHandler {
            id: triggerHover
            onHoveredChanged: {
                if (hovered) {
                    root.show();
                }
            }
        }
    }

    // Generous bounding item for click/hover region when revealed
    Item {
        id: shelfHitArea
        anchors.horizontalCenter: shelf.horizontalCenter
        anchors.bottom: parent.bottom
        width: shelf.width + 80
        height: shelf.height + 34
    }

    // Dynamic Wayland layer click masking
    mask: Region {
        item: root.revealed ? shelfHitArea : triggerStrip
    }

    // Icon lookup helper with common fallback mappings
    function getAppIcon(cls) {
        if (!cls) return Quickshell.iconPath("application-x-executable", "application-x-executable");
        const c = cls.toLowerCase();
        const map = {
            "kitty": "utilities-terminal",
            "foot": "utilities-terminal",
            "agy-term": "utilities-terminal",
            "thunar": "system-file-manager",
            "firefox": "firefox",
            "chromium": "chromium",
            "google-chrome": "google-chrome",
            "code": "visual-studio-code",
            "vscodium": "vscodium",
            "obsidian": "obsidian",
            "md.obsidian.obsidian": "obsidian",
            "antigravity": "antigravity",
            "spotify": "spotify",
            "discord": "discord",
            "webcord": "discord",
            "vesktop": "discord",
            "gimp": "gimp",
            "inkscape": "inkscape",
            "vlc": "vlc",
            "mpv": "mpv"
        };
        const iconName = map[c] || c;
        return Quickshell.iconPath(iconName, "application-x-executable");
    }

    // Dynamic workspace-ordered window model
    readonly property var openWindows: {
        const tops = Hyprland.toplevels.values.filter(t => {
            const wsId = t.workspace?.id ?? 0;
            const cls = (t.lastIpcObject?.class ?? "").toLowerCase();
            return wsId > 0 && cls !== "" && !cls.includes("quickshell");
        });

        // Sort ascending strictly by workspace.id, then by window title
        tops.sort((a, b) => {
            const wa = a.workspace?.id ?? 99;
            const wb = b.workspace?.id ?? 99;
            if (wa !== wb) return wa - wb;
            return (a.title ?? "").localeCompare(b.title ?? "");
        });

        return tops.map(t => ({
            type: "window",
            address: t.address,
            title: t.title || t.lastIpcObject?.class || "App",
            wsId: t.workspace?.id ?? 1,
            wsName: t.workspace?.name ?? `${t.workspace?.id ?? 1}`,
            cls: t.lastIpcObject?.class ?? "",
            icon: root.getAppIcon(t.lastIpcObject?.class),
            focused: t.address === Hyprland.focusedToplevel?.address,
            onActiveWs: (t.workspace?.id ?? 0) === (Hyprland.focusedMonitor?.activeWorkspace?.id ?? -1)
        }));
    }

    // Fallback default launcher items when no windows are open
    readonly property var fallbackApps: [
        { type: "launch", name: "Files", icon: root.getAppIcon("thunar"), exec: ["thunar"] },
        { type: "launch", name: "Terminal", icon: root.getAppIcon("kitty"), exec: ["kitty"] },
        { type: "launch", name: "Browser", icon: root.getAppIcon("firefox"), exec: ["firefox"] },
        { type: "launch", name: "Code", icon: root.getAppIcon("code"), exec: ["code"] },
        { type: "launch", name: "Notes", icon: root.getAppIcon("obsidian"), exec: ["obsidian"] }
    ]

    function activateItem(item) {
        root.revealed = false; // Dismiss dock immediately upon app launch/focus
        if (item.action === "launcher") {
            root.launcherRequested();
            return;
        }
        if (item.action === "quick") {
            root.quickRequested();
            return;
        }
        if (item.action === "settings") {
            root.settingsRequested();
            return;
        }
        if (item.action === "files") {
            Quickshell.execDetached(["thunar"]);
            return;
        }
        if (item.type === "window" && item.address) {
            Hyprland.dispatch(`hl.dsp.focus({ window = "address:0x${item.address}" })`);
            return;
        }
        if (item.exec) {
            Quickshell.execDetached(item.exec);
        }
    }

    // Broad mouse area for smooth tracking and leave detection
    MouseArea {
        id: dockHoverArea
        anchors.fill: shelfHitArea
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onPositionChanged: (mouse) => {
            hideTimer.stop();
            shelf.mouseXInShelf = shelf.mapFromItem(dockHoverArea, mouse.x, mouse.y).x;
        }
        onExited: {
            shelf.mouseXInShelf = -9999;
            hideTimer.restart();
        }
    }

    // Floating translucent frosted glass shelf
    Rectangle {
        id: shelf
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.revealed ? 8 : -height - 24
        Behavior on anchors.bottomMargin { NumberAnimation { duration: 240; easing.type: Easing.OutQuad } }

        width: dockRow.width + 24
        height: 56
        radius: 18
        color: Theme.s1
        border.width: 1
        border.color: Theme.s3
        clip: false

        // Top-edge specular hairline
        Rectangle {
            anchors { left: parent.left; right: parent.right; top: parent.top }
            anchors.margins: 6
            height: 1
            color: Theme.specular
            opacity: 0.8
            radius: 18
        }

        // Dynamic Specular Cursor Glow along the shelf
        SpecularGlow {
            glowRadius: 100
            maxOpacity: 0.65
        }

        property real mouseXInShelf: -9999
        property bool isHovered: dockHoverArea.containsMouse

        Row {
            id: dockRow
            anchors.centerIn: parent
            spacing: 6

            // Left Section: Finder / Spotlight
            DockIcon {
                itemData: ({ name: "Finder", icon: Quickshell.iconPath("system-file-manager", "system-file-manager"), action: "files" })
                shelfObj: shelf
                onTriggered: root.activateItem(itemData)
            }
            DockIcon {
                itemData: ({ name: "Spotlight", icon: Quickshell.iconPath("preferences-system-search", "preferences-system-search"), action: "launcher" })
                shelfObj: shelf
                onTriggered: root.activateItem(itemData)
            }

            // Divider between system tools and open workspace windows
            Rectangle {
                width: 1
                height: 32
                anchors.verticalCenter: parent.verticalCenter
                color: Qt.rgba(255, 255, 255, 0.15)
                radius: 1
            }

            // Middle Section: Dynamic Open Windows in Workspace Order (or fallback if empty)
            Repeater {
                model: root.openWindows.length > 0 ? root.openWindows : root.fallbackApps

                DockIcon {
                    required property var modelData
                    itemData: modelData
                    shelfObj: shelf
                    onTriggered: root.activateItem(itemData)
                }
            }

            // Divider between workspace windows and control tools
            Rectangle {
                width: 1
                height: 32
                anchors.verticalCenter: parent.verticalCenter
                color: Qt.rgba(255, 255, 255, 0.15)
                radius: 1
            }

            // Right Section: Settings & Control Center
            DockIcon {
                itemData: ({ name: "Settings", icon: Quickshell.iconPath("preferences-system", "preferences-system"), action: "settings" })
                shelfObj: shelf
                onTriggered: root.activateItem(itemData)
            }
            DockIcon {
                itemData: ({ name: "Control Center", icon: Quickshell.iconPath("preferences-desktop", "preferences-desktop"), action: "quick" })
                shelfObj: shelf
                onTriggered: root.activateItem(itemData)
            }
        }
    }

    // DockIcon Component with parabolic magnification and workspace indicator dots
    component DockIcon: Item {
        id: dIcon
        property var itemData
        property var shelfObj

        width: 44
        height: 46

        // Parabolic magnification physics
        readonly property real centerX: shelfObj.mapFromItem(dIcon, width / 2, 0).x
        readonly property real dist: Math.abs(shelfObj.mouseXInShelf - centerX)
        readonly property real span: 110

        readonly property real factor: {
            if (!shelfObj.isHovered || dist >= span) return 0.0;
            return Math.cos((Math.PI * dist) / (2 * span));
        }

        readonly property real iconScale: 1.0 + 0.38 * factor
        readonly property real yShift: -14 * factor

        signal triggered()

        Item {
            anchors.centerIn: parent
            width: 38
            height: 38
            scale: dIcon.iconScale
            y: dIcon.yShift

            Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }
            Behavior on y { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }

            Image {
                anchors.fill: parent
                source: dIcon.itemData.icon || Quickshell.iconPath("application-x-executable", "application-x-executable")
                sourceSize: Qt.size(48, 48)
                fillMode: Image.PreserveAspectFit
                smooth: true
            }

            MouseArea {
                id: iconArea
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: dIcon.triggered()
            }
        }

        // Workspace Indicator Dot beneath running window
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: -2
            anchors.horizontalCenter: parent.horizontalCenter
            width: dIcon.itemData.type === "window" && dIcon.itemData.focused ? 8 : 4
            height: 4
            radius: 2
            color: dIcon.itemData.type === "window" && dIcon.itemData.onActiveWs ? Theme.cyan : Qt.rgba(255, 255, 255, 0.65)
            visible: dIcon.itemData.type === "window"

            Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
        }

        // Hover tooltip pill displaying Window Title and Workspace Number
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.top
            anchors.bottomMargin: 8
            visible: iconArea.containsMouse && (dIcon.itemData.title || dIcon.itemData.name)
            width: tipText.implicitWidth + 14
            height: 22
            radius: 11
            color: Qt.rgba(13 / 255, 16 / 255, 23 / 255, 0.90)
            border.width: 1
            border.color: Theme.s3

            Text {
                id: tipText
                anchors.centerIn: parent
                text: dIcon.itemData.type === "window" ? `[${dIcon.itemData.wsName}] ${dIcon.itemData.title}` : (dIcon.itemData.name || "")
                font.family: Theme.ui
                font.pixelSize: 10
                font.weight: Font.Medium
                color: Theme.fg
                elide: Text.ElideRight
            }
        }
    }
}

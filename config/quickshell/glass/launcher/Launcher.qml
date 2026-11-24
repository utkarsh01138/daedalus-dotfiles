import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs
import qs.components
import qs.settings

// Profile 4: glass — Spotlight Search (macOS / visionOS liquid frosted acrylic).
// Supports Applications, Commands (> cmd), Window Switcher, and Math/Conversions (qalc).
PanelWindow {
    id: root

    property bool open: false
    property string query: input.text
    property int sel: 0
    property string calcResult: ""
    property int mode: 0 // 0: Apps, 1: Commands, 2: Windows, 3: Calculator

    readonly property var modeLabels: [
        { id: 0, label: "Apps", icon: "\u{F000E}" },
        { id: 1, label: "Commands", icon: "\u{F012C}" },
        { id: 2, label: "Windows", icon: "\u{F031E}" },
        { id: 3, label: "Calculator", icon: "\u{F01EC}" }
    ]

    function toggle() {
        if (open) close();
        else show();
    }

    function show() {
        open = true;
        sel = 0;
        input.text = "";
        calcResult = "";
        input.forceActiveFocus();
    }

    function close() {
        open = false;
        input.text = "";
    }

    visible: t > 0
    anchors { left: true; right: true; top: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "glass-launcher"

    // Entrance animation curve (macosSpring, 0.16, 1, 0.3, 1)
    property real t: open ? 1 : 0
    Behavior on t { NumberAnimation { duration: Theme.t; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.glide } }

    // Click masking: background scrim intercepts clicks when open, 100% pass-through when closed
    mask: Region {
        item: root.open ? scrim : null
    }

    function icon(name) {
        return Quickshell.iconPath(name || "application-x-executable", "application-x-executable");
    }

    // Collect system applications from DesktopEntries
    property var apps: []
    Timer {
        id: appsT
        interval: 300
        running: true
        onTriggered: {
            root.apps = DesktopEntries.applications.values.filter(e => !e.noDisplay).map(e => ({
                id: e.id,
                name: e.name,
                generic: e.genericName || "",
                desc: e.comment || "",
                src: root.icon(e.icon),
                extra: `${e.id} ${e.genericName} ${(e.keywords ?? []).join(" ")}`.toLowerCase(),
                kind: "app",
                run: () => e.execute()
            })).sort((a, b) => a.name.localeCompare(b.name));
        }
    }
    Connections {
        target: DesktopEntries.applications
        function onValuesChanged() { appsT.restart(); }
    }

    // Active Hyprland Toplevels
    readonly property var winItems: Hyprland.toplevels.values.map(w => ({
        id: "win-" + (w.address ?? ""),
        name: w.title || (w.lastIpcObject?.class ?? "Window"),
        generic: w.lastIpcObject?.class ?? "",
        desc: `Workspace ${w.workspace?.name ?? ""}`,
        src: root.icon(w.lastIpcObject?.class?.toLowerCase()),
        extra: `${w.title} ${w.lastIpcObject?.class}`.toLowerCase(),
        kind: "win",
        run: () => Hyprland.dispatch(`hl.dsp.focus({ window = "address:0x${w.address}" })`)
    }))

    // Subsequence and keyword matching
    function filter(src, q) {
        if (!q) return src.slice(0, 30);
        const l = q.toLowerCase();
        const matches = [];
        for (const it of src) {
            const nameL = it.name.toLowerCase();
            if (nameL.startsWith(l)) {
                matches.push({ it: it, score: 100 - nameL.indexOf(l) });
            } else if (nameL.includes(l)) {
                matches.push({ it: it, score: 50 });
            } else if (it.extra.includes(l)) {
                matches.push({ it: it, score: 10 });
            }
        }
        return matches.sort((a, b) => b.score - a.score).map(m => m.it);
    }

    // Filtered results based on active query & mode
    readonly property var results: {
        const raw = root.query.trim();
        const q = raw.toLowerCase();

        // Direct prefix for command execution
        if (raw.startsWith(">") || root.mode === 1) {
            const cmd = raw.startsWith(">") ? raw.slice(1).trim() : raw;
            if (!cmd) return [];
            return [{
                id: "cmd-" + cmd,
                name: cmd,
                generic: "Shell Command",
                desc: "Press Enter to run in background, Shift+Enter to run in Kitty",
                src: root.icon("utilities-terminal"),
                kind: "cmd",
                run: (inKitty) => {
                    if (inKitty) Quickshell.execDetached(["kitty", "-e", "sh", "-c", cmd + "; exec fish"]);
                    else Quickshell.execDetached(["sh", "-c", cmd]);
                }
            }];
        }

        // Calculator Mode
        if (root.mode === 3 || (root.calcResult && raw.length >= 2 && /[0-9+\-*\/^%().=]/.test(raw))) {
            const items = [];
            if (root.calcResult) {
                items.push({
                    id: "calc-res",
                    name: root.calcResult,
                    generic: "Calculation Result",
                    desc: "Press Enter to copy to clipboard",
                    src: root.icon("accessories-calculator"),
                    kind: "calc",
                    run: () => Quickshell.execDetached(["wl-copy", root.calcResult])
                });
            }
            if (root.mode === 3) return items;
        }

        // Windows Mode
        if (root.mode === 2) {
            return filter(winItems, q);
        }

        // Standard Apps Mode
        const appRes = filter(apps, q);
        if (appRes.length > 0) return appRes;

        // Fallback Web Search if no apps match
        if (raw.length > 0) {
            return [{
                id: "web-search",
                name: `Search "${raw}" on Google`,
                generic: "Web Search",
                desc: "Open query in default browser",
                src: root.icon("web-browser"),
                kind: "web",
                run: () => Quickshell.execDetached(["xdg-open", `https://www.google.com/search?q=${encodeURIComponent(raw)}`])
            }];
        }
        return [];
    }

    // Quick calculation via qalc
    Process {
        id: calcProc
        command: ["qalc", "-t", root.query.trim()]
        stdout: StdioCollector {
            onStreamFinished: {
                const res = text.trim();
                if (res && !res.toLowerCase().includes("error") && res !== root.query.trim()) {
                    root.calcResult = res;
                } else {
                    root.calcResult = "";
                }
            }
        }
    }

    onQueryChanged: {
        sel = 0;
        const q = query.trim();
        if (q.length >= 2 && /[0-9+\-*\/^%().=]/.test(q)) {
            calcProc.command = ["qalc", "-t", q.replace(/^[=>\s]+/, "")];
            calcProc.running = true;
        } else {
            calcResult = "";
        }
    }

    function activateSelected(inKitty) {
        if (results.length > 0 && sel >= 0 && sel < results.length) {
            results[sel].run(inKitty);
            close();
        }
    }

    // Dark scrim dimming the desktop (35% opacity)
    Rectangle {
        id: scrim
        anchors.fill: parent
        color: "#000000"
        opacity: 0.35 * root.t
        visible: root.t > 0
        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }
    }

    // Spotlight floating frosted acrylic panel
    Rectangle {
        id: panel
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round(parent.height * 0.14 + 20 * (1 - root.t))
        width: 760
        height: 500
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

        // Top Search Bar
        Rectangle {
            id: searchBar
            anchors { left: parent.left; right: parent.right; top: parent.top }
            height: 56
            color: "transparent"

            Row {
                anchors { left: parent.left; leftMargin: 18; right: escHint.left; rightMargin: 16; verticalCenter: parent.verticalCenter }
                spacing: 12

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "\u{F002}" // Magnifying glass
                    font.family: Theme.nf
                    font.pixelSize: 18
                    color: Theme.cyan
                }

                TextInput {
                    id: input
                    width: parent.width - 40
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: Theme.ui
                    font.pixelSize: 18
                    color: Theme.fg
                    clip: true
                    activeFocusOnTab: true
                    cursorDelegate: Item {} // Replace static default caret with fluid animated caret

                    // Smooth fluid trailing cursor caret
                    Rectangle {
                        id: caret
                        visible: input.activeFocus
                        x: input.cursorRectangle.x
                        y: input.cursorRectangle.y
                        width: 2.5
                        height: input.cursorRectangle.height
                        radius: 1.25
                        color: Theme.cyan

                        Behavior on x {
                            NumberAnimation { duration: 75; easing.type: Easing.OutQuad }
                        }

                        SequentialAnimation on opacity {
                            running: input.activeFocus
                            loops: Animation.Infinite
                            NumberAnimation { from: 1; to: 1; duration: 500 }
                            NumberAnimation { from: 0.2; to: 0.2; duration: 400 }
                        }
                    }

                    Text {
                        anchors.fill: parent
                        text: root.mode === 1 ? "Type a shell command..." : root.mode === 2 ? "Search open windows..." : root.mode === 3 ? "Enter math expression..." : "Spotlight Search, commands (>), or calc..."
                        font: parent.font
                        color: Theme.mute
                        visible: !input.text
                    }

                    Keys.onEscapePressed: root.close()
                    Keys.onReturnPressed: e => root.activateSelected(e.modifiers & Qt.ShiftModifier)
                    Keys.onDownPressed: {
                        if (root.sel < root.results.length - 1) root.sel++;
                    }
                    Keys.onUpPressed: {
                        if (root.sel > 0) root.sel--;
                    }
                    Keys.onTabPressed: {
                        root.mode = (root.mode + 1) % 4;
                        root.sel = 0;
                    }
                    Keys.onBacktabPressed: {
                        root.mode = (root.mode + 3) % 4;
                        root.sel = 0;
                    }
                }
            }

            // Right Badges & Close Hint
            Row {
                id: escHint
                anchors { right: parent.right; rightMargin: 18; verticalCenter: parent.verticalCenter }
                spacing: 8

                // Quick Calculation Chip
                Rectangle {
                    visible: !!root.calcResult
                    anchors.verticalCenter: parent.verticalCenter
                    height: 26
                    width: calcRow.implicitWidth + 14
                    radius: 13
                    color: Qt.rgba(112 / 255, 192 / 255, 208 / 255, 0.20)
                    border.width: 1
                    border.color: Theme.cyan

                    Row {
                        id: calcRow
                        anchors.centerIn: parent
                        spacing: 4
                        Text {
                            text: "= " + root.calcResult
                            font.family: Theme.mono
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            color: Theme.cyan
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Quickshell.execDetached(["wl-copy", root.calcResult]);
                            root.close();
                        }
                    }
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    height: 22
                    width: escTxt.implicitWidth + 10
                    radius: 5
                    color: Qt.rgba(1, 1, 1, 0.08)
                    Text {
                        id: escTxt
                        anchors.centerIn: parent
                        text: "esc"
                        font.family: Theme.mono
                        font.pixelSize: 11
                        color: Theme.mute
                    }
                }
            }
        }

        // Mode Switcher Tabs
        Rectangle {
            id: modeBar
            anchors { left: parent.left; right: parent.right; top: searchBar.bottom }
            height: 36
            color: Qt.rgba(0, 0, 0, 0.20)

            Row {
                anchors { left: parent.left; leftMargin: 18; verticalCenter: parent.verticalCenter }
                spacing: 6

                Repeater {
                    model: root.modeLabels

                    Rectangle {
                        id: tabBtn
                        required property var modelData
                        height: 24
                        width: tabRow.implicitWidth + 16
                        radius: 12
                        color: root.mode === modelData.id ? Theme.cyan : tabHover.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.06)

                        Row {
                            id: tabRow
                            anchors.centerIn: parent
                            spacing: 6
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: tabBtn.modelData.icon
                                font.family: Theme.nf
                                font.pixelSize: 11
                                color: root.mode === tabBtn.modelData.id ? "#0D1017" : Theme.fg
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: tabBtn.modelData.label
                                font.family: Theme.ui
                                font.pixelSize: 11
                                font.weight: root.mode === tabBtn.modelData.id ? Font.Bold : Font.Normal
                                color: root.mode === tabBtn.modelData.id ? "#0D1017" : Theme.fg
                            }
                        }

                        MouseArea {
                            id: tabHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.mode = tabBtn.modelData.id;
                                root.sel = 0;
                                input.forceActiveFocus();
                            }
                        }
                    }
                }
            }
        }

        // Horizontal Divider Hairline
        Rectangle {
            id: divLine
            anchors { left: parent.left; right: parent.right; top: modeBar.bottom }
            height: 1
            color: Qt.rgba(1, 1, 1, 0.10)
        }

        // Two-Pane Content Area
        Item {
            anchors { left: parent.left; right: parent.right; top: divLine.bottom; bottom: parent.bottom }

            // Left Pane: Results List
            Item {
                id: leftPane
                anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                width: 340

                ListView {
                    id: resList
                    anchors { fill: parent; margins: 10 }
                    spacing: 4
                    clip: true
                    model: root.results
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: Rectangle {
                        id: itemCard
                        required property var modelData
                        required property int index

                        width: resList.width
                        height: 48
                        radius: 10
                        color: root.sel === index ? Qt.rgba(1, 1, 1, 0.14) : itemHover.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                        border.width: root.sel === index ? 1 : 0
                        border.color: Theme.specular
                        clip: true

                        SpecularGlow {
                            glowRadius: 80
                            maxOpacity: 0.8
                        }

                        Row {
                            anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                            spacing: 10

                            Image {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 28
                                height: 28
                                source: itemCard.modelData.src || ""
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 38
                                spacing: 2

                                Text {
                                    width: parent.width
                                    elide: Text.ElideRight
                                    text: itemCard.modelData.name
                                    font.family: Theme.ui
                                    font.pixelSize: 12
                                    font.weight: Font.DemiBold
                                    color: root.sel === itemCard.index ? Theme.fg : Theme.fg
                                }

                                Text {
                                    width: parent.width
                                    elide: Text.ElideRight
                                    text: itemCard.modelData.generic || itemCard.modelData.desc || ""
                                    font.family: Theme.ui
                                    font.pixelSize: 10
                                    color: Theme.sub
                                }
                            }
                        }

                        MouseArea {
                            id: itemHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.sel = itemCard.index;
                                root.activateSelected(false);
                            }
                        }
                    }
                }

                // Empty State
                Item {
                    anchors.centerIn: parent
                    visible: root.results.length === 0

                    Column {
                        anchors.centerIn: parent
                        spacing: 8
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "\u{F002}"
                            font.family: Theme.nf
                            font.pixelSize: 28
                            color: Theme.mute
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "No results found"
                            font.family: Theme.ui
                            font.pixelSize: 12
                            color: Theme.mute
                        }
                    }
                }
            }

            // Vertical Center Divider Hairline
            Rectangle {
                anchors { top: parent.top; bottom: parent.bottom; left: leftPane.right }
                width: 1
                color: Qt.rgba(1, 1, 1, 0.08)
            }

            // Right Pane: Detail & Quick Action Card
            Item {
                id: rightPane
                anchors { left: leftPane.right; right: parent.right; top: parent.top; bottom: parent.bottom }

                readonly property var cur: root.results.length > 0 && root.sel >= 0 && root.sel < root.results.length ? root.results[root.sel] : null

                Column {
                    anchors.centerIn: parent
                    width: parent.width - 40
                    spacing: 12
                    visible: !!rightPane.cur

                    // Big App / Result Icon
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 80
                        height: 80
                        radius: 20
                        color: Qt.rgba(1, 1, 1, 0.06)
                        border.width: 1
                        border.color: Theme.s3

                        Image {
                            anchors.centerIn: parent
                            width: 56
                            height: 56
                            source: rightPane.cur?.src || ""
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                        }
                    }

                    // Title & Category
                    Column {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width
                        spacing: 4

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: rightPane.cur?.name || ""
                            font.family: Theme.title
                            font.pixelSize: 18
                            font.weight: Font.Bold
                            color: Theme.fg
                            elide: Text.ElideRight
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: rightPane.cur?.generic || (rightPane.cur?.kind === "cmd" ? "Command" : "Application")
                            font.family: Theme.ui
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: Theme.cyan
                        }
                    }

                    // Description
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width - 20
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap
                        maximumLineCount: 3
                        elide: Text.ElideRight
                        text: rightPane.cur?.desc || "Ready to execute"
                        font.family: Theme.ui
                        font.pixelSize: 11
                        color: Theme.sub
                    }

                    Item { width: 1; height: 10 }

                    // Action Button
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 160
                        height: 36
                        radius: 18
                        color: Theme.cyan

                        Row {
                            anchors.centerIn: parent
                            spacing: 6
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: rightPane.cur?.kind === "cmd" ? "\u{F012C}" : rightPane.cur?.kind === "win" ? "\u{F031E}" : rightPane.cur?.kind === "calc" ? "\u{F00EC}" : "\u{F0403}"
                                font.family: Theme.nf
                                font.pixelSize: 12
                                color: "#0D1017"
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: rightPane.cur?.kind === "cmd" ? "Run Command" : rightPane.cur?.kind === "win" ? "Switch Window" : rightPane.cur?.kind === "calc" ? "Copy Answer" : "Open Application"
                                font.family: Theme.ui
                                font.pixelSize: 12
                                font.weight: Font.Bold
                                color: "#0D1017"
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.activateSelected(false)
                        }
                    }
                }
            }
        }
    }
}

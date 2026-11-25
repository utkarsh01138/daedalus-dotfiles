import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs
import qs.components

// Profile 4: glass — Quick Note (macOS Sonoma / Sequoia liquid frosted acrylic).
// Anchored at bottom-right corner. Auto-syncs persistently to Obsidian vault:
// /home/utki/MyData/MyFiles/Obsidian Stuff/Notes/QuickNote.md
PanelWindow {
    id: root

    property bool open: false
    readonly property string obsidianPath: "/home/utki/MyData/MyFiles/Obsidian Stuff/Notes/QuickNote.md"
    readonly property string fallbackPath: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/rice/quicknote.md"
    property string activePath: obsidianPath
    property string statusText: "Saved"

    function toggle() {
        if (open) close();
        else show();
    }

    function show() {
        open = true;
        loadFile();
        noteEdit.forceActiveFocus();
    }

    function close() {
        saveFile();
        open = false;
    }

    visible: t > 0
    anchors { right: true; bottom: true }
    implicitWidth: 440
    implicitHeight: 480
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "glass-note"

    property real t: open ? 1 : 0
    Behavior on t { NumberAnimation { duration: Theme.t; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.glide } }

    // File loading and saving via FileView
    FileView {
        id: noteFile
        path: root.activePath
        printErrors: false
        onLoaded: {
            if (noteFile.text) noteEdit.text = noteFile.text;
        }
        onLoadFailed: {
            // Fallback to local state if Obsidian directory is unmounted
            if (root.activePath === root.obsidianPath) {
                root.activePath = root.fallbackPath;
                noteFile.path = root.fallbackPath;
            }
        }
    }

    Timer {
        id: autoSaveT
        interval: 600
        onTriggered: root.saveFile()
    }

    function loadFile() {
        noteFile.reload();
    }

    function saveFile() {
        if (!noteFile.path) return;
        noteFile.setText(noteEdit.text);
        root.statusText = "Saved";
    }

    Rectangle {
        id: card
        anchors.fill: parent
        anchors.margins: 20
        radius: 18
        color: Theme.bg
        border.width: 1
        border.color: Theme.s3
        clip: true

        opacity: root.t
        scale: 0.90 + 0.10 * root.t
        transformOrigin: Item.BottomRight

        // Top specular hairline refraction
        Rectangle {
            anchors { left: parent.left; right: parent.right; top: parent.top }
            anchors.margins: 2
            height: 1
            color: Theme.specular
            opacity: 0.9
            radius: 18
        }

        // --- Header Bar ---
        Rectangle {
            id: header
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: 44
            color: Qt.rgba(255, 255, 255, 0.04)
            border.width: 1
            border.color: Qt.rgba(255, 255, 255, 0.06)

            // Traffic Light Close dot
            Rectangle {
                id: closeDot
                anchors { left: parent.left; leftMargin: 16; verticalCenter: parent.verticalCenter }
                width: 12
                height: 12
                radius: 6
                color: Theme.red

                Text {
                    anchors.centerIn: parent
                    visible: hovClose.containsMouse
                    text: "\u{F00D}"
                    font.family: Theme.nf
                    font.pixelSize: 8
                    color: Qt.rgba(0, 0, 0, 0.6)
                }

                MouseArea {
                    id: hovClose
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.close()
                }
            }

            // Title & Obsidian Tag
            Row {
                anchors.centerIn: parent
                spacing: 8

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Quick Note"
                    font.family: Theme.title
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    color: Theme.fg
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    height: 18
                    width: obsRow.implicitWidth + 10
                    radius: 9
                    color: Qt.rgba(180 / 255, 142 / 255, 173 / 255, 0.20)
                    border.width: 1
                    border.color: Theme.lavender

                    Row {
                        id: obsRow
                        anchors.centerIn: parent
                        spacing: 4
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "\u{F009A}"
                            font.family: Theme.nf
                            font.pixelSize: 10
                            color: Theme.lavender
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Obsidian"
                            font.family: Theme.ui
                            font.pixelSize: 9
                            font.weight: Font.Bold
                            color: Theme.lavender
                        }
                    }
                }
            }

            // Save status pill
            Text {
                anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
                text: root.statusText
                font.family: Theme.ui
                font.pixelSize: 11
                color: Theme.mute
            }
        }

        // --- Text Editor Area ---
        Flickable {
            id: flick
            anchors { top: header.bottom; left: parent.left; right: parent.right; bottom: footer.top; margins: 14 }
            contentWidth: width
            contentHeight: noteEdit.implicitHeight
            clip: true

            TextEdit {
                id: noteEdit
                width: parent.width
                wrapMode: TextEdit.Wrap
                font.family: Theme.ui
                font.pixelSize: 13
                color: Theme.fg
                selectionColor: Theme.cyan
                selectedTextColor: "#0D1017"
                selectByMouse: true
                focus: true

                onTextChanged: {
                    root.statusText = "Saving...";
                    autoSaveT.restart();
                }

                // Placeholder text
                Text {
                    anchors.fill: parent
                    visible: !noteEdit.text && !noteEdit.activeFocus
                    text: "Start typing a quick note...\nAuto-saves to your Obsidian vault."
                    font.family: Theme.ui
                    font.pixelSize: 13
                    color: Theme.mute
                }
            }
        }

        // --- Footer Bar ---
        Rectangle {
            id: footer
            anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
            height: 38
            color: Qt.rgba(255, 255, 255, 0.03)
            border.width: 1
            border.color: Qt.rgba(255, 255, 255, 0.06)

            // Word count
            Text {
                anchors { left: parent.left; leftMargin: 16; verticalCenter: parent.verticalCenter }
                readonly property int words: noteEdit.text.trim() ? noteEdit.text.trim().split(/\s+/).length : 0
                text: `${words} ${words === 1 ? 'word' : 'words'} · ${noteEdit.text.length} chars`
                font.family: Theme.mono
                font.pixelSize: 10
                color: Theme.sub
            }

            // Actions: Open in Obsidian & Clear
            Row {
                anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
                spacing: 8

                Rectangle {
                    height: 24
                    width: clrText.implicitWidth + 14
                    radius: 12
                    color: hovClr.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.06)

                    Text {
                        id: clrText
                        anchors.centerIn: parent
                        text: "Clear"
                        font.family: Theme.ui
                        font.pixelSize: 10
                        font.weight: Font.Medium
                        color: Theme.sub
                    }
                    MouseArea {
                        id: hovClr
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            noteEdit.text = "";
                            root.saveFile();
                        }
                    }
                }

                Rectangle {
                    height: 24
                    width: obsOpenText.implicitWidth + 14
                    radius: 12
                    color: hovObsOpen.containsMouse ? Qt.rgba(180 / 255, 142 / 255, 173 / 255, 0.35) : Qt.rgba(180 / 255, 142 / 255, 173 / 255, 0.20)
                    border.width: 1
                    border.color: Theme.lavender

                    Text {
                        id: obsOpenText
                        anchors.centerIn: parent
                        text: "Open Vault"
                        font.family: Theme.ui
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        color: Theme.lavender
                    }
                    MouseArea {
                        id: hovObsOpen
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.saveFile();
                            Quickshell.execDetached(["obsidian"]);
                        }
                    }
                }
            }
        }
    }

    // Dismiss on Escape key
    Shortcut {
        sequence: "Escape"
        enabled: root.open
        onActivated: root.close()
    }
}

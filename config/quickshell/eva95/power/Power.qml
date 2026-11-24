import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs
import qs.components
import qs.services

// =============================================================================
// EVA-95 CENTRAL DOGMA EMERGENCY SCRAM & POWER TERMINATION CONSOLE (1995 NGE)
// =============================================================================
// Faithful Neon Genesis Evangelion tactical military SCRAM interface:
// - Left: Authentic bilingual command list (01 閉鎖, 02 休止, 03 停止, 04 再起動, 05 離脱)
// - Right: Concentric octagonal AT-Field wireframe with live Central Dogma telemetry
// - Emergency SCRAM state: Flashing scarlet hazard display with MAGI override status
// - CRT amber scanline backdrop and hazard alert tapes
PanelWindow {
    id: root

    property int sel: 2
    readonly property var items: [
        ["01 閉鎖 // LOCK", "防護壁展張 // TERMINAL DOGMA BULKHEAD LOCK", () => Quickshell.execDetached([Quickshell.env("HOME") + "/.config/quickshell/rice/rice", "lock"])],
        ["02 休止 // SLEEP", "予備休眠態勢 // AUXILIARY STANDBY SUSPEND", () => Quickshell.execDetached(["systemctl", "suspend"])],
        ["03 停止 // SCRAM", "主電源強制遮断 // EMERGENCY ALL CIRCUITS CUTOFF", () => Quickshell.execDetached(["systemctl", "poweroff"])],
        ["04 再起動 // REBOOT", "全系再起動 // FULL SYSTEM HARDWARE CYCLE", () => Quickshell.execDetached(["systemctl", "reboot"])],
        ["05 離脱 // LOGOUT", "操縦権限返上 // OPERATOR CLEARANCE REVOKE", () => Hyprland.dispatch("hl.dsp.exit()")]
    ]

    function open() {
        sel = 2;
        SysStats.sample();
        visible = true;
    }
    function close() { visible = false; }
    function accept() {
        close();
        items[sel][2]();
    }

    visible: false
    anchors { left: true; right: true; top: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "glyph-power"

    // CRT Amber Scrim Backdrop
    Rectangle {
        anchors.fill: parent
        color: Theme.fade(Theme.bg, 0.96)
        MouseArea { anchors.fill: parent; onClicked: root.close() }
    }

    // Top Tactical Alert Banner (1995 NERV Emergency Protocol)
    Rectangle {
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: 38
        color: root.sel === 2 ? Theme.red : Theme.s1
        border { width: 1; color: root.sel === 2 ? "#FFFFFF" : Theme.accent }
        Behavior on color { ColorAnimation { duration: 180 } }

        Row {
            anchors.centerIn: parent
            spacing: 14
            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 8; height: 8; color: root.sel === 2 ? "#000000" : Theme.crimson }
            Text {
                text: root.sel === 2
                    ? "【 非常停止命令発令中 // EMERGENCY SCRAM OVERRIDE INITIATED // NERV HQ TOKYO-3 】"
                    : "/// EMERGENCY OVERRIDE // NERV SYSTEM TERMINATION PROTOCOL // MAGI-01 ///"
                font { family: Theme.mono; pixelSize: 11; bold: true; letterSpacing: 2 }
                color: root.sel === 2 ? "#FFFFFF" : Theme.hazard
            }
            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 8; height: 8; color: root.sel === 2 ? "#000000" : Theme.crimson }
        }
    }

    // Bottom Tactical Status Bar
    Rectangle {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 38
        color: Theme.s1
        border { width: 1; color: Theme.accent }
        Row {
            anchors.centerIn: parent
            spacing: 16
            Text {
                text: "/// ACCESS LEVEL A // HAL-16X MILITARY CONSOLE // CENTRAL DOGMA B322F ///"
                font { family: Theme.mono; pixelSize: 11; bold: true; letterSpacing: 2 }
                color: Theme.chalk
            }
        }
    }

    Stage {
        id: stage
        focus: true
        Keys.onPressed: e => {
            if (e.key === Qt.Key_Up || e.key === Qt.Key_K) root.sel = (root.sel + 4) % 5;
            else if (e.key === Qt.Key_Down || e.key === Qt.Key_J || e.key === Qt.Key_Tab) root.sel = (root.sel + 1) % 5;
            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) root.accept();
            else if (e.key === Qt.Key_Escape) root.close();
            else return;
            e.accepted = true;
        }

        // Left Side: Operational Command List
        Column {
            x: 180
            anchors.verticalCenter: parent.verticalCenter
            spacing: 20

            Repeater {
                model: root.items
                Item {
                    id: it
                    required property var modelData
                    required property int index
                    readonly property bool on: root.sel === index
                    readonly property bool isScram: index === 2

                    width: 580
                    height: it.on ? 84 : 58

                    Behavior on height { NumberAnimation { duration: Theme.t; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.glide } }

                    // Card Background for selected item
                    Rectangle {
                        anchors.fill: parent
                        radius: 0
                        color: it.on
                            ? (it.isScram ? Theme.red : Theme.accent)
                            : (hov.hovered ? Theme.s2 : "transparent")
                        border {
                            width: it.on ? 2 : 1
                            color: it.on
                                ? (it.isScram ? "#FFFFFF" : Theme.hazard)
                                : (hov.hovered ? Theme.accent : Theme.s3)
                        }

                        // Tactical Corner Reticles
                        Rectangle { visible: it.on; x: -2; y: -2; width: 10; height: 3; color: it.isScram ? "#FFFFFF" : Theme.hazard }
                        Rectangle { visible: it.on; x: -2; y: -2; width: 3; height: 10; color: it.isScram ? "#FFFFFF" : Theme.hazard }
                        Rectangle { visible: it.on; anchors.right: parent.right; anchors.rightMargin: -2; y: -2; width: 10; height: 3; color: it.isScram ? "#FFFFFF" : Theme.hazard }
                        Rectangle { visible: it.on; anchors.right: parent.right; anchors.rightMargin: -2; y: -2; width: 3; height: 10; color: it.isScram ? "#FFFFFF" : Theme.hazard }
                        Rectangle { visible: it.on; x: -2; anchors.bottom: parent.bottom; anchors.bottomMargin: -2; width: 10; height: 3; color: it.isScram ? "#FFFFFF" : Theme.hazard }
                        Rectangle { visible: it.on; x: -2; anchors.bottom: parent.bottom; anchors.bottomMargin: -2; width: 3; height: 10; color: it.isScram ? "#FFFFFF" : Theme.hazard }
                        Rectangle { visible: it.on; anchors.right: parent.right; anchors.rightMargin: -2; anchors.bottom: parent.bottom; anchors.bottomMargin: -2; width: 10; height: 3; color: it.isScram ? "#FFFFFF" : Theme.hazard }
                        Rectangle { visible: it.on; anchors.right: parent.right; anchors.rightMargin: -2; anchors.bottom: parent.bottom; anchors.bottomMargin: -2; width: 3; height: 10; color: it.isScram ? "#FFFFFF" : Theme.hazard }
                    }

                    Row {
                        anchors { left: parent.left; leftMargin: 18; verticalCenter: parent.verticalCenter }
                        spacing: 16

                        // State indicator block
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: it.on ? 14 : 8
                            height: it.on ? 32 : 16
                            radius: 0
                            color: it.on
                                ? (it.isScram ? "#000000" : "#08080A")
                                : (it.isScram ? Theme.red : Theme.grey)
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 3

                            Text {
                                text: it.modelData[0]
                                font { family: Theme.eva; pixelSize: it.on ? 32 : 24; bold: true }
                                color: it.on
                                    ? (it.isScram ? "#FFFFFF" : "#08080A")
                                    : (it.isScram ? Theme.red : Theme.chalk)
                            }
                            Text {
                                text: it.modelData[1]
                                font { family: Theme.mono; pixelSize: 10; bold: true; letterSpacing: 1.2 }
                                color: it.on
                                    ? (it.isScram ? "#FFE0E0" : "#2E1C00")
                                    : Theme.grey
                            }
                        }
                    }

                    // Selection chevron on right
                    Text {
                        visible: it.on
                        anchors { right: parent.right; rightMargin: 20; verticalCenter: parent.verticalCenter }
                        text: "◀ EXEC"
                        font { family: Theme.mono; pixelSize: 13; bold: true; letterSpacing: 1.5 }
                        color: it.isScram ? "#FFFFFF" : "#08080A"
                    }

                    HoverHandler { id: hov; onHoveredChanged: if (hovered) root.sel = it.index; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: { root.sel = it.index; root.accept(); } }
                }
            }
        }

        // Right Side: Concentric AT-Field Vector & Central Dogma Telemetry
        Item {
            x: stage.width - 200 - 520
            anchors.verticalCenter: parent.verticalCenter
            width: 520
            height: 520

            // Concentric AT-Field Vector Reticle
            Image {
                anchors.centerIn: parent
                width: 480
                height: 480
                source: "file:///home/utki/daedalus/config/quickshell/eva95/bar/atfield.svg"
                fillMode: Image.PreserveAspectFit
                opacity: 0.65

                // Slow rotation for authentic anime radar display
                RotationAnimation on rotation {
                    running: true
                    loops: Animation.Infinite
                    from: 0
                    to: 360
                    duration: 60000
                }
            }

            // Radar angle line overlay
            Rectangle {
                anchors.centerIn: parent
                width: 460
                height: 1
                color: root.sel === 2 ? Theme.red : Theme.amber
                opacity: 0.4
            }
            Rectangle {
                anchors.centerIn: parent
                width: 1
                height: 460
                color: root.sel === 2 ? Theme.red : Theme.amber
                opacity: 0.4
            }

            // Normal Telemetry Display (when not hovering/selecting SCRAM)
            Column {
                anchors.centerIn: parent
                visible: root.sel !== 2
                spacing: 12

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 320
                    height: 24
                    color: Theme.accent
                    Row {
                        anchors.centerIn: parent
                        spacing: 8
                        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 5; height: 5; color: "#000000" }
                        Text {
                            text: "NERV CENTRAL DOGMA // TELEMETRY"
                            font { family: Theme.mono; pixelSize: 10; bold: true; letterSpacing: 1.2 }
                            color: "#000000"
                        }
                        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 5; height: 5; color: "#000000" }
                    }
                }

                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 2
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "CONTINUOUS OPERATIONAL RUNTIME"
                        font { family: Theme.mono; pixelSize: 9; bold: true; letterSpacing: 1.5 }
                        color: Theme.hazard
                    }
                    Num {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: `${Math.floor(SysStats.uptime / 3600)}:${String(Math.floor(SysStats.uptime / 60) % 60).padStart(2, "0")}:${String(Math.floor(SysStats.uptime) % 60).padStart(2, "0")}`
                        font.pixelSize: 64
                        color: Theme.fg
                    }
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 280
                    height: 1
                    color: Theme.s3
                }

                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 4
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: `ACTIVE PROCESS THREADS: ${Hyprland.toplevels.values.length} WINDOWS DEPLOYED`
                        font { family: Theme.mono; pixelSize: 10; bold: true; letterSpacing: 1.0 }
                        color: Theme.chalk
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "MAGI-01 STATUS: MELCHIOR [OK] BALTHASAR [OK] CASPAR [OK]"
                        font { family: Theme.mono; pixelSize: 9; letterSpacing: 0.8 }
                        color: Theme.phosphor
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "GEOFRONT B322F // SECTOR 01 // SUBTERRANEAN HEADQUARTERS"
                        font { family: Theme.mono; pixelSize: 8; letterSpacing: 0.8 }
                        color: Theme.grey
                    }
                }
            }

            // Emergency SCRAM Warning Display (when hovering/selecting SCRAM)
            Rectangle {
                anchors.centerIn: parent
                visible: root.sel === 2
                width: 440
                height: 220
                color: Theme.red
                border { width: 3; color: "#FFFFFF" }

                SequentialAnimation on opacity {
                    running: root.sel === 2
                    loops: Animation.Infinite
                    NumberAnimation { from: 1.0; to: 0.70; duration: 350 }
                    NumberAnimation { from: 0.70; to: 1.0; duration: 350 }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 10

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 400
                        height: 28
                        color: "#000000"
                        Text {
                            anchors.centerIn: parent
                            text: "【 非常停止 // EMERGENCY SCRAM 】"
                            font { family: Theme.eva; pixelSize: 14; bold: true; letterSpacing: 2 }
                            color: Theme.red
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "ALL OPERATIONAL CIRCUITS TERMINATING"
                        font { family: Theme.mono; pixelSize: 13; bold: true; letterSpacing: 1.5 }
                        color: "#FFFFFF"
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "MAGI TRIPARTITE CONSENSUS: OVERRIDE AUTHORIZED"
                        font { family: Theme.mono; pixelSize: 10; bold: true }
                        color: "#000000"
                    }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 380
                        height: 1
                        color: "#000000"
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "PRESS [ENTER] TO EXECUTE IMMEDIATE SCRAM"
                        font { family: Theme.mono; pixelSize: 11; bold: true; letterSpacing: 1.2 }
                        color: "#FFFFFF"
                    }
                }
            }
        }

        // Bottom Help Legend
        Row {
            x: 180
            anchors { bottom: parent.bottom; bottomMargin: 60 }
            spacing: 34
            Lb { text: "↑↓ / J K  SELECT PROTOCOL"; px: 11; color: Theme.chalk }
            Lb { text: "↵ ENTER  CONFIRM EXECUTION"; px: 11; color: Theme.hazard }
            Lb { text: "ESC  ABORT COMMAND"; px: 11; color: Theme.grey }
        }
    }
}

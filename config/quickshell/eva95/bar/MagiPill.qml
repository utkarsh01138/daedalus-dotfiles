import QtQuick
import Quickshell
import qs
import qs.components
import qs.services

// MAGI Tri-Cluster Consensus Telemetry Pill (1995 Evangelion TV Series Style):
// MELCHIOR-1 (科学者) | BALTHASAR-2 (母) | CASPAR-3 (女)
// Solid phosphor consensus stamp & live hex reactor core
Rectangle {
    id: root

    readonly property real cpu: SysStats.cpu
    readonly property real temp: SysStats.cpuTemp
    readonly property bool alert: cpu > 0.90 || temp > 85
    readonly property bool busy: !alert && (cpu > 0.65 || temp > 72)

    height: 24
    width: magiRow.width + 16
    radius: 0
    color: alert ? Qt.rgba(1.0, 0.13, 0.0, 0.3) : Theme.s2
    border {
        width: 1
        color: alert ? Theme.red : busy ? Theme.hazard : Theme.amber
    }

    Timer {
        id: blink
        interval: 400
        repeat: true
        running: root.alert
        onTriggered: root.border.color = root.border.color === Theme.red ? Qt.color("#FFFFFF") : Theme.red
        onRunningChanged: if (!running) root.border.color = root.alert ? Theme.red : root.busy ? Theme.hazard : Theme.amber
    }

    Row {
        id: magiRow
        anchors.centerIn: parent
        spacing: 8

        AnimatedImage {
            anchors.verticalCenter: parent.verticalCenter
            width: 14
            height: 14
            source: Quickshell.shellPath("assets/gifs/opt/ja_fuel_bundle_hex_reactor_2x.gif")
            fillMode: Image.PreserveAspectFit
            playing: true
        }

        // Consensus Header Stamp
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            height: 16
            width: 58
            color: root.alert ? Theme.red : Theme.phosphor
            Text {
                anchors.centerIn: parent
                text: root.alert ? "決裂 1/3" : "全会一致"
                font { family: Theme.eva; pixelSize: 9; bold: true }
                color: "#08080A"
            }
        }

        // Cluster status item: TV Show Solid Stamp
        component NodeStatus: Row {
            property string name: ""
            property string kanji: ""
            property string stampText: root.alert ? "拒絶" : root.busy ? "審議" : "承認"
            property color nodeColor: root.alert ? Theme.red : root.busy ? Theme.hazard : Theme.phosphor
            spacing: 4

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: `${name} ${kanji}`
                font { family: Theme.eva; pixelSize: 9; bold: true }
                color: Theme.chalk
            }
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 32
                height: 14
                color: nodeColor
                Text {
                    anchors.centerIn: parent
                    text: stampText
                    font { family: Theme.eva; pixelSize: 8; bold: true }
                    color: "#08080A"
                }
            }
        }

        NodeStatus { name: "M-1"; kanji: "科学者" }
        NodeStatus { name: "B-2"; kanji: "母" }
        NodeStatus { name: "C-3"; kanji: "女" }
    }
}

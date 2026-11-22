import QtQuick
import qs
import qs.components
import qs.services

// MAGI Tri-Cluster Consensus Telemetry Pill:
// MELCHIOR-1 | BALTHASAR-2 | CASPAR-3
// Automatically assesses load/temperature state from SysStats:
// Normal: Electric Amber [OK]
// Heavy / Crunch: Hazard Yellow [BUSY]
// Emergency / Critical (>90% CPU or >85C): Flashing Unit-02 Crimson [ALERT / OVERRIDE]
Rectangle {
    id: root

    readonly property real cpu: SysStats.cpu
    readonly property real temp: SysStats.cpuTemp
    readonly property bool alert: cpu > 0.90 || temp > 85
    readonly property bool busy: !alert && (cpu > 0.65 || temp > 72)

    height: 28
    width: magiRow.width + 20
    radius: 0
    color: alert ? Qt.rgba(0.9, 0.11, 0.14, 0.2) : Theme.s2
    border {
        width: 1
        color: alert ? Theme.crimson : busy ? Theme.hazard : Theme.crimson
    }

    Timer {
        id: blink
        interval: 400
        repeat: true
        running: root.alert
        onTriggered: root.border.color = root.border.color === Theme.crimson ? Qt.color("#FFFFFF") : Theme.crimson
        onRunningChanged: if (!running) root.border.color = root.alert ? Theme.crimson : root.busy ? Theme.hazard : Theme.crimson
    }

    Row {
        id: magiRow
        anchors.centerIn: parent
        spacing: 10

        // Cluster status item
        component NodeStatus: Row {
            property string name: ""
            property string status: root.alert ? "ALERT" : root.busy ? "BUSY" : "OK"
            property color nodeColor: root.alert ? Theme.crimson : root.busy ? Theme.hazard : Theme.crimson
            spacing: 4

            Text {
                text: name
                font.family: Theme.mono
                font.pixelSize: 11
                font.bold: true
                color: Theme.chalk
            }
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 6
                height: 6
                color: nodeColor
            }
            Text {
                text: `[${status}]`
                font.family: Theme.mono
                font.pixelSize: 10
                font.bold: true
                color: nodeColor
            }
        }

        NodeStatus { name: "M-1" }
        Text { text: "|"; font.family: Theme.mono; font.pixelSize: 11; color: Theme.s3 }
        NodeStatus { name: "B-2" }
        Text { text: "|"; font.family: Theme.mono; font.pixelSize: 11; color: Theme.s3 }
        NodeStatus {
            name: "C-3"
            status: root.alert ? "OVERRIDE" : root.busy ? "BUSY" : "OK"
        }
    }
}

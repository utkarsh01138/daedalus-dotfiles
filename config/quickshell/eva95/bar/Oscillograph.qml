import QtQuick
import qs
import qs.services

// Real-time CPU core oscillograph / activity bars across threads
Row {
    id: root

    spacing: 2
    height: 18

    Repeater {
        model: Math.min(16, SysStats.cores.length || 8)

        Rectangle {
            required property int index
            readonly property real load: SysStats.cores[index] ?? (SysStats.cpu * (0.6 + 0.4 * Math.sin(index)))
            width: 3
            height: Math.max(3, Math.round(parent.height * Math.min(1, Math.max(0.1, load))))
            anchors.bottom: parent.bottom
            radius: 0
            color: load > 0.85 ? Theme.red : load > 0.6 ? Theme.hazard : Theme.amber
            opacity: 0.85

            Behavior on height {
                NumberAnimation { duration: 180; easing.type: Easing.OutQuad }
            }
        }
    }
}

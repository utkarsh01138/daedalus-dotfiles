import QtQuick
import qs
import qs.components

// настройки записи под плитками (правый клик по record): область, звук, fps, качество, курсор.
// Живут в Theme.state, их же берёт запись из скриншотилки (Sys.recArgs)
Rectangle {
    id: root
    signal touched // любой клик внутри — панель приколота
    signal start

    readonly property var st: Theme.state

    height: list.height + 32
    radius: 0
    color: Theme.s2
    border { width: 1; color: Theme.accent }

    Column {
        id: list
        x: 16
        y: 16
        width: parent.width - 32
        spacing: 8

        Lb { x: 4; text: "recording · ~/videos" }

        Choice { label: "area"; opts: ["screen", "region"]; cur: root.st.recArea; onPicked: i => root.st.recArea = i }
        Choice { label: "audio"; opts: ["off", "sys", "mic", "both"]; cur: root.st.recAudio; onPicked: i => root.st.recAudio = i }
        Choice { label: "fps"; opts: Sys.recFps; cur: Math.max(0, Sys.recFps.indexOf(root.st.recFps)); onPicked: i => root.st.recFps = Sys.recFps[i] }
        Choice { label: "quality"; opts: ["med", "high", "max", "ultra"]; cur: root.st.recQuality; onPicked: i => root.st.recQuality = i }
        Choice { label: "cursor"; opts: ["on", "off"]; cur: root.st.recCursor ? 0 : 1; onPicked: i => root.st.recCursor = i === 0 }

        // старт/стоп
        Rectangle {
            width: list.width
            height: 48
            radius: 0
            color: Theme.accent
            border { width: 1; color: Theme.hazard }
            Row {
                anchors.centerIn: parent
                spacing: 10
                Rectangle { visible: Sys.rec; anchors.verticalCenter: parent.verticalCenter; width: 10; height: 10; radius: 0; color: "#000000" }
                Lb { anchors.verticalCenter: parent.verticalCenter; text: Sys.rec ? "STOP RECORDING" : "START RECORDING"; color: "#000000" }
            }
            TapHandler { onTapped: root.start() }
            HoverHandler { cursorShape: Qt.PointingHandCursor }
        }
    }

    // ряд выбора: метка слева
    component Choice: Item {
        id: ch
        property string label
        property var opts: []
        property int cur
        signal picked(int i)
        width: list.width
        height: 40
        Lb { x: 4; anchors.verticalCenter: parent.verticalCenter; text: ch.label; px: 10 }
        Rectangle {
            id: track
            x: 96
            width: parent.width - x
            height: parent.height
            radius: 0
            color: Theme.s1
            border { width: 1; color: Theme.line }
            readonly property real cell: (width - 8) / ch.opts.length
            Rectangle {
                x: 4 + track.cell * ch.cur
                y: 4
                width: track.cell
                height: parent.height - 8
                radius: 0
                color: Theme.accent
                border { width: 1; color: Theme.hazard }
                Behavior on x { NumberAnimation { duration: Theme.t; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.glide } }
            }
            Repeater {
                model: ch.opts
                Item {
                    id: cell
                    required property int index
                    required property var modelData
                    x: 4 + track.cell * index
                    width: track.cell
                    height: track.height
                    Lb { anchors.centerIn: parent; px: 10; text: cell.modelData; color: ch.cur === cell.index ? "#000000" : Theme.chalk }
                    TapHandler { onTapped: { root.touched(); ch.picked(cell.index); } }
                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                }
            }
        }
    }
}

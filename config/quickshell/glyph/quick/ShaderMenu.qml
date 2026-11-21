import QtQuick
import qs
import qs.components

// Daedalus Optics: Quick Settings shader selector menu (right-click on Shader tile)
Rectangle {
    id: root
    signal touched

    property int tab: 0 // 0: Daily Rotation (6), 1: All Shaders (14)

    readonly property var daily: Sys.shaderList.filter(s => s.fav)
    readonly property var all: Sys.shaderList
    readonly property var currentItems: tab === 0 ? daily : all

    height: col.height + 32
    radius: Theme.corner(30)
    color: Theme.s2

    Column {
        id: col
        x: 16
        y: 16
        width: parent.width - 32
        spacing: 12

        // Header: title, category selector, and "turn off" pill
        Item {
            width: parent.width
            height: 28

            Row {
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                spacing: 8

                Lb {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "optics"
                    px: 11
                }

                // Tab chips: Rotation (6) vs All (14)
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    Rectangle {
                        width: rotLab.implicitWidth + 16
                        height: 24
                        radius: 12
                        color: root.tab === 0 ? Theme.fg : Theme.s1
                        Lb {
                            id: rotLab
                            anchors.centerIn: parent
                            text: "daily (6)"
                            px: 10
                            color: root.tab === 0 ? Theme.ink : Theme.grey
                        }
                        TapHandler { onTapped: { root.touched(); root.tab = 0; } }
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                    }

                    Rectangle {
                        width: allLab.implicitWidth + 16
                        height: 24
                        radius: 12
                        color: root.tab === 1 ? Theme.fg : Theme.s1
                        Lb {
                            id: allLab
                            anchors.centerIn: parent
                            text: "all (14)"
                            px: 10
                            color: root.tab === 1 ? Theme.ink : Theme.grey
                        }
                        TapHandler { onTapped: { root.touched(); root.tab = 1; } }
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                    }
                }
            }

            // Normal Display / Off button
            Rectangle {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                width: offLab.implicitWidth + 18
                height: 26
                radius: 13
                color: Sys.shader === "" ? Theme.fg : Theme.s1
                border { width: Sys.shader === "" ? 0 : 1; color: Theme.s3 }
                Row {
                    anchors.centerIn: parent
                    spacing: 5
                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "\u{F050E}"
                        font.pixelSize: 11
                        color: Sys.shader === "" ? Theme.ink : Theme.grey
                    }
                    Lb {
                        id: offLab
                        anchors.verticalCenter: parent.verticalCenter
                        text: "normal"
                        px: 10
                        color: Sys.shader === "" ? Theme.ink : Theme.fg
                    }
                }
                TapHandler {
                    onTapped: {
                        root.touched();
                        Sys.clearShader();
                    }
                }
                HoverHandler { cursorShape: Qt.PointingHandCursor }
            }
        }

        // Scrollable shader grid container
        Flickable {
            id: flick
            width: parent.width
            height: Math.min(contentHeight, 260)
            contentHeight: grid.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Grid {
                id: grid
                width: flick.width
                columns: 2
                spacing: 8

                Repeater {
                    model: root.currentItems

                    Rectangle {
                        id: card
                        required property var modelData
                        required property int index

                        readonly property bool active: Sys.shader === modelData.id
                        width: (grid.width - 8) / 2
                        height: 42
                        radius: Theme.corner(21)
                        color: active ? Theme.fg : cardHov.hovered ? Theme.s3 : Theme.s1
                        border { width: active ? 0 : 1; color: Theme.s3 }
                        Behavior on color { ColorAnimation { duration: Theme.t } }

                        Row {
                            anchors { left: parent.left; leftMargin: 12; right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                            spacing: 8

                            Icon {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "\u{F03D8}"
                                font.pixelSize: 13
                                color: card.active ? Theme.ink : Theme.grey
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 24
                                spacing: 1

                                Text {
                                    text: card.modelData.label
                                    textFormat: Text.PlainText
                                    elide: Text.ElideRight
                                    width: parent.width
                                    font { family: Theme.ui; pixelSize: 12; weight: Font.DemiBold }
                                    color: card.active ? Theme.ink : Theme.fg
                                }

                                Lb {
                                    text: card.modelData.desc
                                    elide: Text.ElideRight
                                    width: parent.width
                                    px: 9
                                    color: card.active ? Theme.ink : Theme.grey
                                    opacity: card.active ? 0.7 : 1
                                }
                            }
                        }

                        TapHandler {
                            onTapped: {
                                root.touched();
                                if (card.active) {
                                    Sys.clearShader();
                                } else {
                                    Sys.setShader(card.modelData.id);
                                }
                            }
                        }
                        HoverHandler { id: cardHov; cursorShape: Qt.PointingHandCursor }
                    }
                }
            }
        }
    }
}

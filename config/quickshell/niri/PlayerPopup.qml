import Quickshell
import Quickshell.Io
import QtQuick

PopupWindow {
    id: popupRoot

    property var barWin

    visible: false
    implicitWidth: 360
    implicitHeight: contentColumn.implicitHeight + 28
    color: "transparent"
    grabFocus: false

    readonly property bool multi: Player.players.length > 1
    readonly property real progress: Player.length > 0 ? Math.max(0, Math.min(1, Player.position / Player.length)) : 0

    function openAt(x) {
        anchor.window = barWin ?? null;
        anchor.rect.x = Math.max(0, Math.min(x - 20, (barWin?.width ?? 1000) - implicitWidth - 8));
        anchor.rect.y = Theme.barHeight + 6;
        visible = true;
        Player.refresh();
    }

    onVisibleChanged: {
        if (!visible)
            closed();
    }

    component MediaBtn: Rectangle {
        id: mb

        property string glyph
        property var action
        property bool primary: false
        property bool dimmed: false
        property int box: 34

        width: box
        height: box
        radius: 0
        color: mbHover.hovered && !dimmed ? Theme.accent : Theme.bgLight
        opacity: dimmed ? 0.35 : 1

        Text {
            anchors.centerIn: parent
            text: mb.glyph
            font.family: Theme.fontFamily
            font.pixelSize: mb.primary ? 19 : 16
            color: mbHover.hovered && !dimmed ? Theme.bg : Theme.fg
        }

        HoverHandler {
            id: mbHover

            enabled: !mb.dimmed
        }

        MouseArea {
            anchors.fill: parent
            enabled: !mb.dimmed
            cursorShape: Qt.PointingHandCursor
            onClicked: if (mb.action)
                mb.action()
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 0
        color: Theme.bg
        border.color: Theme.accent
        border.width: 1

        Column {
            id: contentColumn

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 14
            spacing: 10

            Item {
                width: parent.width
                height: 16

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: Player.available ? "NOW PLAYING" : "MEDIA"
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    color: Theme.dim
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: Player.playerName
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    color: Theme.accent
                }
            }

            Text {
                width: parent.width
                elide: Text.ElideRight
                text: Player.hasTrack ? Player.title : (Player.available ? "No track" : "No media player")
                font.family: Theme.fontFamily
                font.pixelSize: 16
                color: Theme.fg
            }

            Text {
                width: parent.width
                elide: Text.ElideRight
                visible: text !== ""
                text: Player.artist + (Player.album !== "" ? "  ·  " + Player.album : "")
                font.family: Theme.fontFamily
                font.pixelSize: 12
                color: Theme.dim
            }

            Column {
                width: parent.width
                spacing: 4
                visible: Player.length > 0

                Rectangle {
                    id: seekBar

                    width: parent.width
                    height: 6
                    radius: 0
                    color: Theme.bgLight

                    Rectangle {
                        width: seekBar.width * popupRoot.progress
                        height: parent.height
                        radius: 0
                        color: Theme.accent
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onPressed: mouse => Player.seek(mouse.x / width)
                    }
                }

                Item {
                    width: parent.width
                    height: 14

                    Text {
                        anchors.left: parent.left
                        text: Player.fmtTime(Player.position)
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        color: Theme.dim
                    }

                    Text {
                        anchors.right: parent.right
                        text: Player.fmtTime(Player.length)
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        color: Theme.dim
                    }
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 10

                MediaBtn {
                    glyph: "󰒮"
                    dimmed: !Player.canControl
                    action: () => Player.previous()
                }

                MediaBtn {
                    glyph: Player.playing ? "󰏤" : "󰐊"
                    primary: true
                    dimmed: !Player.canControl
                    action: () => Player.togglePlay()
                }

                MediaBtn {
                    glyph: "󰒭"
                    dimmed: !Player.canControl
                    action: () => Player.next()
                }
            }

            Row {
                width: parent.width
                spacing: 8

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Player.playerVolume <= 0 ? "󰖁" : Player.playerVolume < 0.34 ? "󰕿" : Player.playerVolume < 0.67 ? "󰖀" : "󰕾"
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                    color: Theme.fg
                }

                Rectangle {
                    id: volBar

                    width: parent.width - 82
                    height: 6
                    anchors.verticalCenter: parent.verticalCenter
                    radius: 0
                    color: Theme.bgLight

                    Rectangle {
                        width: volBar.width * Math.max(0, Math.min(1, Player.playerVolume))
                        height: parent.height
                        radius: 0
                        color: Theme.accent
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onPressed: mouse => Player.setVolume(mouse.x / width)
                        onReleased: mouse => Player.setVolume(mouse.x / width)
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 40
                    horizontalAlignment: Text.AlignRight
                    text: Math.round(Player.playerVolume * 100) + "%"
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    color: Theme.dim
                }
            }

            Row {
                visible: popupRoot.multi
                spacing: 6

                Repeater {
                    model: Player.players

                    delegate: Rectangle {
                        id: playerChip

                        required property string modelData

                        readonly property bool active: Player.selectedPlayer === modelData || (Player.selectedPlayer === "" && Player.playerName === modelData)

                        width: chipLabel.implicitWidth + 16
                        height: 22
                        radius: 0
                        color: active ? Theme.accent : chipHover.hovered ? Qt.lighter(Theme.bgLight, 1.25) : Theme.bgLight

                        Text {
                            id: chipLabel

                            anchors.centerIn: parent
                            text: playerChip.modelData
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            color: playerChip.active ? Theme.bg : Theme.fg
                        }

                        HoverHandler {
                            id: chipHover
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Player.selectPlayer(playerChip.modelData)
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "playerpopup"

        function toggle(): void {
            if (popupRoot.visible) {
                popupRoot.visible = false;
                return;
            }
            popupRoot.openAt((popupRoot.barWin?.width ?? 800) - popupRoot.implicitWidth);
        }
    }
}

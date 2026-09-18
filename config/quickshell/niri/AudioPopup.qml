import Quickshell
import Quickshell.Io
import QtQuick

PopupWindow {
    id: popupRoot

    property var barWin
    property bool interacting: false

    visible: false
    implicitWidth: 380
    implicitHeight: contentColumn.implicitHeight + 28
    color: "transparent"
    grabFocus: false

    function openAt(x) {
        anchor.window = barWin ?? null;
        anchor.rect.x = Math.max(0, Math.min(x - 20, (barWin?.width ?? 1000) - implicitWidth - 8));
        anchor.rect.y = Theme.barHeight + 6;
        visible = true;
        Audio.refresh();
    }

    onVisibleChanged: {
        if (!visible)
            closed();
    }

    Timer {
        interval: 2000
        repeat: true
        running: popupRoot.visible && !popupRoot.interacting
        onTriggered: Audio.refresh()
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
                height: 26

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Audio Output"
                    font.family: Theme.fontFamily
                    font.pixelSize: 15
                    font.bold: true
                    color: Theme.fg
                }

                Rectangle {
                    id: closeBtn

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 26
                    height: 22
                    radius: 0
                    color: closeHover.containsMouse ? Theme.red : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "󰅖"
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        color: closeHover.containsMouse ? Theme.bg : Theme.fg
                    }

                    HoverHandler {
                        id: closeHover
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: popupRoot.visible = false
                    }
                }
            }

            Text {
                width: parent.width
                visible: !Audio.available
                text: "No output devices found"
                font.family: Theme.fontFamily
                font.pixelSize: 12
                color: Theme.dim
            }

            Column {
                width: parent.width
                spacing: 6

                Repeater {
                    model: Audio.sinks

                    delegate: Rectangle {
                        id: sinkRow

                        required property var modelData

                        readonly property bool muted: modelData.mute
                        readonly property real shownVol: dragVol >= 0 ? dragVol : Math.max(0, Math.min(1, modelData.volume))

                        property real dragVol: -1

                        width: parent.width
                        height: 58
                        radius: 0
                        color: sinkHover.hovered ? Theme.bgLight : "transparent"
                        border.color: modelData.isDefault ? Theme.accent : Theme.bgLight
                        border.width: 1

                        HoverHandler {
                            id: sinkHover
                        }

                        Item {
                            id: nameRow

                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            anchors.topMargin: 6
                            height: 18

                            Text {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 32
                                elide: Text.ElideRight
                                text: sinkRow.modelData.description
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                color: sinkRow.modelData.isDefault ? Theme.accent : Theme.fg
                            }

                            Rectangle {
                                id: muteBtn

                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                width: 24
                                height: 18
                                radius: 0
                                color: muteHover.hovered ? Theme.bgLight : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: sinkRow.muted ? "󰖁" : "󰕾"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 13
                                    color: sinkRow.muted ? Theme.red : Theme.fg
                                }

                                HoverHandler {
                                    id: muteHover
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Audio.toggleMute(sinkRow.modelData.index)
                                }
                            }

                            MouseArea {
                                anchors.left: parent.left
                                anchors.right: muteBtn.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Audio.setDefault(sinkRow.modelData.index)
                            }
                        }

                        Item {
                            id: sliderRow

                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            anchors.bottomMargin: 6
                            height: 14

                            Rectangle {
                                id: volTrack

                                anchors.left: parent.left
                                anchors.right: pctText.left
                                anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                height: 6
                                color: Theme.bgLight

                                Rectangle {
                                    width: volTrack.width * sinkRow.shownVol
                                    height: parent.height
                                    color: sinkRow.muted ? Theme.dim : Theme.accent
                                }
                            }

                            Text {
                                id: pctText

                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                width: 36
                                horizontalAlignment: Text.AlignRight
                                text: Math.round(sinkRow.shownVol * 100) + "%"
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                color: Theme.dim
                            }

                            MouseArea {
                                anchors.left: parent.left
                                anchors.right: pctText.left
                                anchors.rightMargin: 8
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                cursorShape: Qt.PointingHandCursor
                                onPressed: mouse => {
                                    popupRoot.interacting = true;
                                    sinkRow.dragVol = Math.max(0, Math.min(1, mouse.x / width));
                                }
                                onPositionChanged: mouse => {
                                    if (pressed)
                                        sinkRow.dragVol = Math.max(0, Math.min(1, mouse.x / width));
                                }
                                onReleased: mouse => {
                                    const v = sinkRow.dragVol >= 0 ? sinkRow.dragVol : Math.max(0, Math.min(1, mouse.x / width));
                                    sinkRow.dragVol = -1;
                                    popupRoot.interacting = false;
                                    Audio.setVolume(sinkRow.modelData.index, v);
                                }
                                onCanceled: {
                                    sinkRow.dragVol = -1;
                                    popupRoot.interacting = false;
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                id: pavuBtn

                width: parent.width
                height: 28
                radius: 0
                color: pavuHover.hovered ? Theme.accent : Theme.bgLight

                Text {
                    anchors.centerIn: parent
                    text: "Open pavucontrol"
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    color: pavuHover.hovered ? Theme.bg : Theme.fg
                }

                HoverHandler {
                    id: pavuHover
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Actions.detached("nirarchy-launch-audio");
                        popupRoot.visible = false;
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "audiopopup"

        function toggle(): void {
            if (popupRoot.visible) {
                popupRoot.visible = false;
                return;
            }
            popupRoot.openAt((popupRoot.barWin?.width ?? 800) - popupRoot.implicitWidth);
        }
    }
}

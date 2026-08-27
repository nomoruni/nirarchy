import Quickshell
import QtQuick
import QtQuick.Layouts

PopupWindow {
    id: popupRoot

    property var barWin

    visible: false
    implicitWidth: 280
    implicitHeight: 260
    color: "transparent"
    grabFocus: false

    function openAt(x) {
        anchor.window = barWin ?? null;
        anchor.rect.x = Math.max(0, Math.min(x - 40, (barWin?.width ?? 1000) - implicitWidth - 8));
        anchor.rect.y = Theme.barHeight + 6;
        visible = true;
    }

    Rectangle {
        anchors.fill: parent
        radius: 0
        color: Theme.bg
        border.color: Theme.accent
        border.width: 1

        Column {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            // Header
            Item {
                width: parent.width
                height: 28

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Pomodoro"
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

            // Mode indicator
            Rectangle {
                width: parent.width
                height: 32
                radius: 0
                color: Theme.bgLight

                Row {
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Pomodoro.modeIcon()
                        font.family: Theme.fontFamily
                        font.pixelSize: 16
                        color: Pomodoro.mode === "work" ? Theme.red : Pomodoro.mode === "idle" ? Theme.dim : Theme.green
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Pomodoro.modeLabel()
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        color: Theme.fg
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "·"
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        color: Theme.dim
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Session " + (Pomodoro.sessions + 1) + "/" + Pomodoro.sessionsBeforeLong
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        color: Theme.dim
                    }
                }
            }

            // Timer display
            Rectangle {
                width: parent.width
                height: 70
                radius: 0
                color: "transparent"
                border.color: Pomodoro.running ? (Pomodoro.mode === "work" ? Theme.red : Theme.green) : Theme.dim
                border.width: 2

                Text {
                    anchors.centerIn: parent
                    text: Pomodoro.running ? Pomodoro.formattedTime() : "--:--"
                    font.family: Theme.fontFamily
                    font.pixelSize: 36
                    font.bold: true
                    color: Pomodoro.running ? (Pomodoro.mode === "work" ? Theme.red : Theme.green) : Theme.dim
                }
            }

            // Session dots
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8

                Repeater {
                    model: Pomodoro.sessionsBeforeLong

                    Rectangle {
                        width: 10
                        height: 10
                        radius: 0
                        color: index < Pomodoro.sessions ? Theme.accent : Theme.bgLight
                        border.color: Theme.dim
                        border.width: 1
                    }
                }
            }

            // Controls
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 10

                // Start/Pause
                Rectangle {
                    width: 80
                    height: 32
                    radius: 0
                    color: startHover.containsMouse ? Theme.accent : Theme.bgLight

                    Text {
                        anchors.centerIn: parent
                        text: Pomodoro.running ? "󰏤 Pause" : "󰐊 Start"
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        color: startHover.containsMouse ? Theme.bg : Theme.fg
                    }

                    HoverHandler {
                        id: startHover
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Pomodoro.start()
                    }
                }

                // Skip
                Rectangle {
                    width: 70
                    height: 32
                    radius: 0
                    color: skipHover.containsMouse ? Theme.bgLight : "transparent"
                    border.color: Theme.dim
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "󰓉 Skip"
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        color: Theme.fg
                    }

                    HoverHandler {
                        id: skipHover
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Pomodoro.skip()
                    }
                }

                // Reset
                Rectangle {
                    width: 70
                    height: 32
                    radius: 0
                    color: resetHover.containsMouse ? Theme.red : "transparent"
                    border.color: Theme.dim
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "󰦖 Reset"
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        color: resetHover.containsMouse ? Theme.bg : Theme.fg
                    }

                    HoverHandler {
                        id: resetHover
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Pomodoro.reset()
                    }
                }
            }
        }

        IpcHandler {
            target: "pomodoropopup"

            function toggle(): void {
                if (popupRoot.visible) {
                    popupRoot.visible = false;
                    return;
                }
                popupRoot.openAt((popupRoot.barWin?.width ?? 800) - popupRoot.implicitWidth);
            }
        }
    }
}

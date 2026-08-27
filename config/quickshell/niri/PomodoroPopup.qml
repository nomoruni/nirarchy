import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Io

PopupWindow {
    id: popupRoot

    property var barWin

    visible: false
    implicitWidth: 290
    implicitHeight: 400
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
            spacing: 8

            // Header
            Item {
                width: parent.width
                height: 26

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
                height: 30
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
                height: 60
                radius: 0
                color: "transparent"
                border.color: Pomodoro.running ? (Pomodoro.mode === "work" ? Theme.red : Theme.green) : Theme.dim
                border.width: 2

                Text {
                    anchors.centerIn: parent
                    text: Pomodoro.running ? Pomodoro.formattedTime() : "--:--"
                    font.family: Theme.fontFamily
                    font.pixelSize: 34
                    font.bold: true
                    color: Pomodoro.running ? (Pomodoro.mode === "work" ? Theme.red : Theme.green) : Theme.dim
                }
            }

            // Controls
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8

                // Start/Pause
                Rectangle {
                    width: 80
                    height: 30
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
                    width: 60
                    height: 30
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
                    width: 60
                    height: 30
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

            // Settings
            Rectangle {
                width: parent.width
                height: 3
                color: Theme.bgLight
            }

            Text {
                text: "Durations (minutes)"
                font.family: Theme.fontFamily
                font.pixelSize: 13
                font.bold: true
                color: Theme.fg
            }

            // Work duration stepper
            Item {
                width: parent.width
                height: 26

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰔛 Work"
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    color: Theme.red
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    StepBtn {
                        text: "−"
                        onDo: if (Pomodoro.workDuration > 1) { Pomodoro.workDuration = Pomodoro.workDuration - 60; Pomodoro.saveState(); }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 34
                        horizontalAlignment: Text.AlignHCenter
                        text: Math.round(Pomodoro.workDuration / 60)
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        color: Theme.fg
                    }

                    StepBtn {
                        text: "+"
                        onDo: { Pomodoro.workDuration = Pomodoro.workDuration + 60; Pomodoro.saveState(); }
                    }
                }
            }

            // Break duration stepper
            Item {
                width: parent.width
                height: 26

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰔠 Break"
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    color: Theme.green
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    StepBtn {
                        text: "−"
                        onDo: if (Pomodoro.breakDuration > 1) { Pomodoro.breakDuration = Pomodoro.breakDuration - 60; Pomodoro.saveState(); }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 34
                        horizontalAlignment: Text.AlignHCenter
                        text: Math.round(Pomodoro.breakDuration / 60)
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        color: Theme.fg
                    }

                    StepBtn {
                        text: "+"
                        onDo: { Pomodoro.breakDuration = Pomodoro.breakDuration + 60; Pomodoro.saveState(); }
                    }
                }
            }

            // Long break duration stepper
            Item {
                width: parent.width
                height: 26

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰈸 Long Break"
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    color: Theme.yellow
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    StepBtn {
                        text: "−"
                        onDo: if (Pomodoro.longBreakDuration > 1) { Pomodoro.longBreakDuration = Pomodoro.longBreakDuration - 60; Pomodoro.saveState(); }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 34
                        horizontalAlignment: Text.AlignHCenter
                        text: Math.round(Pomodoro.longBreakDuration / 60)
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        color: Theme.fg
                    }

                    StepBtn {
                        text: "+"
                        onDo: { Pomodoro.longBreakDuration = Pomodoro.longBreakDuration + 60; Pomodoro.saveState(); }
                    }
                }
            }

            // Sessions before long break stepper
            Item {
                width: parent.width
                height: 26

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰇚 Sessions"
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    color: Theme.accent
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    StepBtn {
                        text: "−"
                        onDo: if (Pomodoro.sessionsBeforeLong > 2) { Pomodoro.sessionsBeforeLong = Pomodoro.sessionsBeforeLong - 1; Pomodoro.saveState(); }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 34
                        horizontalAlignment: Text.AlignHCenter
                        text: Pomodoro.sessionsBeforeLong
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        color: Theme.fg
                    }

                    StepBtn {
                        text: "+"
                        onDo: { Pomodoro.sessionsBeforeLong = Pomodoro.sessionsBeforeLong + 1; Pomodoro.saveState(); }
                    }
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

    component StepBtn: Rectangle {
        property string text: ""
        property var onDo: null

        width: 22
        height: 22
        radius: 0
        color: stepHover.containsMouse ? Theme.accent : Theme.bgLight

        Text {
            anchors.centerIn: parent
            text: parent.text
            font.family: Theme.fontFamily
            font.pixelSize: 14
            color: stepHover.containsMouse ? Theme.bg : Theme.fg
        }

        HoverHandler {
            id: stepHover
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (parent.onDo)
                    parent.onDo();
            }
        }
    }
}

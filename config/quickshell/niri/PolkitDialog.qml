import Quickshell
import Quickshell.Services.Polkit
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: polkitRoot

    property var flow: agent.flow

    visible: flow !== null && flow.isResponseRequired
    implicitWidth: 420
    implicitHeight: 260
    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "nirarchy-polkit"

    PolkitAgent {
        id: agent
    }

    MouseArea {
        anchors.fill: parent
        onClicked: polkitRoot.dismiss()
    }

    Rectangle {
        anchors.centerIn: parent
        width: 400
        height: 240
        radius: 0
        color: Theme.bg
        border.color: Theme.accent
        border.width: 1
        visible: polkitRoot.flow !== null

        Column {
            anchors.centerIn: parent
            spacing: 16
            width: parent.width - 40

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 12

                Text {
                    text: "\u{F023}"
                    font.family: Theme.fontFamily
                    font.pixelSize: 28
                    color: Theme.accent
                    anchors.verticalCenter: parent.verticalCenter
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 280

                    Text {
                        text: polkitRoot.flow ? polkitRoot.flow.actionId : ""
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        font.bold: true
                        color: Theme.fg
                        width: parent.width
                        elide: Text.ElideRight
                    }

                    Text {
                        text: polkitRoot.flow ? polkitRoot.flow.message : ""
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        color: Theme.dim
                        width: parent.width
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                    }
                }
            }

            Text {
                visible: polkitRoot.flow && polkitRoot.flow.supplementaryIsError
                text: polkitRoot.flow ? polkitRoot.flow.supplementaryMessage : ""
                font.family: Theme.fontFamily
                font.pixelSize: 11
                color: Theme.red
                width: parent.width - 40
                anchors.horizontalCenter: parent.horizontalCenter
                wrapMode: Text.Wrap
            }

            Rectangle {
                width: parent.width
                height: 36
                radius: 0
                color: Theme.bgLight
                border.color: passField.activeFocus ? Theme.accent : Theme.dim
                border.width: 1
                visible: polkitRoot.flow && polkitRoot.flow.isResponseRequired

                TextInput {
                    id: passField
                    anchors.fill: parent
                    anchors.margins: 8
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: TextInput.Password
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    font.letterSpacing: 4
                    color: Theme.fg
                    selectionColor: Theme.accent
                    clip: true
                    focus: true

                    onAccepted: polkitRoot.submit()
                    Keys.onEscapePressed: polkitRoot.dismiss()
                }

                Text {
                    visible: !passField.text && !passField.activeFocus
                    text: polkitRoot.flow ? polkitRoot.flow.inputPrompt : "Password..."
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    color: Theme.dim
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 12
                visible: polkitRoot.flow && polkitRoot.flow.isResponseRequired

                Rectangle {
                    width: 120
                    height: 30
                    radius: 0
                    color: cancelArea.containsMouse ? Theme.bgLight : "transparent"
                    border.color: Theme.dim
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "Cancel"
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        color: Theme.fg
                    }

                    MouseArea {
                        id: cancelArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: polkitRoot.dismiss()
                    }
                }

                Rectangle {
                    width: 120
                    height: 30
                    radius: 0
                    color: submitArea.containsMouse ? Theme.accent : Theme.bgLight
                    border.color: Theme.accent
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "Authenticate"
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        color: submitArea.containsMouse ? Theme.bg : Theme.accent
                    }

                    MouseArea {
                        id: submitArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: polkitRoot.submit()
                    }
                }
            }
        }
    }

    onVisibleChanged: {
        if (!visible) passField.text = "";
    }

    function submit() {
        var pw = passField.text;
        passField.text = "";
        if (flow) {
            flow.submit(pw);
        }
    }

    function dismiss() {
        passField.text = "";
        if (flow) {
            flow.cancelAuthenticationRequest();
        }
    }
}

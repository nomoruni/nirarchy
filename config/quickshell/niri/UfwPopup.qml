import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls

PanelWindow {
    id: popupRoot

    property var barWin
    property string addPort: ""
    property string addProto: "tcp"
    property string addFrom: ""
    property string addAction: "allow"
    property bool showAddRule: false

    function confirmAdd() {
        if (popupRoot.addPort.trim() === "")
            return;
        UfwState.addRule(popupRoot.addAction, popupRoot.addPort.trim(), popupRoot.addProto, popupRoot.addFrom.trim());
        popupRoot.showAddRule = false;
        popupRoot.addPort = "";
        popupRoot.addFrom = "";
    }

    visible: false
    implicitWidth: 400
    implicitHeight: (showAddRule ? 568 : 440) + Theme.barHeight + 6
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "nirarchy-ufw"

    anchors {
        top: true
        right: true
    }
    function openAt(x) {
        visible = true;
        UfwState.refresh();
    }

    onVisibleChanged: {
        if (!visible)
            closed();
    }

    MouseArea {
        anchors.fill: parent
        onClicked: popupRoot.visible = false
    }

    Rectangle {
        anchors.fill: parent
        anchors.topMargin: Theme.barHeight + 6
        radius: 0
        color: Theme.bg
        border.color: Theme.accent
        border.width: 1

        Column {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            Item {
                width: parent.width
                height: 30

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Firewall"
                    font.family: Theme.fontFamily
                    font.pixelSize: 15
                    font.bold: true
                    color: Theme.fg
                }

                Rectangle {
                    id: refreshBtn

                    anchors.right: closeBtn.left
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    width: 30
                    height: 22
                    radius: 0
                    color: refreshHover.containsMouse ? Theme.bgLight : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "󰑐"
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        color: Theme.fg
                    }

                    HoverHandler { id: refreshHover }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: UfwState.refresh()
                    }
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

                    HoverHandler { id: closeHover }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: popupRoot.visible = false
                    }
                }
            }

            // Status bar
            Rectangle {
                width: parent.width
                height: 34
                radius: 0
                color: Theme.bgLight

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: UfwState.enabled ? "  Active" : "  Inactive"
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    color: UfwState.enabled ? Theme.green : Theme.red
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    width: 70
                    height: 24
                    radius: 0
                    color: toggleMouse.containsMouse ? (UfwState.enabled ? Theme.red : Theme.green) : Theme.bgLight

                    Text {
                        anchors.centerIn: parent
                        text: UfwState.enabled ? "Disable" : "Enable"
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        color: toggleMouse.containsMouse ? Theme.bg : Theme.fg
                    }

                    MouseArea {
                        id: toggleMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: UfwState.toggleUfw()
                    }
                }
            }

            // Defaults
            Row {
                spacing: 20

                Text {
                    text: "In: " + UfwState.defaultIncoming + "  Out: " + UfwState.defaultOutgoing
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    color: Theme.dim
                }

                Text {
                    text: "Log: " + UfwState.logging
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    color: Theme.dim
                }
            }

            // Rules header
            Text {
                text: "Rules (" + UfwState.rules.length + ")"
                font.family: Theme.fontFamily
                font.pixelSize: 12
                font.bold: true
                color: Theme.fg
            }

            // Rules list
            ListView {
                width: parent.width
                height: popupRoot.showAddRule ? 80 : Math.max(100, popupRoot.height - 260)
                clip: true
                spacing: 2
                model: UfwState.rules

                delegate: Rectangle {
                    id: ruleRow

                    required property var modelData

                    width: ListView.view.width
                    height: 32
                    radius: 0
                    color: ruleHover.containsMouse ? Theme.bgLight : "transparent"

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: ruleRow.modelData.action === "ALLOW" ? "󰒓" : "󰅗"
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            color: ruleRow.modelData.action === "ALLOW" ? Theme.green : Theme.red
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 220
                            elide: Text.ElideRight
                            text: ruleRow.modelData.action + " " + ruleRow.modelData.to
                                  + (ruleRow.modelData.from !== "" && ruleRow.modelData.from !== "Anywhere" ? " from " + ruleRow.modelData.from : "")
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            color: Theme.fg
                        }
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.rightMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        width: 56
                        height: 20
                        radius: 0
                        color: delMouse.containsMouse ? Theme.red : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "Delete"
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            color: delMouse.containsMouse ? Theme.bg : Theme.dim
                        }

                        MouseArea {
                            id: delMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: UfwState.deleteRule(ruleRow.modelData.num)
                        }
                    }

                    HoverHandler { id: ruleHover }
                }

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }
            }

            // Add rule button
            Rectangle {
                width: parent.width
                height: 30
                radius: 0
                color: addBtnHover.containsMouse ? Theme.accent : Theme.bgLight

                Text {
                    anchors.centerIn: parent
                    text: popupRoot.showAddRule ? "Cancel" : "Add Rule"
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    font.bold: true
                    color: addBtnHover.containsMouse ? Theme.bg : Theme.fg
                }

                HoverHandler { id: addBtnHover }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: popupRoot.showAddRule = !popupRoot.showAddRule
                }
            }

            // Add rule form
            Column {
                visible: popupRoot.showAddRule
                width: parent.width
                spacing: 8

                Text {
                    text: "Action"
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    color: Theme.dim
                }

                Row {
                    width: parent.width
                    spacing: 4

                    Rectangle {
                        id: allowSeg

                        width: (parent.width - 8) / 3
                        height: 26
                        radius: 0
                        border.color: popupRoot.addAction === "allow" ? Theme.green : Theme.dim
                        border.width: 1
                        color: popupRoot.addAction === "allow" ? Theme.green : Theme.bg

                        Text {
                            anchors.centerIn: parent
                            text: "ALLOW"
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.bold: true
                            color: popupRoot.addAction === "allow" ? Theme.bg : Theme.fg
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: popupRoot.addAction = "allow"
                        }
                    }

                    Rectangle {
                        id: denySeg

                        width: (parent.width - 8) / 3
                        height: 26
                        radius: 0
                        border.color: popupRoot.addAction === "deny" ? Theme.red : Theme.dim
                        border.width: 1
                        color: popupRoot.addAction === "deny" ? Theme.red : Theme.bg

                        Text {
                            anchors.centerIn: parent
                            text: "DENY"
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.bold: true
                            color: popupRoot.addAction === "deny" ? Theme.bg : Theme.fg
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: popupRoot.addAction = "deny"
                        }
                    }

                    Rectangle {
                        id: rejectSeg

                        width: (parent.width - 8) / 3
                        height: 26
                        radius: 0
                        border.color: popupRoot.addAction === "reject" ? Theme.yellow : Theme.dim
                        border.width: 1
                        color: popupRoot.addAction === "reject" ? Theme.yellow : Theme.bg

                        Text {
                            anchors.centerIn: parent
                            text: "REJECT"
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.bold: true
                            color: popupRoot.addAction === "reject" ? Theme.bg : Theme.fg
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: popupRoot.addAction = "reject"
                        }
                    }
                }

                Text {
                    text: "Port or range"
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    color: Theme.dim
                }

                Rectangle {
                    width: parent.width
                    height: 32
                    radius: 0
                    color: Theme.bg
                    border.color: portField.activeFocus ? Theme.accent : Theme.dim
                    border.width: 1

                    TextInput {
                        id: portField

                        anchors.fill: parent
                        anchors.margins: 8
                        verticalAlignment: TextInput.AlignVCenter
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        color: Theme.fg
                        selectionColor: Theme.accent
                        clip: true

                        onTextChanged: popupRoot.addPort = text
                        Keys.onReturnPressed: popupRoot.confirmAdd()
                        Keys.onEnterPressed: popupRoot.confirmAdd()
                    }

                    Text {
                        visible: !portField.text && !portField.activeFocus
                        text: "e.g. 22, 80, 8080-8090"
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        color: Theme.dim
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                    }
                }

                Text {
                    text: "Protocol"
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    color: Theme.dim
                }

                Row {
                    width: parent.width
                    spacing: 4

                    Rectangle {
                        width: (parent.width - 8) / 3
                        height: 26
                        radius: 0
                        border.color: popupRoot.addProto === "tcp" ? Theme.accent : Theme.dim
                        border.width: 1
                        color: popupRoot.addProto === "tcp" ? Theme.accent : Theme.bg

                        Text {
                            anchors.centerIn: parent
                            text: "TCP"
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.bold: true
                            color: popupRoot.addProto === "tcp" ? Theme.bg : Theme.fg
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: popupRoot.addProto = "tcp"
                        }
                    }

                    Rectangle {
                        width: (parent.width - 8) / 3
                        height: 26
                        radius: 0
                        border.color: popupRoot.addProto === "udp" ? Theme.accent : Theme.dim
                        border.width: 1
                        color: popupRoot.addProto === "udp" ? Theme.accent : Theme.bg

                        Text {
                            anchors.centerIn: parent
                            text: "UDP"
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.bold: true
                            color: popupRoot.addProto === "udp" ? Theme.bg : Theme.fg
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: popupRoot.addProto = "udp"
                        }
                    }

                    Rectangle {
                        width: (parent.width - 8) / 3
                        height: 26
                        radius: 0
                        border.color: popupRoot.addProto === "both" ? Theme.accent : Theme.dim
                        border.width: 1
                        color: popupRoot.addProto === "both" ? Theme.accent : Theme.bg

                        Text {
                            anchors.centerIn: parent
                            text: "BOTH"
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.bold: true
                            color: popupRoot.addProto === "both" ? Theme.bg : Theme.fg
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: popupRoot.addProto = "both"
                        }
                    }
                }

                Text {
                    text: "From (optional)"
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    color: Theme.dim
                }

                Rectangle {
                    width: parent.width
                    height: 32
                    radius: 0
                    color: Theme.bg
                    border.color: fromField.activeFocus ? Theme.accent : Theme.dim
                    border.width: 1

                    TextInput {
                        id: fromField

                        anchors.fill: parent
                        anchors.margins: 8
                        verticalAlignment: TextInput.AlignVCenter
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        color: Theme.fg
                        selectionColor: Theme.accent
                        clip: true

                        onTextChanged: popupRoot.addFrom = text
                        Keys.onReturnPressed: popupRoot.confirmAdd()
                        Keys.onEnterPressed: popupRoot.confirmAdd()
                    }

                    Text {
                        visible: !fromField.text && !fromField.activeFocus
                        text: "e.g. 192.168.1.0/24 (leave empty for Anywhere)"
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        color: Theme.dim
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 28
                    radius: 0
                    color: confirmMouse.containsMouse ? Theme.green : Theme.accent

                    Text {
                        anchors.centerIn: parent
                        text: "Add Rule"
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        font.bold: true
                        color: Theme.bg
                    }

                    MouseArea {
                        id: confirmMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: popupRoot.confirmAdd()
                    }
                }
            }
        }

        IpcHandler {
            target: "ufw"

            function toggle(): void {
                if (popupRoot.visible) {
                    popupRoot.visible = false;
                    return;
                }
                popupRoot.openAt();
            }
        }
    }
}

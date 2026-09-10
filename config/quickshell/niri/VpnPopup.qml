import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls

PanelWindow {
    id: popupRoot

    property var barWin
    property real openX: 0

    visible: false
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "nirarchy-vpn"
    implicitWidth: 1920
    implicitHeight: 1080

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    function openAt(x) {
        popupRoot.openX = x ?? 800;
        visible = true;
        VpnState.refresh();
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
        id: contentBox

        x: Math.max(0, Math.min(popupRoot.openX - 20, popupRoot.width - 408))
        y: Theme.barHeight + 6
        width: 400
        height: 320
        radius: 0
        color: Theme.bg
        border.color: Theme.accent
        border.width: 1

        Column {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            // Header
            Item {
                width: parent.width
                height: 30

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "VPN"
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
                    text: VpnState.connected ? "  Connected" : "  Disconnected"
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    color: VpnState.connected ? Theme.green : Theme.red
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    width: 80
                    height: 24
                    radius: 0
                    color: toggleMouse.containsMouse ? (VpnState.connected ? Theme.red : Theme.green) : Theme.bgLight

                    Text {
                        anchors.centerIn: parent
                        text: VpnState.connected ? "Disconnect" : "Connect"
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        color: toggleMouse.containsMouse ? Theme.bg : Theme.fg
                    }

                    MouseArea {
                        id: toggleMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: VpnState.toggle()
                    }
                }
            }

            // Connection info (when connected)
            Column {
                visible: VpnState.connected
                width: parent.width
                spacing: 6

                Row {
                    spacing: 8

                    Text {
                        text: "Server:"
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                        color: Theme.dim
                        width: 50
                    }

                    Text {
                        text: VpnState.server || "—"
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        color: Theme.fg
                        width: parent.width - 58
                        elide: Text.ElideRight
                    }
                }

                Row {
                    spacing: 8

                    Text {
                        text: "Load:"
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                        color: Theme.dim
                        width: 50
                    }

                    Text {
                        text: VpnState.load || "—"
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        color: Theme.fg
                    }
                }

                Row {
                    spacing: 8

                    Text {
                        text: "Proto:"
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                        color: Theme.dim
                        width: 50
                    }

                    Text {
                        text: VpnState.protocol || "—"
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        color: Theme.fg
                    }
                }
            }

            // Status output
            Text {
                visible: VpnState.lastOutput !== ""
                width: parent.width
                wrapMode: Text.Wrap
                text: VpnState.lastOutput
                font.family: Theme.fontFamily
                font.pixelSize: 10
                color: /error|failed/i.test(VpnState.lastOutput) ? Theme.red : Theme.dim
            }

            // Refresh button
            Rectangle {
                width: parent.width
                height: 28
                radius: 0
                color: refreshMouse.containsMouse ? Theme.accent : Theme.bgLight

                Text {
                    anchors.centerIn: parent
                    text: "Refresh"
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    font.bold: true
                    color: refreshMouse.containsMouse ? Theme.bg : Theme.fg
                }

                MouseArea {
                    id: refreshMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: VpnState.refresh()
                }
            }
        }
    }

    IpcHandler {
        target: "vpn"

        function toggle(): void {
            if (popupRoot.visible) {
                popupRoot.visible = false;
                return;
            }
            popupRoot.openAt();
        }
    }
}

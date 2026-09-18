import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls

PanelWindow {
    id: popupRoot

    property var barWin
    property real openX: 0
    property string serverDisplay: ""
    property string loadDisplay: ""
    property string protoDisplay: ""
    property bool vpnConnected: false

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

    function refreshStatus() {
        statusProc.running = true;
    }

    function openAt(x) {
        popupRoot.openX = x ?? 800;
        visible = true;
        refreshStatus();
    }

    onVisibleChanged: {
        if (!visible)
            closed();
    }

    readonly property Process statusProc: Process {
        command: ["sh", "-c", "protonvpn status 2>&1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                popupRoot.vpnConnected = false;
                popupRoot.serverDisplay = "";
                popupRoot.loadDisplay = "";
                popupRoot.protoDisplay = "";
                for (let i = 0; i < lines.length; i++) {
                    const l = lines[i].trim();
                    if (l.startsWith("Status:"))
                        popupRoot.vpnConnected = /^connected$/i.test(l.slice(7).trim());
                    else if (l.startsWith("Server:"))
                        popupRoot.serverDisplay = l.slice(7).trim();
                    else if (l.startsWith("Load:"))
                        popupRoot.loadDisplay = l.slice(5).trim();
                    else if (l.startsWith("Protocol:"))
                        popupRoot.protoDisplay = l.slice(9).trim();
                }
            }
        }
    }

    readonly property Process cmdProc: Process {
        command: ["true"]
        stdout: StdioCollector {
            onStreamFinished: {
                popupRoot.refreshStatus();
            }
        }
    }

    Timer {
        interval: 20000
        running: popupRoot.visible
        repeat: true
        onTriggered: popupRoot.refreshStatus()
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
                    text: popupRoot.vpnConnected ? "  Connected" : "  Disconnected"
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    color: popupRoot.vpnConnected ? Theme.green : Theme.red
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    width: 80
                    height: 24
                    radius: 0
                    color: popupRoot.vpnConnected ? Theme.red : Theme.green

                    Text {
                        anchors.centerIn: parent
                        text: popupRoot.vpnConnected ? "Disconnect" : "Connect"
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

            // Server info (when connected)
            Column {
                visible: popupRoot.vpnConnected
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
                        text: popupRoot.serverDisplay || "—"
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
                        text: popupRoot.loadDisplay || "—"
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
                        text: popupRoot.protoDisplay || "—"
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
                    onClicked: popupRoot.refreshStatus()
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

import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls

PopupWindow {
    id: popupRoot

    property var barWin
    property string wifiState: "enabled"
    property string currentNet: ""
    property var networks: []

    visible: false
    implicitWidth: 380
    implicitHeight: 440
    color: "transparent"
    grabFocus: false

    function openAt(x) {
        anchor.window = barWin ?? null;
        anchor.rect.x = Math.max(0, Math.min(x - 20, (barWin?.width ?? 1000) - implicitWidth - 8));
        anchor.rect.y = Theme.barHeight + 6;
        visible = true;
        refresh();
    }

    function refresh() {
        statusProc.running = true;
        listProc.running = true;
    }

    onVisibleChanged: {
        if (!visible)
            bar.wifiBtnOpen = false;
    }

    function netGlyph(sig) {
        return sig >= 80 ? "󰤨" : sig >= 60 ? "󰤥" : sig >= 40 ? "󰤢" : sig >= 20 ? "󰤟" : "󰤯";
    }

    readonly property Process statusProc: Process {
        command: ["sh", "-c", "echo $(nmcli -t -f WIFI g status); echo $(nmcli -t -f NAME,TYPE connection show --active | grep 802-11-wireless | cut -d: -f1)"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                popupRoot.wifiState = lines[0]?.trim() || "disabled";
                popupRoot.currentNet = lines[1]?.trim() || "";
            }
        }
    }

    readonly property Process listProc: Process {
        command: ["sh", "-c", "nmcli -t -f IN-USE,SIGNAL,SSID,SECURITY device wifi list --rescan no 2>/dev/null | awk -F: '$3 != \"\"' | sort -t: -k2,2rn | awk -F: '!seen[$3]++'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const rows = [];
                const lines = text.trim().split("\n");
                for (let i = 0; i < lines.length; i++) {
                    if (!lines[i])
                        continue;
                    const p = lines[i].split(":");
                    rows.push({
                        "inUse": p[0] === "*",
                        "signal": parseInt(p[1]) || 0,
                        "ssid": p[2],
                        "secured": p[3] !== "" && p[3] !== "--"
                    });
                }
                popupRoot.networks = rows;
            }
        }
    }

    readonly property Process passProc: Process {
        property string ssid: ""

        command: ["true"]
        stdout: StdioCollector {
            onStreamFinished: {
                const pass = text.trim();
                if (pass !== "")
                    popupRoot.doConnect(passProc.ssid, pass);
            }
        }
    }

    function toggleWifi() {
        Actions.run("nmcli radio wifi " + (wifiState === "enabled" ? "off" : "on"));
        refreshTimer.restart();
    }

    function connectTo(net) {
        if (net.secured) {
            passProc.ssid = net.ssid;
            passProc.command = ["nirarchy-menu-input", "Password for " + net.ssid];
            passProc.running = true;
        } else {
            doConnect(net.ssid, "");
        }
    }

    function doConnect(ssid, pass) {
        const q = ssid.replace(/'/g, "'\\''");
        const cmd = pass !== "" ? "nmcli device wifi connect '" + q + "' password '" + pass.replace(/'/g, "'\\''") + "'" : "nmcli device wifi connect '" + q + "'";
        const qs2 = ssid.replace(/'/g, "");
        Actions.run(cmd + " && notify-send -u low 'WiFi' 'Connected to " + qs2 + "' || notify-send -u critical 'WiFi' 'Failed to connect to " + qs2 + "'");
        refreshTimer.restart();
    }

    function disconnectCurrent() {
        if (currentNet !== "")
            Actions.run("nmcli connection down id '" + currentNet.replace(/'/g, "'\\''") + "'");
        refreshTimer.restart();
    }

    Timer {
        id: refreshTimer

        interval: 4000
        repeat: true
        running: popupRoot.visible
        onTriggered: popupRoot.refresh()
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
            spacing: 10

            Item {
                width: parent.width
                height: 30

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Wi-Fi"
                    font.family: Theme.fontFamily
                    font.pixelSize: 15
                    font.bold: true
                    color: Theme.fg
                }

                Rectangle {
                    anchors.right: rescanBtn.left
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    width: 44
                    height: 22
                    radius: 0
                    color: popupRoot.wifiState === "enabled" ? Theme.accent : Theme.dim
                    Behavior on color {
                        ColorAnimation {
                            duration: 120
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: popupRoot.wifiState === "enabled" ? "ON" : "OFF"
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        font.bold: true
                        color: Theme.bg
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: popupRoot.toggleWifi()
                    }
                }

                Rectangle {
                    id: rescanBtn

                    anchors.right: closeBtn.left
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    width: 30
                    height: 22
                    radius: 0
                    color: rescanHover.containsMouse ? Theme.bgLight : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "󰑐"
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        color: Theme.fg
                    }

                    HoverHandler {
                        id: rescanHover
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Actions.run("nmcli device wifi rescan");
                            popupRoot.refreshTimer.restart();
                        }
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

            Rectangle {
                visible: popupRoot.currentNet !== ""
                width: parent.width
                height: 34
                radius: 0
                color: Theme.bgLight

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰤨  " + popupRoot.currentNet
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    color: Theme.green
                    elide: Text.ElideRight
                    width: parent.width - 110
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    width: 86
                    height: 24
                    radius: 0
                    color: discMouse.containsMouse ? Theme.red : Theme.bgLight

                    Text {
                        anchors.centerIn: parent
                        text: "Disconnect"
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        color: Theme.fg
                    }

                    MouseArea {
                        id: discMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: popupRoot.disconnectCurrent()
                    }
                }
            }

            ListView {
                width: parent.width
                height: parent.height - (popupRoot.currentNet !== "" ? 44 : 40)
                clip: true
                spacing: 2
                model: popupRoot.networks

                delegate: Rectangle {
                    id: netRow

                    required property var modelData

                    width: ListView.view.width
                    height: 32
                    radius: 0
                    color: netMouse.containsMouse ? Theme.bgLight : "transparent"

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: popupRoot.netGlyph(netRow.modelData.signal)
                            font.family: Theme.fontFamily
                            font.pixelSize: 15
                            color: netRow.modelData.inUse ? Theme.green : Theme.fg
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 230
                            elide: Text.ElideRight
                            text: netRow.modelData.ssid
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            color: netRow.modelData.inUse ? Theme.green : Theme.fg
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: netRow.modelData.secured ? "󰌾" : ""
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            color: Theme.dim
                        }
                    }

                    MouseArea {
                        id: netMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: popupRoot.connectTo(netRow.modelData)
                    }
                }

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }
            }
        }

        IpcHandler {
            target: "netpopup"

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

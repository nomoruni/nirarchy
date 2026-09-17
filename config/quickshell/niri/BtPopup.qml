import Quickshell
import Quickshell.Io
import QtQuick.Controls
import QtQuick

PopupWindow {
    id: popupRoot

    property var barWin
    property bool powered: false
    property bool scanning: false
    property var devices: []


    visible: false
    implicitWidth: 380
    implicitHeight: 420
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
        stateProc.running = true;
        devProc.running = true;
    }

    onVisibleChanged: {
        if (!visible)
            closed();
    }

    readonly property Process stateProc: Process {
        command: ["sh", "-c", "bluetoothctl show | grep -q 'Powered: yes' && echo on || echo off"]
        stdout: StdioCollector {
            onStreamFinished: popupRoot.powered = text.trim() === "on"
        }
    }

    readonly property Process devProc: Process {
        command: ["sh", "-c", "bluetoothctl devices Paired 2>/dev/null | sed 's/^Device /P /'; bluetoothctl devices Trusted 2>/dev/null | sed 's/^Device /T /'; bluetoothctl devices 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                const paired = {};
                const trusted = {};
                const seen = {};
                const rows = [];
                for (let i = 0; i < lines.length; i++) {
                    let m = lines[i].match(/^P (\S+)/);
                    if (m) {
                        paired[m[1]] = true;
                        continue;
                    }
                    m = lines[i].match(/^T (\S+)/);
                    if (m) {
                        trusted[m[1]] = true;
                        continue;
                    }
                    m = lines[i].match(/^Device\s+(\S+)\s+(.*)$/);
                    if (!m)
                        continue;
                    if (seen[m[1]])
                        continue;
                    seen[m[1]] = true;
                    rows.push({
                        "mac": m[1],
                        "name": m[2],
                        "connected": false,
                        "paired": !!paired[m[1]],
                        "trusted": !!trusted[m[1]]
                    });
                }
                getConn.command = ["sh", "-c", "bluetoothctl devices Connected"];
                getConn.rows = rows;
                getConn.running = true;
            }
        }
    }

    property Process getConn: Process {
        property var rows: []

        command: ["true"]
        stdout: StdioCollector {
            onStreamFinished: {
                const conns = {};
                const lines = text.trim().split("\n");
                for (let i = 0; i < lines.length; i++) {
                    const m = lines[i].match(/^Device\s+(\S+)/);
                    if (m)
                        conns[m[1]] = true;
                }
                for (let j = 0; j < getConn.rows.length; j++)
                    getConn.rows[j].connected = !!conns[getConn.rows[j].mac];
                popupRoot.devices = getConn.rows.slice();
            }
        }
    }

    readonly property Process scanProc: Process {
        command: ["true"]
        stdout: StdioCollector {
            onStreamFinished: {
                popupRoot.scanning = false;
                popupRoot.refresh();
            }
        }
    }

    function togglePower() {
        Actions.run("bluetoothctl power " + (powered ? "off" : "on"));
        refreshTimer.restart();
    }

    function toggleScan() {
        if (scanning) {
            Actions.run("bluetoothctl scan off");
            scanProc.running = false;
            scanning = false;
        } else {
            // Plain `bluetoothctl scan on` only sets the discovery filter and
            // never starts discovery when run detached; --timeout actually scans.
            scanProc.command = ["sh", "-c", "bluetoothctl --timeout 30 scan on"];
            scanProc.running = true;
            scanning = true;
        }
        refreshTimer.restart();
    }

    function connectDev(d) {
        Actions.run("timeout 10 bluetoothctl connect " + d.mac + " && notify-send -u low 'Bluetooth' 'Connected to " + d.name.replace(/'/g, "") + "' || notify-send -u critical 'Bluetooth' 'Failed to connect'");
        refreshTimer.restart();
    }

    function disconnectDev(d) {
        Actions.run("bluetoothctl disconnect " + d.mac);
        refreshTimer.restart();
    }

    function pairDev(d) {
        Actions.run("notify-send -u low 'Bluetooth' 'Pairing with " + d.name.replace(/'/g, "") + "…'; timeout 15 bluetoothctl pair " + d.mac + " && timeout 10 bluetoothctl trust " + d.mac + " && timeout 10 bluetoothctl connect " + d.mac + " && notify-send -u low 'Bluetooth' 'Paired " + d.name.replace(/'/g, "") + "' || notify-send -u critical 'Bluetooth' 'Pairing failed'");
        refreshTimer.restart();
    }

    function trustDev(d, on) {
        Actions.run("bluetoothctl " + (on ? "trust" : "untrust") + " " + d.mac);
        refreshTimer.restart();
    }

    Timer {
        id: refreshTimer

        interval: 5000
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
                    text: "Bluetooth"
                    font.family: Theme.fontFamily
                    font.pixelSize: 15
                    font.bold: true
                    color: Theme.fg
                }

                Rectangle {
                    anchors.right: scanBtn.left
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    width: 44
                    height: 22
                    radius: 0
                    color: popupRoot.powered ? Theme.accent : Theme.dim
                    Behavior on color {
                        ColorAnimation {
                            duration: 120
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: popupRoot.powered ? "ON" : "OFF"
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        font.bold: true
                        color: Theme.bg
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: popupRoot.togglePower()
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

                Rectangle {
                    id: scanBtn

                    anchors.right: closeBtn.left
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    width: 30
                    height: 22
                    radius: 0
                    color: scanHover.containsMouse ? Theme.bgLight : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: popupRoot.scanning ? "󰔟" : "󰍺"
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        color: popupRoot.scanning ? Theme.accent : Theme.fg
                    }

                    HoverHandler {
                        id: scanHover
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: popupRoot.toggleScan()
                    }
                }
            }

            ListView {
                width: parent.width
                height: parent.height - 40
                clip: true
                spacing: 2
                model: popupRoot.devices

                delegate: Rectangle {
                    id: devRow

                    required property var modelData

                    width: ListView.view.width
                    height: 36
                    radius: 0
                    color: devMouse.containsMouse ? Theme.bgLight : "transparent"

                    // Row-wide hover/press backdrop. Declared FIRST so it sits
                    // behind the interactive elements and doesn't steal clicks.
                    MouseArea {
                        id: devMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {}
                        onPressed: devRow.scale = 0.98
                        onReleased: devRow.scale = 1.0
                        onCanceled: devRow.scale = 1.0

                        Behavior on scale {
                            NumberAnimation { duration: 100; easing.type: Easing.OutQuad }
                        }
                    }

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        spacing: 8

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: devRow.modelData.connected ? "󰂱" : "󰂯"
                            font.family: Theme.fontFamily
                            font.pixelSize: 15
                            color: devRow.modelData.connected ? Theme.green : Theme.fg
                        }

                        Column {
                            width: 150
                            spacing: 0
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                width: parent.width
                                elide: Text.ElideRight
                                text: devRow.modelData.name
                                font.family: Theme.fontFamily
                                font.pixelSize: 13
                                color: devRow.modelData.connected ? Theme.green : Theme.fg
                            }

                            Text {
                                text: devRow.modelData.connected ? "Connected" : devRow.modelData.paired ? "Paired" : "Not paired"
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                color: devRow.modelData.connected ? Theme.green : devRow.modelData.paired ? Theme.dim : Theme.dim
                            }
                        }

                        Item {
                            width: 50
                            height: 24

                            Rectangle {
                                anchors.fill: parent
                                radius: 0
                                color: trustAct.containsMouse ? Theme.accent : Theme.bgLight

                                Text {
                                    anchors.centerIn: parent
                                    text: devRow.modelData.trusted ? "Trusted" : "Trust"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    color: devRow.modelData.trusted ? Theme.green : trustAct.containsMouse ? Theme.bg : Theme.fg
                                }
                            }

                            MouseArea {
                                id: trustAct

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: popupRoot.trustDev(devRow.modelData, !devRow.modelData.trusted)
                                onPressed: trustAct.parent.scale = 0.9
                                onReleased: trustAct.parent.scale = 1.0
                                onCanceled: trustAct.parent.scale = 1.0
                            }

                            Behavior on scale {
                                NumberAnimation { duration: 100; easing.type: Easing.OutQuad }
                            }
                        }

                        Item {
                            width: 66
                            height: 24

                            Rectangle {
                                anchors.fill: parent
                                radius: 0
                                color: devAct.containsMouse ? Theme.accent : Theme.bgLight

                                Text {
                                    anchors.centerIn: parent
                                    text: devRow.modelData.connected ? "Disconnect" : devRow.modelData.paired ? "Connect" : "Pair"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    color: devAct.containsMouse ? Theme.bg : Theme.fg
                                }
                            }

                            MouseArea {
                                id: devAct

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (devRow.modelData.connected)
                                        popupRoot.disconnectDev(devRow.modelData);
                                    else if (devRow.modelData.paired)
                                        popupRoot.connectDev(devRow.modelData);
                                    else
                                        popupRoot.pairDev(devRow.modelData);
                                }
                                onPressed: devAct.parent.scale = 0.9
                                onReleased: devAct.parent.scale = 1.0
                                onCanceled: devAct.parent.scale = 1.0
                            }

                            Behavior on scale {
                                NumberAnimation { duration: 100; easing.type: Easing.OutQuad }
                            }
                        }
                    }
                }

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }
            }
        }
    }
    IpcHandler {
        target: "btpopup"

        function toggle(): void {
            if (popupRoot.visible) {
                popupRoot.visible = false;
                return;
            }
            popupRoot.openAt((popupRoot.barWin?.width ?? 800) - popupRoot.implicitWidth);
        }
    }
}

import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls

PopupWindow {
    id: popupRoot

    property var barWin
    property string printerStatus: "unknown"
    property string printerModel: "Printer"
    property string printerDevice: ""
    property var jobs: []

    visible: false
    implicitWidth: 380
    implicitHeight: 500
    color: "transparent"
    grabFocus: false

    property string printerQueue: "EPSON_L3250_Series"

    function openAt(x) {
        anchor.window = barWin ?? null;
        anchor.rect.x = Math.max(0, Math.min(x - 20, (barWin?.width ?? 1000) - implicitWidth - 8));
        anchor.rect.y = Theme.barHeight + 6;
        visible = true;
        refresh();
    }

    function refresh() {
        statusProc.running = true;
        jobsProc.running = true;
    }

    function cancelJob(jobId) {
        Actions.run("cancel " + jobId);
        Qt.callLater(function() { refresh(); });
    }

    onVisibleChanged: {
        if (!visible)
            closed();
    }

    Component.onCompleted: refresh()

    readonly property Process statusProc: Process {
        command: ["sh", "-c",
            "echo $(lpstat -p " + printerQueue + " 2>/dev/null); " +
            "echo $(lpstat -l -p " + printerQueue + " 2>/dev/null | grep -i 'Description:' | sed 's/.*Description:\\s*//'); " +
            "echo $(lpstat -p " + printerQueue + " -v 2>/dev/null | sed 's/.*device for .*: //')"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                const statusLine = lines[0] || "";
                if (statusLine.includes("idle")) popupRoot.printerStatus = "idle";
                else if (statusLine.includes("printing")) popupRoot.printerStatus = "printing";
                else if (statusLine.includes("stopped")) popupRoot.printerStatus = "stopped";
                else if (statusLine.includes("disabled")) popupRoot.printerStatus = "offline";
                else popupRoot.printerStatus = "unknown";

                popupRoot.printerModel = lines[1]?.trim() || "EPSON L3250 Series";
                popupRoot.printerDevice = lines[2]?.trim() || "";
            }
        }
    }

    readonly property Process jobsProc: Process {
        command: ["sh", "-c", "lpstat -W not-completed 2>/dev/null | grep -i '" + printerQueue + "' || true"]
        stdout: StdioCollector {
            onStreamFinished: {
                const rows = [];
                const lines = text.trim().split("\n");
                for (let i = 0; i < lines.length; i++) {
                    if (!lines[i])
                        continue;
                    const p = lines[i].trim().split(/\s+/);
                    if (p.length >= 3) {
                        rows.push({
                            "id": p[0].split("-").pop(),
                            "user": p[1],
                            "size": p[2],
                            "date": p.slice(3).join(" ")
                        });
                    }
                }
                popupRoot.jobs = rows;
            }
        }
    }

    function statusIcon() {
        return "";
    }

    function statusColor() {
        if (printerStatus === "idle") return Theme.green;
        if (printerStatus === "printing") return Theme.accent;
        if (printerStatus === "stopped") return Theme.yellow;
        if (printerStatus === "offline") return Theme.red;
        return Theme.dim;
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
                    text: "Printer"
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
                        onClicked: popupRoot.refresh()
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
                    text: statusIcon() + "  " + printerModel + " — " + printerStatus
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    color: statusColor()
                    elide: Text.ElideRight
                    width: parent.width - 100
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    width: 86
                    height: 24
                    radius: 0
                    color: queueMouse.containsMouse ? Theme.accent : Theme.bgLight

                    Text {
                        anchors.centerIn: parent
                        text: "Queue"
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        color: queueMouse.containsMouse ? Theme.bg : Theme.fg
                    }

                    MouseArea {
                        id: queueMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Actions.detached("xdg-open http://localhost:631")
                    }
                }
            }

            // Device
            Text {
                visible: printerDevice !== ""
                width: parent.width
                text: printerDevice.length > 60 ? printerDevice.substring(0, 57) + "..." : printerDevice
                font.family: Theme.fontFamily
                font.pixelSize: 10
                color: Theme.dim
                elide: Text.ElideRight
            }

            // Active Jobs
            Text {
                width: parent.width
                text: "Active Jobs" + (jobs.length > 0 ? " (" + jobs.length + ")" : "")
                font.family: Theme.fontFamily
                font.pixelSize: 12
                font.bold: true
                color: Theme.fg
            }

            Text {
                visible: jobs.length === 0
                width: parent.width
                text: printerStatus === "printing" ? "Printing..." : "No active jobs"
                font.family: Theme.fontFamily
                font.pixelSize: 11
                color: printerStatus === "printing" ? Theme.accent : Theme.dim
            }

            Repeater {
                model: jobs

                delegate: Rectangle {
                    id: jobRow

                    required property var modelData

                    width: parent.width
                    height: 34
                    radius: 0
                    color: jobHover.containsMouse ? Theme.bgLight : "transparent"

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "󰈙"
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            color: Theme.accent
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 180
                            elide: Text.ElideMiddle
                            text: "#" + jobRow.modelData.id + " · " + jobRow.modelData.user
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            color: Theme.fg
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: jobRow.modelData.size + "B"
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            color: Theme.dim
                        }
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.rightMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        width: 60
                        height: 22
                        radius: 0
                        color: cancelMouse.containsMouse ? Theme.red : Theme.bgLight

                        Text {
                            anchors.centerIn: parent
                            text: "Cancel"
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            color: cancelMouse.containsMouse ? Theme.bg : Theme.fg
                        }

                        MouseArea {
                            id: cancelMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: popupRoot.cancelJob(jobRow.modelData.id)
                        }
                    }

                    HoverHandler { id: jobHover }
                }
            }

            Item { width: 1; height: 10 }
        }

        IpcHandler {
            target: "printpopup"

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

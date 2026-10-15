import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls

PopupWindow {
    id: popupRoot

    property var barWin
    property var usbPrinters: []
    property var netPrinters: []
    property string selectedTab: "usb"
    property string selectedQueue: ""
    property string printerStatus: "unknown"
    property string printerModel: ""
    property string printerDevice: ""
    property var jobs: []

    visible: false
    implicitWidth: 440
    implicitHeight: 580
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
        discoverProc.running = true;
    }

    function refreshDetails() {
        statusProc.running = true;
        jobsProc.running = true;
    }

    function selectPrinter(q) {
        selectedQueue = q;
        printerModel = q.replace(/_/g, " ");
        printerStatus = "unknown";
        printerDevice = "";
        jobs = [];
        refreshDetails();
    }

    function cancelJob(jobId) {
        Actions.run("cancel " + jobId + " " + selectedQueue);
        Qt.callLater(function() { refreshDetails(); });
    }

    onVisibleChanged: {
        if (!visible)
            closed();
    }

    Component.onCompleted: refresh()

    // Discover all printers and split into USB / network lists
    readonly property Process discoverProc: Process {
        command: ["sh", "-c",
            "lpstat -v 2>/dev/null; echo '---SEP---'; lpstat -p 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.split("---SEP---");
                const vLines = (parts[0] || "").trim().split("\n");
                const pLines = (parts[1] || "").trim().split("\n");

                // queue name -> device URI
                const devMap = {};
                for (const l of vLines) {
                    const m = l.trim().match(/^device for (\S+):\s*(.+)$/);
                    if (m)
                        devMap[m[1]] = m[2].trim();
                }

                const usb = [];
                const net = [];
                for (const l of pLines) {
                    const m = l.trim().match(/^printer (\S+)\s+(idle|disabled|printing|stopped)/);
                    if (!m)
                        continue;
                    const q = m[1];
                    const st = m[2];
                    const dev = devMap[q] || "";
                    const info = { queue: q, status: st, device: dev };
                    if (dev.toLowerCase().startsWith("usb://"))
                        usb.push(info);
                    else
                        net.push(info);
                }
                usb.sort(function(a, b) { return a.queue.localeCompare(b.queue); });
                net.sort(function(a, b) { return a.queue.localeCompare(b.queue); });
                popupRoot.usbPrinters = usb;
                popupRoot.netPrinters = net;

                // Auto-select a printer if current selection is gone or empty
                const list = popupRoot.selectedTab === "usb" ? usb : net;
                if (!list.find(function(p) { return p.queue === popupRoot.selectedQueue; })) {
                    const other = popupRoot.selectedTab === "usb" ? net : usb;
                    const fallback = list.length > 0 ? list[0] : (other.length > 0 ? other[0] : null);
                    if (fallback)
                        popupRoot.selectPrinter(fallback.queue);
                }
            }
        }
    }

    readonly property Process statusProc: Process {
        command: ["sh", "-c",
            "echo $(lpstat -p " + selectedQueue + " 2>/dev/null); " +
            "echo $(lpstat -p " + selectedQueue + " -v 2>/dev/null | sed 's/.*device for .*: //')"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!popupRoot.selectedQueue)
                    return;
                const lines = text.trim().split("\n");
                const statusLine = lines[0] || "";
                if (statusLine.includes("idle"))
                    popupRoot.printerStatus = "idle";
                else if (statusLine.includes("printing"))
                    popupRoot.printerStatus = "printing";
                else if (statusLine.includes("stopped"))
                    popupRoot.printerStatus = "stopped";
                else if (statusLine.includes("disabled"))
                    popupRoot.printerStatus = "offline";
                else
                    popupRoot.printerStatus = "unknown";

                popupRoot.printerDevice = lines[1] ? lines[1].trim() : "";
            }
        }
    }

    readonly property Process jobsProc: Process {
        command: ["sh", "-c", "lpstat -W not-completed '" + selectedQueue + "' 2>/dev/null || true"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!popupRoot.selectedQueue)
                    return;
                const rows = [];
                for (const l of text.trim().split("\n")) {
                    if (!l.trim())
                        continue;
                    const p = l.trim().split(/\s+/);
                    // EPSON_L3250_WIFI_-12 user 12345 "date"
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
        return "";
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

            // Header
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

            // Tab selector: USB / Network
            Row {
                width: parent.width
                height: 26
                spacing: 6

                Rectangle {
                    width: (parent.width - 6) / 2
                    height: parent.height
                    radius: 0
                    color: popupRoot.selectedTab === "usb" ? Theme.accent : Theme.bgLight

                    Text {
                        anchors.centerIn: parent
                        text: "USB (" + popupRoot.usbPrinters.length + ")"
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        color: popupRoot.selectedTab === "usb" ? Theme.bg : Theme.fg
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            popupRoot.selectedTab = "usb";
                            if (popupRoot.usbPrinters.length > 0
                                && !popupRoot.usbPrinters.find(function(p) { return p.queue === popupRoot.selectedQueue; }))
                                popupRoot.selectPrinter(popupRoot.usbPrinters[0].queue);
                        }
                    }
                }

                Rectangle {
                    width: (parent.width - 6) / 2
                    height: parent.height
                    radius: 0
                    color: popupRoot.selectedTab === "net" ? Theme.accent : Theme.bgLight

                    Text {
                        anchors.centerIn: parent
                        text: "Network (" + popupRoot.netPrinters.length + ")"
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        color: popupRoot.selectedTab === "net" ? Theme.bg : Theme.fg
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            popupRoot.selectedTab = "net";
                            if (popupRoot.netPrinters.length > 0
                                && !popupRoot.netPrinters.find(function(p) { return p.queue === popupRoot.selectedQueue; }))
                                popupRoot.selectPrinter(popupRoot.netPrinters[0].queue);
                        }
                    }
                }
            }

            // Printer list for the selected tab (only when more than one)
            Column {
                width: parent.width
                spacing: 2
                visible: popupRoot.selectedTab === "usb"
                    ? popupRoot.usbPrinters.length > 1
                    : popupRoot.netPrinters.length > 1

                Repeater {
                    model: popupRoot.selectedTab === "usb" ? popupRoot.usbPrinters : popupRoot.netPrinters

                    delegate: Rectangle {
                        id: pItem

                        required property var modelData

                        width: parent.width
                        height: 26
                        radius: 0
                        color: pItem.modelData.queue === popupRoot.selectedQueue
                            ? Theme.bgLight
                            : (pItemHover.containsMouse ? Theme.bgLight : "transparent")

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 16
                            text: pItem.modelData.queue.replace(/_/g, " ")
                                + (pItem.modelData.status === "disabled" ? " (off)" : "")
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            color: pItem.modelData.queue === popupRoot.selectedQueue ? Theme.accent : Theme.fg
                            elide: Text.ElideRight
                        }

                        HoverHandler { id: pItemHover }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: popupRoot.selectPrinter(pItem.modelData.queue)
                        }
                    }
                }
            }

            // Empty tab state
            Text {
                visible: popupRoot.selectedTab === "usb"
                    ? popupRoot.usbPrinters.length === 0
                    : popupRoot.netPrinters.length === 0
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: "No " + (popupRoot.selectedTab === "usb" ? "USB" : "network") + " printers found"
                font.family: Theme.fontFamily
                font.pixelSize: 11
                color: Theme.dim
            }

            // Status bar
            Rectangle {
                width: parent.width
                height: 34
                radius: 0
                color: Theme.bgLight
                visible: popupRoot.selectedQueue !== ""

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 100
                    text: popupRoot.statusIcon() + "  " + popupRoot.printerModel + " — " + popupRoot.printerStatus
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    color: popupRoot.statusColor()
                    elide: Text.ElideRight
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

            // Device URI
            Text {
                visible: popupRoot.printerDevice !== ""
                width: parent.width
                text: popupRoot.printerDevice
                font.family: Theme.fontFamily
                font.pixelSize: 10
                color: Theme.dim
                elide: Text.ElideRight
            }

            // Active Jobs
            Text {
                width: parent.width
                text: "Active Jobs" + (popupRoot.jobs.length > 0 ? " (" + popupRoot.jobs.length + ")" : "")
                font.family: Theme.fontFamily
                font.pixelSize: 12
                font.bold: true
                color: Theme.fg
            }

            Text {
                visible: popupRoot.jobs.length === 0
                width: parent.width
                text: popupRoot.printerStatus === "printing" ? "Printing..." : "No active jobs"
                font.family: Theme.fontFamily
                font.pixelSize: 11
                color: popupRoot.printerStatus === "printing" ? Theme.accent : Theme.dim
            }

            Repeater {
                model: popupRoot.jobs

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

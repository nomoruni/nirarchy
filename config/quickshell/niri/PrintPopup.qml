import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls

PopupWindow {
    id: popupRoot

    property var barWin
    property var printerData: null
    property string printerName: "office"

    visible: false
    implicitWidth: 380
    implicitHeight: 400
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
        printProc.running = true;
    }

    onVisibleChanged: {
        if (!visible)
            closed();
    }

    Component.onCompleted: refresh()

    Timer {
        id: autoRefreshTimer

        interval: 15000
        repeat: true
        running: popupRoot.visible
        onTriggered: popupRoot.refresh()
    }

    readonly property Process printProc: Process {
        command: ["printbar", popupRoot.printerName, "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    popupRoot.printerData = JSON.parse(text.trim());
                } catch (e) {
                    popupRoot.printerData = null;
                }
            }
        }
    }

    function stateColor(state) {
        if (state === "ok") return Theme.green;
        if (state === "warn") return Theme.yellow;
        if (state === "critical") return Theme.red;
        if (state === "offline") return Theme.dim;
        return Theme.dim;
    }

    function supplyLevel(supply) {
        if (!supply || supply.level_pct === undefined) return "?%";
        return Math.round(supply.level_pct) + "%";
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

                    HoverHandler {
                        id: refreshHover
                    }

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
                    text: {
                        if (!popupRoot.printerData) return "Loading...";
                        var s = popupRoot.printerData.status || "unknown";
                        return "󰤨  " + (popupRoot.printerData.model || popupRoot.printerName) + " — " + s;
                    }
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    color: popupRoot.printerData ? popupRoot.stateColor(popupRoot.printerData.state) : Theme.dim
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

            // Supplies
            Text {
                visible: popupRoot.printerData && popupRoot.printerData.supplies && popupRoot.printerData.supplies.length > 0
                text: "Supplies"
                font.family: Theme.fontFamily
                font.pixelSize: 12
                font.bold: true
                color: Theme.fg
            }

            Repeater {
                model: popupRoot.printerData ? (popupRoot.printerData.supplies || []) : []

                delegate: Rectangle {
                    width: parent.width
                    height: 28
                    radius: 0
                    color: "transparent"

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.colorant || modelData.name || "?"
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            color: Theme.fg
                            width: 60
                        }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 120
                            height: 10
                            radius: 0
                            color: Theme.bgLight

                            Rectangle {
                                width: Math.max(0, Math.min(1, (modelData.level_pct || 0) / 100)) * parent.width
                                height: parent.height
                                radius: 0
                                color: popupRoot.stateColor(modelData.state)
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: popupRoot.supplyLevel(modelData)
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            color: popupRoot.stateColor(modelData.state)
                        }
                    }
                }
            }

            // Jobs
            Text {
                visible: popupRoot.printerData && popupRoot.printerData.jobs > 0
                text: "Jobs: " + (popupRoot.printerData ? popupRoot.printerData.jobs : 0)
                font.family: Theme.fontFamily
                font.pixelSize: 12
                font.bold: true
                color: Theme.accent
            }

            // Display text
            Text {
                visible: popupRoot.printerData && popupRoot.printerData.display && popupRoot.printerData.display !== ""
                width: parent.width
                text: popupRoot.printerData ? popupRoot.printerData.display : ""
                font.family: Theme.fontFamily
                font.pixelSize: 11
                color: Theme.dim
                wrapMode: Text.Wrap
            }

            Item {
                width: 1
                height: parent.height > 200 ? 10 : 0
            }
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

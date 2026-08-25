import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: calRoot

    property var barWin
    property date viewDate: new Date()
    property var cells: []
    property string monthTitle: ""
    property int panelX: 0

    visible: false
    implicitWidth: 0
    implicitHeight: 0
    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "nirarchy-calendar"

    function openAt(cx) {
        panelX = Math.max(8, Math.min(cx - 140, (barWin?.width ?? 1000) - 288));
        viewDate = new Date();
        rebuild();
        visible = true;
    }

    function closeCalendar() {
        visible = false;
    }

    function rebuild() {
        const y = viewDate.getFullYear();
        const m = viewDate.getMonth();
        const first = new Date(y, m, 1);
        const startDow = (first.getDay() + 6) % 7;
        const start = new Date(y, m, 1 - startDow);
        const today = new Date();
        const rows = [];
        for (let i = 0; i < 42; i++) {
            const d = new Date(start.getFullYear(), start.getMonth(), start.getDate() + i);
            rows.push({
                "day": d.getDate(),
                "inMonth": d.getMonth() === m,
                "today": d.toDateString() === today.toDateString()
            });
        }
        calRoot.cells = rows;
        monthTitle = Qt.formatDate(viewDate, "MMMM yyyy");
    }

    function shiftMonth(delta) {
        viewDate = new Date(viewDate.getFullYear(), viewDate.getMonth() + delta, 1);
        rebuild();
    }

    Rectangle {
        id: scrim

        anchors.fill: parent
        color: "transparent"

        MouseArea {
            anchors.fill: parent
            onClicked: calRoot.closeCalendar()
        }
    }

    Rectangle {
        id: panel

        x: calRoot.panelX
        y: Theme.barHeight + 6
        width: 280
        height: 316
        radius: 0
        color: Theme.bg
        border.color: Qt.alpha(Theme.accent, 0.55)
        border.width: 1
        opacity: calRoot.visible ? 1 : 0
        scale: calRoot.visible ? 1 : 0.96
        Behavior on opacity {
            NumberAnimation {
                duration: 120
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: 120
                easing.type: Easing.OutQuad
            }
        }

        MouseArea {
            anchors.fill: parent

            onClicked: mouse => mouse.accepted = true
        }

        Column {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 8

            Item {
                width: parent.width
                height: 28

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: calRoot.monthTitle
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                    font.bold: true
                    color: Theme.fg
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    Repeater {
                        model: [{
                                "glyph": "\uf053",
                                "act": function() {
                                    calRoot.shiftMonth(-1);
                                }
                            }, {
                                "glyph": "\uf054",
                                "act": function() {
                                    calRoot.shiftMonth(1);
                                }
                            }, {
                                "glyph": "\uf00d",
                                "act": function() {
                                    calRoot.closeCalendar();
                                }
                            }]

                        delegate: Rectangle {
                            id: navBtn

                            required property var modelData

                            width: 26
                            height: 22
                            color: navHover.containsMouse ? Theme.bgLight : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: navBtn.modelData.glyph
                                font.family: Theme.fontFamily
                                font.pixelSize: 13
                                color: navHover.containsMouse ? Theme.accent : Theme.fg
                            }

                            HoverHandler {
                                id: navHover
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: navBtn.modelData.act()
                            }
                        }
                    }
                }
            }

            Row {
                width: parent.width
                spacing: 0

                Repeater {
                    model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

                    Text {
                        required property string modelData

                        width: (panel.width - 28) / 7
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                        color: Theme.dim
                    }
                }
            }

            GridView {
                id: grid

                width: parent.width
                height: parent.height - 66
                interactive: false
                cellWidth: width / 7
                cellHeight: cellWidth * 0.8
                model: calRoot.cells

                delegate: Item {
                    id: dayCell

                    required property var modelData

                    width: grid.cellWidth
                    height: grid.cellHeight

                    Rectangle {
                        anchors.centerIn: parent
                        width: Math.min(grid.cellWidth, grid.cellHeight) - 8
                        height: width
                        color: dayCell.modelData.today ? Theme.accent : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: dayCell.modelData.day
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.bold: dayCell.modelData.today
                            color: dayCell.modelData.today ? Theme.bg : dayCell.modelData.inMonth ? Theme.fg : Qt.alpha(Theme.dim, 0.55)
                        }
                    }
                }
            }
        }

        IpcHandler {
            target: "calendar"

            function toggle(): void {
                if (calRoot.visible) {
                    calRoot.closeCalendar();
                    return;
                }
                calRoot.openAt((calRoot.barWin?.width ?? 1000) / 2);
            }
        }
    }
}

import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: clockRoot

    property var barWin
    property var calendar: null
    property string text: ""

    function isoWeek(d) {
        const date = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
        const dayNum = date.getUTCDay() || 7;
        date.setUTCDate(date.getUTCDate() + 4 - dayNum);
        const yearStart = new Date(Date.UTC(date.getUTCFullYear(), 0, 1));
        return Math.ceil((((date - yearStart) / 86400000) + 1) / 7);
    }

    function update() {
        const now = new Date();
        text = Qt.formatDateTime(now, "dddd HH:mm");
    }

    implicitWidth: clockText.implicitWidth
    implicitHeight: Theme.barHeight - 4

    Text {
        id: clockText

        anchors.centerIn: parent
        text: clockRoot.text
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        color: hov.hovered ? Theme.accent : Theme.fg
        Behavior on color {
            ColorAnimation {
                duration: 100
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: clockRoot.update()
    }

    HoverHandler {
        id: hov
    }

    TapHandler {
        onTapped: {
            if (!clockRoot.calendar)
                return;
            if (clockRoot.calendar.visible) {
                clockRoot.calendar.closeCalendar();
                return;
            }
            const p = clockRoot.mapToItem(clockRoot.barWin?.contentItem ?? clockRoot, clockRoot.width / 2, 0);
            clockRoot.calendar.openAt(p.x);
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 0
        color: hov.hovered ? Theme.bgLight : "transparent"
        z: -1
    }
}

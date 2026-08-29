import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: bar

    property var modelData

    screen: modelData
    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: Theme.barHeight
    color: "transparent"

    Niri {
        id: niriState

        output: modelData.name
    }

    component TipBox: Rectangle {
        id: tipBox

        property string tipText: ""

        visible: false
        z: 999
        y: Theme.barHeight + 8
        width: tipText.implicitWidth + 20
        height: tipText.implicitHeight + 12
        radius: 0
        color: Theme.bgLight
        border.color: Theme.accent
        border.width: 1

        Text {
            id: tipText

            anchors.centerIn: parent
            text: tipBox.tipText.replace(/\n/g, "  ·  ")
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 1
            color: Theme.fg
        }
    }

    component HoverClick: MouseArea {
        id: hc

        property var onClickAction: null
        property var onRightClickAction: null
        property var onScrollUpAction: null
        property var onScrollDownAction: null

        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                if (onRightClickAction)
                    onRightClickAction();
            } else if (onClickAction) {
                onClickAction();
            }
        }
        onWheel: wheel => {
            if (wheel.angleDelta.y > 0 && onScrollUpAction)
                onScrollUpAction();
            else if (wheel.angleDelta.y < 0 && onScrollDownAction)
                onScrollDownAction();
        }
    }

    component BarButton: Rectangle {
        id: btnRoot

        property string glyph: ""
        property int glyphPixel: Theme.fontSize + 2
        property color glyphTint: Theme.fg
        property string imageSource: ""
        property string label: ""
        property string tip: ""
        property var onClickAction: null
        property var onRightClickAction: null
        property var onScrollUpAction: null
        property var onScrollDownAction: null
        property bool accentColor: false
        property bool dangerColor: false

        radius: 0
        implicitWidth: row.implicitWidth + 14
        implicitHeight: Theme.barHeight - 4
        color: hover.hovered ? Theme.bgLight : "transparent"

        RowLayout {
            id: row

            anchors.centerIn: parent
            spacing: 5

            Text {
                visible: glyph !== ""
                text: glyph
                font.family: Theme.fontFamily
                font.pixelSize: btnRoot.glyphPixel
                color: btnRoot.dangerColor ? Theme.red : btnRoot.accentColor ? Theme.accent : btnRoot.glyphTint
            }

            Image {
                visible: btnRoot.imageSource !== ""
                source: btnRoot.imageSource
                width: btnRoot.glyphPixel
                height: btnRoot.glyphPixel
                sourceSize: Qt.size(btnRoot.glyphPixel, btnRoot.glyphPixel)
                smooth: true
                layer.enabled: true
                layer.effect: null
            }

            Text {
                visible: label !== ""
                text: label
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                color: btnRoot.dangerColor ? Theme.red : btnRoot.accentColor ? Theme.accent : Theme.fg
            }
        }

        HoverHandler {
            id: hover

            onHoveredChanged: tipLoader.active = hovered && btnRoot.tip !== ""
        }

        HoverClick {
            onClickAction: btnRoot.onClickAction
            onRightClickAction: btnRoot.onRightClickAction
            onScrollUpAction: btnRoot.onScrollUpAction
            onScrollDownAction: btnRoot.onScrollDownAction
        }

        Loader {
            id: tipLoader

            active: false
            sourceComponent: TipBox {
                tipText: btnRoot.tip
                x: Math.min(btnRoot.mapToItem(bar.contentItem, 0, 0).x, bar.width - width - 8)
            }
        }
    }

    component TrayButton: Rectangle {
        id: trayRoot

        property SystemTrayItem item
        property string tip: ""

        radius: 0
        implicitWidth: Math.max(iconImg.implicitWidth, Theme.barHeight - 12) + 12
        implicitHeight: Theme.barHeight - 4
        color: hover.hovered ? Theme.bgLight : "transparent"

        IconImage {
            id: iconImg

            anchors.centerIn: parent
            source: trayRoot.item?.icon ?? ""
            implicitSize: 16
            asynchronous: true
        }

        HoverHandler {
            id: hover

            onHoveredChanged: tipLoader.active = hovered && trayRoot.tip !== ""
        }

        HoverClick {
            onClickAction: () => trayRoot.item?.activate()
            onRightClickAction: () => {
                const it = trayRoot.item;
                if (!it)
                    return;
                if (it.hasMenu) {
                    const pos = trayRoot.mapToItem(bar.contentItem, 0, 0);
                    it.display(bar, pos.x, bar.height);
                } else {
                    it.secondaryActivate();
                }
            }
            onScrollUpAction: () => trayRoot.item?.scroll(1, false)
            onScrollDownAction: () => trayRoot.item?.scroll(-1, false)
        }

        Loader {
            id: tipLoader

            active: false
            sourceComponent: TipBox {
                tipText: trayRoot.tip
                x: Math.min(trayRoot.mapToItem(bar.contentItem, 0, 0).x, bar.width - width - 8)
            }
        }
    }

    Rectangle {
        id: content

        anchors.fill: parent
        color: Theme.bg

        RowLayout {
            id: leftRow

            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            spacing: 0

            BarButton {
                imageSource: Theme.dataDir + "/nirarchy-menu-icon.png"
                glyphPixel: 19
                tip: "Nirarchy Menu\n\nSuper + Alt + Space"
                onClickAction: () => Actions.detached("nirarchy-menu")
                onRightClickAction: () => Actions.detached("foot")
            }

            Item {
                width: 8
            }

            Repeater {
                model: niriState.visibleWorkspaces

                BarButton {
                    id: wsBtn

                    required property var modelData

                    readonly property int num: modelData.num ?? modelData.idx
                    readonly property bool active: modelData.is_active
                    readonly property bool isUrgent: modelData.is_urgent

                    glyph: active ? "\uf111" : "\uf10c"
                    glyphPixel: active ? Theme.fontSize + 3 : Theme.fontSize - 1
                    glyphTint: active ? Theme.fg : Theme.dim
                    accentColor: active
                    dangerColor: isUrgent
                    tip: "Workspace " + num + (isUrgent ? " (urgent)" : "")
                    label: ""
                    onClickAction: () => niriState.focusWs(modelData)
                    onScrollUpAction: () => niriState.cycleWorkspace(1)
                    onScrollDownAction: () => niriState.cycleWorkspace(-1)
                }
            }
        }

        RowLayout {
            anchors.centerIn: parent
            spacing: 2

            BarButton {
                visible: true
                glyph: Pomodoro.modeIcon()
                label: Pomodoro.running ? Pomodoro.formattedTime() : ""
                glyphTint: Pomodoro.mode === "work" ? Theme.red : Pomodoro.mode === "idle" ? Theme.dim : Theme.green
                accentColor: Pomodoro.running
                tip: Pomodoro.modeLabel() + (Pomodoro.running ? " · " + Pomodoro.formattedTime() : "") + "\n\nSession " + (Pomodoro.sessions + 1) + "/" + Pomodoro.sessionsBeforeLong + "\nLeft-click: start / pause\nRight-click: open controls"
                onClickAction: () => Pomodoro.start()
                onRightClickAction: () => {
                    if (pomoPopup.visible) {
                        pomoPopup.visible = false;
                        return;
                    }
                    const px = mapToItem(bar.contentItem, 0, 0).x;
                    pomoPopup.openAt(px);
                }
            }

            ClockWidget {
                barWin: bar
                calendar: calPopup
            }

            BarButton {
                visible: Indicators.weatherVisible
                label: Indicators.weather
                tip: "Weather"
                onClickAction: () => Actions.detached("notify-send -u low \"" + Indicators.weather.replace(/"/g, "") + "\"")
            }

            BarButton {
                glyph: ""
                tip: Indicators.recording ? "Recording — click to stop" : "Record screen\n\nRight-click for options"
                dangerColor: Indicators.recording
                accentColor: !Indicators.recording
                onClickAction: () => Actions.detached(Indicators.recording ? "nirarchy-capture-screenrecording --stop-recording" : "nirarchy-capture-screenrecording")
                onRightClickAction: () => Actions.detached("nirarchy-menu screenrecord")
            }

            BarButton {
                glyph: "󰄀"
                tip: "Screenshot\n\nRight-click for capture menu"
                onClickAction: () => Actions.detached("nirarchy-capture-screenshot")
                onRightClickAction: () => Actions.detached("nirarchy-menu capture")
            }

            BarButton {
                glyph: "󰔛"
                tip: "Reminders\n\nRight-click to show all"
                onClickAction: () => Actions.detached("nirarchy-menu reminder")
                onRightClickAction: () => Actions.detached("nirarchy-reminder show")
            }

            BarButton {
                visible: Indicators.updates > 0
                glyph: "󰚰"
                tip: Indicators.updates + " updates available"
                accentColor: true
                onClickAction: () => Actions.detached("nirarchy-launch-floating-terminal-with-presentation 'echo Updating system… && paru'")
            }

            BarButton {
                visible: Indicators.idleOff
                glyph: "󰾧"
                tip: "Idle locking disabled\n\nClick to enable"
                accentColor: true
                onClickAction: () => Actions.detached("nirarchy-toggle-idle")
            }

            BarButton {
                visible: Indicators.silenced
                glyph: "󰂛"
                tip: "Notifications silenced\n\nClick to enable"
                accentColor: true
                onClickAction: () => Actions.detached("nirarchy-toggle-notification-silencing")
            }
        }

        RowLayout {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            spacing: 0

            Repeater {
                model: SystemTray.items

                delegate: TrayButton {
                    required property SystemTrayItem modelData

                    item: modelData
                    tip: modelData.tooltipTitle || modelData.title || ""
                }
            }

            Item {
                visible: SystemTray.items.values.length > 0
                width: 4
            }

            BarButton {
                id: btBtn

                visible: Sys.btPresent
                glyph: !Sys.btPowered ? "󰂲" : Sys.btConnected > 0 ? "󰂱" : "󰂯"
                accentColor: bar.btBtnOpen
                tip: Sys.btPowered ? "Devices connected: " + Sys.btConnected : "Bluetooth off"
                onClickAction: () => {
                    if (btPopup.visible) {
                        btPopup.visible = false;
                        return;
                    }
                    const px = mapToItem(bar.contentItem, 0, 0).x;
                    netPopup.visible = false;
                    bar.btBtnOpen = true;
                    btPopup.openAt(px);
                }
            }

            BarButton {
                id: printerBtn

                visible: printerPopup.printerStatus !== "unknown"
                glyph: printerPopup.statusIcon()
                accentColor: bar.printerBtnOpen
                tip: printerPopup.printerModel + " — " + printerPopup.printerStatus + (printerPopup.jobs.length > 0 ? "\n" + printerPopup.jobs.length + " jobs" : "")
                dangerColor: printerPopup.printerStatus === "offline" || printerPopup.printerStatus === "stopped"
                onClickAction: () => {
                    if (printerPopup.visible) {
                        printerPopup.visible = false;
                        return;
                    }
                    const px = mapToItem(bar.contentItem, 0, 0).x;
                    btPopup.visible = false;
                    netPopup.visible = false;
                    bar.printerBtnOpen = true;
                    printerPopup.openAt(px);
                }
            }

            BarButton {
                id: wifiBtn

                glyph: Sys.netIcon
                accentColor: bar.wifiBtnOpen
                tip: Sys.netTooltip
                onClickAction: () => {
                    if (netPopup.visible) {
                        netPopup.visible = false;
                        return;
                    }
                    const px = mapToItem(bar.contentItem, 0, 0).x;
                    btPopup.visible = false;
                    bar.wifiBtnOpen = true;
                    netPopup.openAt(px);
                }
            }

            BarButton {
                glyph: Indicators.audioGlyph()
                tip: Sys.muted ? "Muted" : "Playing at " + Sys.volume + "%"
                onClickAction: () => Actions.detached("nirarchy-launch-audio")
                onRightClickAction: () => Actions.run("swayosd-client --output-volume mute-toggle")
                onScrollUpAction: () => {
                    Actions.run("swayosd-client --output-volume raise");
                    Sys.audioProc.running = true;
                }
                onScrollDownAction: () => {
                    Actions.run("swayosd-client --output-volume lower");
                    Sys.audioProc.running = true;
                }
            }

            BarButton {
                glyph: "󰍛"
                tip: "CPU " + Sys.cpu + "%\n\nClick for btop"
                onClickAction: () => Actions.detached("nirarchy-launch-or-focus-tui btop")
            }

            BarButton {
                visible: Sys.batPresent
                label: Sys.batCapacity + "%"
                glyph: Sys.batIcon()
                tip: Sys.batStatus + " · " + Sys.batCapacity + "%\n\nClick for power menu"
                dangerColor: Sys.batCapacity <= 15 && Sys.batStatus !== "Charging" && Sys.batStatus !== "Full"
                onClickAction: () => Actions.detached("nirarchy-menu power")
                onRightClickAction: () => Actions.run("notify-send -u low \"$(nirarchy-battery-status)\"")
            }

            Item {
                width: 6
            }
        }
    }

    CalendarPopup {
        id: calPopup

        barWin: bar
    }

    NetPopup {
        id: netPopup

        barWin: bar
        onClosed: wifiBtnOpen = false
    }

    BtPopup {
        id: btPopup

        barWin: bar
        onClosed: btBtnOpen = false
    }

    PomodoroPopup {
        id: pomoPopup

        barWin: bar
        onClosed: pomoBtnOpen = false
    }

    PrintPopup {
        id: printerPopup

        barWin: bar
        onClosed: printerBtnOpen = false
    }

    property bool wifiBtnOpen: false
    property bool btBtnOpen: false
    property bool pomoBtnOpen: false
    property bool printerBtnOpen: false
}

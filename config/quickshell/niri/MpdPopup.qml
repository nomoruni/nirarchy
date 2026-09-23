import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

// Full-screen transparent overlay: clicking anywhere outside the content box
// closes the popup (same pattern as UfwPopup).
PanelWindow {
    id: popupRoot

    property var barWin
    property real openX: 0
    property real boxWidth: 360

    visible: false
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "nirarchy-mpd"
    implicitWidth: 1920
    implicitHeight: 1080

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    readonly property real progress: Mpd.length > 0 ? Math.max(0, Math.min(1, Mpd.position / Mpd.length)) : 0

    function openAt(x) {
        popupRoot.openX = x ?? 800;
        visible = true;
        Mpd.refresh();
    }

    onVisibleChanged: {
        if (!visible)
            closed();
    }

    // Click anywhere outside the content box to dismiss.
    MouseArea {
        anchors.fill: parent
        onClicked: popupRoot.visible = false
    }

    component MediaBtn: Rectangle {
        id: mb

        property string glyph
        property var action
        property bool primary: false
        property bool dimmed: false
        property int box: 34

        width: box
        height: box
        radius: 0
        color: mbHover.hovered && !dimmed ? Theme.accent : Theme.bgLight
        opacity: dimmed ? 0.35 : 1

        Text {
            anchors.centerIn: parent
            text: mb.glyph
            font.family: Theme.fontFamily
            font.pixelSize: mb.primary ? 19 : 16
            color: mbHover.hovered && !dimmed ? Theme.bg : Theme.fg
        }

        HoverHandler {
            id: mbHover

            enabled: !mb.dimmed
        }

        MouseArea {
            anchors.fill: parent
            enabled: !mb.dimmed
            cursorShape: Qt.PointingHandCursor
            onClicked: if (mb.action)
                mb.action()
        }
    }

    Rectangle {
        id: contentBox

        x: Math.max(0, Math.min(popupRoot.openX - 20, popupRoot.width - popupRoot.boxWidth - 8))
        y: Theme.barHeight + 6
        width: popupRoot.boxWidth
        height: contentColumn.implicitHeight + 28
        radius: 0
        color: Theme.bg
        border.color: Theme.accent
        border.width: 1

        // Absorb clicks in the popup's own empty space so they don't hit the
        // dismiss scrim behind it.
        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        Column {
            id: contentColumn

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 14
            spacing: 10

            Item {
                width: parent.width
                height: 16

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: Mpd.available ? "NOW PLAYING" : "MPD"
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    color: Theme.dim
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: Mpd.queuePos !== "" ? "#" + Mpd.queuePos : "MPD"
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    color: Theme.accent
                }
            }

            Text {
                width: parent.width
                elide: Text.ElideRight
                text: Mpd.hasTrack ? Mpd.title : (Mpd.available ? "No track" : "MPD unavailable")
                font.family: Theme.fontFamily
                font.pixelSize: 16
                color: Theme.fg
            }

            Text {
                width: parent.width
                elide: Text.ElideRight
                visible: text !== ""
                text: Mpd.artist + (Mpd.album !== "" ? "  ·  " + Mpd.album : "")
                font.family: Theme.fontFamily
                font.pixelSize: 12
                color: Theme.dim
            }

            Column {
                width: parent.width
                spacing: 4
                visible: Mpd.length > 0

                Rectangle {
                    id: seekBar

                    width: parent.width
                    height: 6
                    radius: 0
                    color: Theme.bgLight

                    Rectangle {
                        width: seekBar.width * popupRoot.progress
                        height: parent.height
                        radius: 0
                        color: Theme.accent
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onPressed: mouse => Mpd.seek(mouse.x / width)
                    }
                }

                Item {
                    width: parent.width
                    height: 14

                    Text {
                        anchors.left: parent.left
                        text: Mpd.fmtTime(Mpd.position)
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        color: Theme.dim
                    }

                    Text {
                        anchors.right: parent.right
                        text: Mpd.fmtTime(Mpd.length)
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        color: Theme.dim
                    }
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 10

                MediaBtn {
                    glyph: "󰒮"
                    dimmed: !Mpd.canControl
                    action: () => Mpd.previous()
                }

                MediaBtn {
                    glyph: Mpd.playing ? "\uF04B" : "\uF04C"
                    primary: true
                    dimmed: !Mpd.canControl
                    action: () => Mpd.togglePlay()
                }

                MediaBtn {
                    glyph: "󰒭"
                    dimmed: !Mpd.canControl
                    action: () => Mpd.next()
                }
            }

            Row {
                width: parent.width
                spacing: 8
                visible: Mpd.volume >= 0

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Mpd.volume <= 0 ? "󰖁" : Mpd.volume < 34 ? "󰕿" : Mpd.volume < 67 ? "󰖀" : "󰕾"
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                    color: Theme.fg
                }

                Rectangle {
                    id: volBar

                    width: parent.width - 82
                    height: 6
                    anchors.verticalCenter: parent.verticalCenter
                    radius: 0
                    color: Theme.bgLight

                    Rectangle {
                        width: volBar.width * Math.max(0, Math.min(1, Mpd.volume / 100))
                        height: parent.height
                        radius: 0
                        color: Theme.accent
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onPressed: mouse => Mpd.setVolume(mouse.x / width)
                        onReleased: mouse => Mpd.setVolume(mouse.x / width)
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 40
                    horizontalAlignment: Text.AlignRight
                    text: Math.round(Mpd.volume) + "%"
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    color: Theme.dim
                }
            }

            Item {
                width: parent.width
                height: 26

                Rectangle {
                    id: npBtn

                    anchors.fill: parent
                    radius: 0
                    color: npHover.hovered ? Theme.accent : Theme.bgLight

                    Text {
                        anchors.centerIn: parent
                        text: "󰦚  ncmpcpp"
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        color: npHover.hovered ? Theme.bg : Theme.fg
                    }

                    HoverHandler {
                        id: npHover
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            popupRoot.visible = false;
                            Actions.detached("nirarchy-launch-or-focus-tui ncmpcpp");
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "mpdpopup"

        function toggle(): void {
            if (popupRoot.visible) {
                popupRoot.visible = false;
                return;
            }
            popupRoot.openAt(((popupRoot.barWin?.width || popupRoot.width) || 1366) - popupRoot.boxWidth - 20);
        }
    }
}
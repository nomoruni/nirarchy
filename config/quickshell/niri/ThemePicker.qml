import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls

PanelWindow {
    id: pickerRoot

    property bool open: false
    property string mode: "themes"
    property string filterText: ""
    property var entries: []
    property int currentIndex: 0

    function openPicker(m) {
        mode = m;
        filterText = "";
        currentIndex = 0;
        loadEntries();
        open = true;
        searchField.forceActiveFocus();
    }

    function closePicker() {
        open = false;
        searchField.text = "";
    }

    function loadEntries() {
        listProc.command = ["nirarchy-picker-list", mode];
        listProc.running = true;
    }

    implicitWidth: 0
    implicitHeight: 0
    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }
    color: "transparent"
    visible: open

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "nirarchy-picker"

    Process {
        id: listProc

        stdout: StdioCollector {
            onStreamFinished: {
                const rows = [];
                const lines = text.trim().split("\n");
                for (let i = 0; i < lines.length; i++) {
                    if (!lines[i])
                        continue;
                    const parts = lines[i].split("\t");
                    rows.push({
                        "value": parts[0],
                        "label": parts[1],
                        "image": parts[2] ?? ""
                    });
                }
                pickerRoot.entries = rows;
            }
        }
    }

    Rectangle {
        id: scrim

        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 1)
        opacity: pickerRoot.open ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: 140
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: pickerRoot.closePicker()
        }
    }

    Rectangle {
        id: panel

        property int panelWidth: 860
        property int panelHeight: 560

        anchors.centerIn: parent
        width: panelWidth
        height: panelHeight
        radius: 0
        color: Theme.bg
        border.color: Theme.accent
        border.width: 1
        opacity: pickerRoot.open ? 1 : 0
        scale: pickerRoot.open ? 1 : 0.94
        Behavior on opacity {
            NumberAnimation {
                duration: 140
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: 140
                easing.type: Easing.OutQuad
            }
        }

        Column {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            Item {
                width: parent.width
                height: 40

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: pickerRoot.mode === "backgrounds" ? "Backgrounds" : "Themes"
                    font.family: Theme.fontFamily
                    font.pixelSize: 17
                    font.bold: true
                    color: Theme.fg
                }

                TextField {
                    id: searchField

                    anchors.right: parent.right
                    width: 240
                    height: 34
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    color: Theme.fg
                    placeholderText: "Filter…"
                    background: Rectangle {
                        radius: 0
                        color: Theme.bgLight
                        border.color: searchField.activeFocus ? Theme.accent : "transparent"
                    }
                    onTextChanged: pickerRoot.filterText = text.toLowerCase()
                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Escape) {
                            pickerRoot.closePicker();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Down || event.key === Qt.Key_J) {
                            grid.moveCurrentIndexDown();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Up || event.key === Qt.Key_K) {
                            grid.moveCurrentIndexUp();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Right || event.key === Qt.Key_L) {
                            grid.moveCurrentIndexRight();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Left || event.key === Qt.Key_H) {
                            grid.moveCurrentIndexLeft();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            pickerRoot.applyEntry(grid.currentIndex);
                            event.accepted = true;
                        }
                    }
                }
            }

            GridView {
                id: grid

                width: parent.width
                height: parent.height - 52
                clip: true
                cellWidth: 205
                cellHeight: 165
                model: ScriptModel {
                    values: {
                        const f = pickerRoot.filterText;
                        if (!f)
                            return pickerRoot.entries;
                        return pickerRoot.entries.filter(e => e.label.toLowerCase().includes(f));
                    }
                }
                currentIndex: 0
                highlightFollowsCurrentItem: true

                delegate: Item {
                    id: cardRoot

                    required property var modelData
                    required property int index

                    width: grid.cellWidth - 12
                    height: grid.cellHeight - 12

                    Rectangle {
                        id: card

                        anchors.fill: parent
                        radius: 0
                        color: cardMouse.containsMouse ? Theme.bgLight : Theme.bg
                        border.width: 2
                        border.color: grid.currentIndex === cardRoot.index ? Theme.accent : "transparent"
                        Behavior on border.color {
                            ColorAnimation {
                                duration: 100
                            }
                        }

                        Column {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 6

                            Item {
                                width: parent.width
                                height: parent.height - 26

                                Image {
                                    anchors.fill: parent
                                    source: cardRoot.modelData.image.startsWith("/") ? "file://" + cardRoot.modelData.image : cardRoot.modelData.image
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    cache: true
                                    visible: cardRoot.modelData.image !== ""
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 0
                                    color: Theme.bgLight
                                    visible: cardRoot.modelData.image === ""

                                    Text {
                                        anchors.centerIn: parent
                                        text: "no preview"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 11
                                        color: Theme.dim
                                    }
                                }

                                clip: true
                            }

                            Text {
                                width: parent.width
                                text: cardRoot.modelData.label
                                elide: Text.ElideRight
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                color: grid.currentIndex === cardRoot.index ? Theme.accent : Theme.fg
                            }
                        }
                    }

                    MouseArea {
                        id: cardMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            grid.currentIndex = cardRoot.index;
                            pickerRoot.applyEntry(cardRoot.index);
                        }
                        onEntered: grid.currentIndex = cardRoot.index
                    }
                }

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        pickerRoot.closePicker();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        pickerRoot.applyEntry(grid.currentIndex);
                        event.accepted = true;
                    }
                }
            }
        }
    }

    function applyEntry(i) {
        const vis = grid.model.values ?? [];
        const e = vis[i];
        if (!e)
            return;
        if (mode === "backgrounds")
            Actions.detached("nirarchy-background-set '" + e.value.replace(/'/g, "'\\''") + "'");
        else
            Actions.detached("nirarchy-theme-set '" + e.value.replace(/'/g, "'\\''") + "'");
        closePicker();
    }

    IpcHandler {
        target: "picker"

        function themes() {
            pickerRoot.openPicker("themes");
        }

        function backgrounds() {
            pickerRoot.openPicker("backgrounds");
        }
    }
}

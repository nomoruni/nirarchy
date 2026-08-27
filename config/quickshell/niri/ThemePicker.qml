import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects
import QtQuick.Shapes

PanelWindow {
    id: pickerRoot

    property bool open: false
    property string mode: "themes"
    property string filterText: ""
    property var entries: []
    property int selectedIndex: 0
    property bool imagesLoaded: false

    property int expandedWidth: 560
    property int expandedHeight: 320
    property int sliceWidth: 90
    property int sliceHeight: 300
    property int sliceSpacing: -24
    property int skewOffset: 22
    property int bottomChromeHeight: 66

    function openPicker(m) {
        mode = m;
        filterText = "";
        selectedIndex = 0;
        imagesLoaded = false;
        entries = [];
        loadEntries();
        open = true;
    }

    function closePicker() {
        open = false;
        filterText = "";
    }

    function loadEntries() {
        listProc.command = ["nirarchy-picker-list", mode];
        listProc.running = true;
    }

    function labelFor(value) {
        for (let i = 0; i < entries.length; i++)
            if (entries[i].value === value)
                return entries[i].label;
        return value;
    }

    function currentLabel() {
        if (entries.length === 0 || !itemMatches(selectedIndex))
            return filterText ? "No matches" : "";
        return entries[selectedIndex].label;
    }

    function matchesFilter(e) {
        if (!filterText)
            return true;
        return e.label.toLowerCase().includes(filterText);
    }

    function itemMatches(index) {
        return index >= 0 && index < entries.length && matchesFilter(entries[index]);
    }

    function firstMatchingIndex() {
        for (let i = 0; i < entries.length; i++)
            if (itemMatches(i))
                return i;
        return -1;
    }

    function visibleCountBefore(index) {
        let c = 0;
        for (let i = 0; i < index; i++)
            if (itemMatches(i))
                c++;
        return c;
    }

    function selectedVisiblePos() {
        return visibleCountBefore(selectedIndex);
    }

    function relativeIndex(index) {
        if (!itemMatches(index))
            return 0;
        return visibleCountBefore(index) - selectedVisiblePos();
    }

    function select(index) {
        if (entries.length === 0)
            return;
        let target = index;
        if (target < 0)
            target = entries.length - 1;
        else if (target >= entries.length)
            target = 0;
        if (!itemMatches(target))
            return;
        selectedIndex = target;
    }

    function selectAdjacent(direction) {
        let count = entries.length;
        if (count === 0)
            return;
        let index = selectedIndex;
        for (let i = 0; i < count; i++) {
            index = (index + direction + count) % count;
            if (itemMatches(index)) {
                selectedIndex = index;
                return;
            }
        }
    }

    function updateFilter(next) {
        filterText = next;
        if (!itemMatches(selectedIndex)) {
            const first = firstMatchingIndex();
            if (first >= 0)
                selectedIndex = first;
        }
    }

    function applySelected() {
        const e = entries[selectedIndex];
        if (!e || !itemMatches(selectedIndex))
            return;
        if (mode === "backgrounds")
            Actions.detached("nirarchy-background-set '" + e.value.replace(/'/g, "'\\''") + "'");
        else
            Actions.detached("nirarchy-theme-set '" + e.value.replace(/'/g, "'\\''") + "'");
        closePicker();
    }

    implicitWidth: 0
    implicitHeight: 0
    anchors { top: true; left: true; right: true; bottom: true }
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
                pickerRoot.imagesLoaded = true;
                if (rows.length > 0) {
                    pickerRoot.selectedIndex = 0;
                    Qt.callLater(function() { carousel.forceActiveFocus(); });
                }
            }
        }
    }

    Rectangle {
        id: scrim

        anchors.fill: parent
        color: Theme.bg
        visible: pickerRoot.open

        MouseArea {
            anchors.fill: parent
            onClicked: pickerRoot.closePicker()
        }
    }

    Item {
        id: card

        visible: pickerRoot.open && pickerRoot.imagesLoaded && pickerRoot.entries.length > 0
        width: Math.min(parent.width - 80, pickerRoot.expandedWidth + 13 * (pickerRoot.sliceWidth + pickerRoot.sliceSpacing) + 40)
        height: pickerRoot.expandedHeight + 52 + pickerRoot.bottomChromeHeight
        anchors.centerIn: parent

        MouseArea { anchors.fill: parent; onClicked: {} }

        Item {
            id: carousel

            anchors.top: parent.top
            anchors.topMargin: 28
            anchors.bottom: parent.bottom
            anchors.bottomMargin: pickerRoot.bottomChromeHeight
            anchors.horizontalCenter: parent.horizontalCenter
            width: pickerRoot.expandedWidth + 13 * (pickerRoot.sliceWidth + pickerRoot.sliceSpacing)
            clip: false
            focus: true

            readonly property real itemStep: pickerRoot.sliceWidth + pickerRoot.sliceSpacing
            readonly property real previewX: (width - pickerRoot.expandedWidth) / 2

            Keys.priority: Keys.BeforeItem
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    if (pickerRoot.filterText)
                        pickerRoot.updateFilter("");
                    else
                        pickerRoot.closePicker();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    pickerRoot.applySelected();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && event.modifiers & Qt.ShiftModifier)) {
                    pickerRoot.selectAdjacent(-1);
                    event.accepted = true;
                } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab) {
                    pickerRoot.selectAdjacent(1);
                    event.accepted = true;
                } else if (event.key === Qt.Key_Backspace) {
                    if (pickerRoot.filterText) {
                        pickerRoot.updateFilter(pickerRoot.filterText.slice(0, -1));
                        event.accepted = true;
                    }
                } else if (event.text && event.text.length === 1 && event.text.charCodeAt(0) >= 32
                           && event.text.charCodeAt(0) !== 127
                           && (event.modifiers === Qt.NoModifier || event.modifiers === Qt.ShiftModifier)) {
                    pickerRoot.updateFilter(pickerRoot.filterText + event.text);
                    event.accepted = true;
                }
            }

            Component.onCompleted: forceActiveFocus()

            Repeater {
                model: pickerRoot.entries.length

                delegate: Item {
                    id: item

                    required property int index

                    readonly property var itemData: pickerRoot.entries[index]
                    readonly property bool matched: pickerRoot.itemMatches(index)
                    readonly property int relIndex: pickerRoot.relativeIndex(index)
                    readonly property bool sel: matched && index === pickerRoot.selectedIndex
                    readonly property bool nearby: matched && Math.abs(relIndex) <= 12
                    property bool sourceActivated: false
                    onNearbyChanged: if (nearby) sourceActivated = true

                    visible: nearby
                    x: sel ? carousel.previewX
                           : (relIndex < 0
                              ? carousel.previewX + relIndex * carousel.itemStep
                              : carousel.previewX + pickerRoot.expandedWidth + pickerRoot.sliceSpacing + (relIndex - 1) * carousel.itemStep)
                    width: sel ? pickerRoot.expandedWidth : pickerRoot.sliceWidth
                    height: sel ? pickerRoot.expandedHeight : pickerRoot.sliceHeight
                    y: sel ? 0 : (pickerRoot.expandedHeight - pickerRoot.sliceHeight) / 2
                    z: sel ? 100 : 50 - Math.min(Math.abs(relIndex), 40)

                    readonly property real skAbs: Math.abs(pickerRoot.skewOffset)
                    readonly property real topLeft: pickerRoot.skewOffset >= 0 ? skAbs : 0
                    readonly property real topRight: pickerRoot.skewOffset >= 0 ? width : width - skAbs
                    readonly property real bottomRight: pickerRoot.skewOffset >= 0 ? width - skAbs : width
                    readonly property real bottomLeft: pickerRoot.skewOffset >= 0 ? 0 : skAbs

                    Item {
                        id: maskShape
                        anchors.fill: parent
                        visible: false
                        layer.enabled: true

                        Shape {
                            anchors.fill: parent
                            antialiasing: true
                            preferredRendererType: Shape.CurveRenderer
                            ShapePath {
                                fillColor: "white"
                                strokeColor: "transparent"
                                startX: item.topLeft; startY: 0
                                PathLine { x: item.topRight; y: 0 }
                                PathLine { x: item.bottomRight; y: item.height }
                                PathLine { x: item.bottomLeft; y: item.height }
                                PathLine { x: item.topLeft; y: 0 }
                            }
                        }
                    }

                    Item {
                        anchors.fill: parent
                        layer.enabled: true
                        layer.smooth: true
                        layer.effect: MultiEffect {
                            maskEnabled: true
                            maskSource: maskShape
                            maskThresholdMin: 0.3
                            maskSpreadAtMin: 0.3
                        }

                        Image {
                            anchors.fill: parent
                            source: item.sourceActivated && item.itemData && item.itemData.image
                                   ? (item.itemData.image.startsWith("/") ? "file://" + item.itemData.image : item.itemData.image)
                                   : ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: false
                            cache: true
                            smooth: true
                        }

                        Rectangle {
                            anchors.fill: parent
                            color: Qt.rgba(0, 0, 0, item.sel ? 0 : 0.5)
                        }
                    }

                    Shape {
                        anchors.fill: parent
                        antialiasing: true
                        preferredRendererType: Shape.CurveRenderer
                        ShapePath {
                            fillColor: "transparent"
                            strokeColor: item.sel ? Theme.accent : Theme.dim
                            strokeWidth: item.sel ? 3 : 1
                            startX: item.topLeft; startY: 0
                            PathLine { x: item.topRight; y: 0 }
                            PathLine { x: item.bottomRight; y: item.height }
                            PathLine { x: item.bottomLeft; y: item.height }
                            PathLine { x: item.topLeft; y: 0 }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: item.sel ? pickerRoot.applySelected() : pickerRoot.select(index)
                    }
                }
            }
        }

        Item {
            anchors.top: carousel.bottom
            anchors.topMargin: 10
            anchors.horizontalCenter: carousel.horizontalCenter
            width: pickerRoot.expandedWidth
            height: 46

            Text {
                id: titleLabel

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                text: pickerRoot.currentLabel()
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: 18
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: titleLabel.bottom
                anchors.topMargin: 5
                text: pickerRoot.filterText ? "filter: " + pickerRoot.filterText
                                            : (pickerRoot.mode === "backgrounds" ? "← → browse   ↵ apply   Esc close"
                                                                                : "← → browse   ↵ apply   Esc close   type to filter")
                color: Theme.dim
                font.family: Theme.fontFamily
                font.pixelSize: 11
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }
        }
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

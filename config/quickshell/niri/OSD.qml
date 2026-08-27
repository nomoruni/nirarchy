import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

PanelWindow {
    id: root

    visible: false

    anchors {
        bottom: true
    }

    implicitWidth: 300
    implicitHeight: 80

    color: "transparent"

    // Hide after 1.5 seconds
    Timer {
        id: hideTimer
        interval: 1500
        onTriggered: root.visible = false
    }

    // Track previous values to detect changes
    property int prevVolume: -1
    property int prevBrightness: -1
    property bool prevMuted: false

    // Current values
    property int volume: 0
    property bool muted: false
    property int brightness: 0
    property bool showBrightness: false

    function showOSD() {
        root.visible = true;
        hideTimer.restart();
    }

    // Volume monitoring
    readonly property Process volProc: Process {
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: StdioCollector {
            onStreamFinished: {
                const match = text.match(/Volume: (\d+\.?\d*)/);
                if (match) {
                    const newVol = Math.round(parseFloat(match[1]) * 100);
                    const newMuted = text.includes("MUTED");
                    
                    // Only show if changed
                    if (newVol !== root.prevVolume || newMuted !== root.prevMuted) {
                        root.volume = newVol;
                        root.muted = newMuted;
                        root.prevVolume = newVol;
                        root.prevMuted = newMuted;
                        root.showBrightness = false;
                        root.showOSD();
                    }
                }
            }
        }
    }

    // Brightness monitoring
    readonly property Process brightProc: Process {
        command: ["brightnessctl", "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                const current = parseInt(text.trim()) || 0;
                const max = 7142; // From brightnessctl max
                const newBright = Math.round((current / max) * 100);
                
                // Only show if changed
                if (newBright !== root.prevBrightness) {
                    root.brightness = newBright;
                    root.prevBrightness = newBright;
                    root.showBrightness = true;
                    root.showOSD();
                }
            }
        }
    }

    // Poll for changes (every 500ms)
    Timer {
        interval: 500
        running: true
        repeat: true
        onTriggered: {
            root.volProc.running = true;
            root.brightProc.running = true;
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#282828"
        border.color: "#7daea3"
        border.width: 2
        radius: 8

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 5

            // Volume indicator
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    text: root.muted ? "󰝟" : (root.volume < 30 ? "󰕿" : (root.volume < 70 ? "󰖀" : "󰕾"))
                    color: "#d4be98"
                    font.pixelSize: 20
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 8
                    color: "#3c3836"
                    radius: 4

                    Rectangle {
                        width: parent.width * (root.volume / 100)
                        height: parent.height
                        color: root.muted ? "#928374" : "#7daea3"
                        radius: 4
                    }
                }

                Text {
                    text: root.muted ? "Muted" : root.volume + "%"
                    color: "#d4be98"
                    font.pixelSize: 14
                }
            }

            // Brightness indicator
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    text: "󰃠"
                    color: "#d4be98"
                    font.pixelSize: 20
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 8
                    color: "#3c3836"
                    radius: 4

                    Rectangle {
                        width: parent.width * (root.brightness / 100)
                        height: parent.height
                        color: "#d4be98"
                        radius: 4
                    }
                }

                Text {
                    text: root.brightness + "%"
                    color: "#d4be98"
                    font.pixelSize: 14
                }
            }
        }
    }
}

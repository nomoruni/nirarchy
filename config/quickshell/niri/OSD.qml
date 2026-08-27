import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

PanelWindow {
    id: root

    anchors {
        bottom: true
        horizontalCenter: true
    }

    implicitWidth: 300
    implicitHeight: 80

    color: "transparent"

    // Hide after 2 seconds
    Timer {
        id: hideTimer
        interval: 2000
        onTriggered: root.visible = false
    }

    // Monitor volume changes
    property int volume: 0
    property bool muted: false

    readonly property Process volProc: Process {
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: StdioCollector {
            onStreamFinished: {
                const match = text.match(/Volume: (\d+\.?\d*)/);
                if (match) {
                    root.volume = Math.round(parseFloat(match[1]) * 100);
                    root.visible = true;
                    hideTimer.restart();
                }
                root.muted = text.includes("MUTED");
            }
        }
    }

    // Monitor brightness changes
    property int brightness: 0

    readonly property Process brightProc: Process {
        command: ["brightnessctl", "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                const current = parseInt(text.trim()) || 0;
                const max = 255; // Typical max brightness
                root.brightness = Math.round((current / max) * 100);
                root.visible = true;
                hideTimer.restart();
            }
        }
    }

    // Poll for changes
    Timer {
        interval: 1000
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
                    text: root.muted ? "󰝟" : (root.volume < 50 ? "󰕿" : (root.volume < 75 ? "󰖀" : "󰕾"))
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

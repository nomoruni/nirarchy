pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property int updates: 0
    property bool recording: false
    property bool idleOff: false
    property bool silenced: false
    property string weather: ""
    property bool weatherVisible: false

    readonly property string stateDir: Theme.home + "/.cache/nirarchy"

    function audioGlyph() {
        if (Sys.muted)
            return "󰝟";
        if (Sys.volume < 50)
            return "󰕿";
        if (Sys.volume < 75)
            return "󰖀";
        return "󰕾";
    }

    readonly property Process updProc: Process {
        command: ["sh", "-c", "pacman -Qu 2>/dev/null | wc -l"]
        stdout: StdioCollector {
            onStreamFinished: root.updates = parseInt(text.trim()) || 0
        }
    }

    readonly property Process recProc: Process {
        command: ["sh", "-c", "pgrep -f '^gpu-screen-recorder' >/dev/null && echo on || echo off"]
        stdout: StdioCollector {
            onStreamFinished: root.recording = text.trim() === "on"
        }
    }

    readonly property Process idleProc: Process {
        command: ["sh", "-c", "test -f " + root.stateDir + "/idle-off && echo off || echo on"]
        stdout: StdioCollector {
            onStreamFinished: root.idleOff = text.trim() === "off"
        }
    }

    readonly property Process silProc: Process {
        command: ["makoctl", "mode"]
        stdout: StdioCollector {
            onStreamFinished: root.silenced = /do-not-disturb/.test(text)
        }
    }

    readonly property Process weatherProc: Process {
        command: ["curl", "-sm4", "wttr.in/?format=%c+%t&u=metric"]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = text.trim();
                root.weatherVisible = v.length > 0 && v.length < 20;
                root.weather = v;
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.recProc.running = true;
            root.idleProc.running = true;
            root.silProc.running = true;
        }
    }

    Timer {
        interval: 21600000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.updProc.running = true;
            root.weatherProc.running = true;
        }
    }
}

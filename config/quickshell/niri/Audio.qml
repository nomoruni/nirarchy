pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    // Each entry: { index, name, description, volume (0..1), mute, isDefault }
    property var sinks: []
    property string defaultSink: ""
    property bool available: false

    function refresh() {
        pollProc.running = true;
    }

    function setVolume(index, v) {
        const pct = Math.round(Math.max(0, Math.min(1.5, v)) * 100);
        runCmd("pactl set-sink-volume " + index + " " + pct + "%");
    }

    function toggleMute(index) {
        runCmd("pactl set-sink-mute " + index + " toggle");
    }

    function setDefault(index) {
        runCmd("pactl set-default-sink " + index);
    }

    function runCmd(cmd) {
        cmdProc.command = ["sh", "-c", cmd];
        cmdProc.running = true;
        cmdRefresh.restart();
    }

    readonly property Process pollProc: Process {
        command: ["sh", "-c", "printf 'DEF|'; pactl get-default-sink 2>/dev/null; printf 'JS|'; pactl -f json list sinks 2>/dev/null | tr -d '\\n'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n");
                let def = "";
                let json = "";
                for (let i = 0; i < lines.length; i++) {
                    if (lines[i].startsWith("DEF|"))
                        def = lines[i].slice(4).trim();
                    else if (lines[i].startsWith("JS|"))
                        json = lines[i].slice(3);
                }
                root.defaultSink = def;

                let arr = [];
                try {
                    arr = JSON.parse(json);
                } catch (e) {
                    arr = [];
                }

                const out = [];
                for (let i = 0; i < arr.length; i++) {
                    const s = arr[i];
                    let sum = 0;
                    let n = 0;
                    for (const key in s.volume) {
                        const ch = s.volume[key];
                        if (ch && typeof ch.value === "number") {
                            sum += ch.value;
                            n++;
                        }
                    }
                    out.push({
                        index: s.index,
                        name: s.name,
                        description: s.description || s.name,
                        volume: n > 0 ? sum / (n * 65536) : 0,
                        mute: !!s.mute,
                        isDefault: s.name === def
                    });
                }
                root.available = out.length > 0;
                root.sinks = out;
            }
        }
    }

    readonly property Process cmdProc: Process {
        command: ["true"]
    }

    Timer {
        id: cmdRefresh

        interval: 200
        onTriggered: root.refresh()
    }
}

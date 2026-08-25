pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property int cpu: 0
    property bool batPresent: false
    property int batCapacity: 0
    property string batStatus: "Unknown"
    property int volume: 0
    property bool muted: false
    property string netIcon: "󰤮"
    property string netTooltip: "Disconnected"
    property bool btPresent: false
    property bool btPowered: false
    property int btConnected: 0

    function batIcon() {
        if (!batPresent)
            return "";
        let i;
        if (batCapacity >= 90) i = 9; else if (batCapacity >= 80) i = 8; else if (batCapacity >= 70) i = 7; else if (batCapacity >= 60) i = 6; else if (batCapacity >= 50) i = 5; else if (batCapacity >= 40) i = 4; else if (batCapacity >= 30) i = 3; else if (batCapacity >= 20) i = 2; else if (batCapacity >= 10) i = 1; else i = 0;
        const charging = batStatus === "Charging";
        const full = batStatus === "Full";
        if (full || (charging && batCapacity >= 95))
            return "󰂅";
        const icons = charging ? ["󰢜", "󰂆", "󰂇", "󰂈", "󰢝", "󰂉", "󰢞", "󰂊", "󰂋", "󰂅"] : ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"];
        return icons[i];
    }

    readonly property Process cpuProc: Process {
        command: [Theme.home + "/.local/bin/nirarchy-sys", "cpu"]
        stdout: StdioCollector {
            onStreamFinished: root.cpu = parseInt(text.trim()) || 0
        }
    }

    readonly property Process batProc: Process {
        command: [Theme.home + "/.local/bin/nirarchy-sys", "battery"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim().split("|");
                if (p[0] === "none") {
                    root.batPresent = false;
                    return;
                }
                root.batPresent = true;
                root.batCapacity = parseInt(p[0]) || 0;
                root.batStatus = p[1] ?? "Unknown";
            }
        }
    }

    readonly property Process audioProc: Process {
        command: [Theme.home + "/.local/bin/nirarchy-sys", "audio"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim().split("|");
                root.volume = parseInt(p[0]) || 0;
                root.muted = p[1] === "1";
            }
        }
    }

    readonly property Process netProc: Process {
        command: [Theme.home + "/.local/bin/nirarchy-sys", "net"]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = text.trim();
                if (v === "")
                    return;
                const p = v.split("|");
                const kind = p[0];
                if (kind === "eth") {
                    root.netIcon = "󰀂";
                    root.netTooltip = "Ethernet connected";
                } else if (kind === "wifi") {
                    const s = parseInt(p[1]) || 0;
                    root.netIcon = s >= 80 ? "󰤨" : s >= 60 ? "󰤥" : s >= 40 ? "󰤢" : s >= 20 ? "󰤟" : "󰤯";
                    root.netTooltip = (p[2] ?? "") + " (" + s + "%)";
                } else if (kind === "down") {
                    root.netIcon = "󰤮";
                    root.netTooltip = "Disconnected";
                }
            }
        }
    }

    readonly property Process btProc: Process {
        command: [Theme.home + "/.local/bin/nirarchy-sys", "bt"]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = text.trim();
                const p = v.split("|");
                if (p[0] === "none") {
                    root.btPresent = false;
                    return;
                }
                root.btPresent = true;
                root.btPowered = p[0] === "on";
                root.btConnected = parseInt(p[1]) || 0;
            }
        }
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.cpuProc.running = true;
            root.audioProc.running = true;
            root.netProc.running = true;
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.batProc.running = true;
            root.btProc.running = true;
        }
    }
}

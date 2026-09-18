pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool connected: false
    property string serverName: ""
    property string load: ""
    property string protocol: ""
    property string lastOutput: ""
    property bool needsRefresh: false
    property bool busy: false

    function refresh() {
        if (statusProc.running) {
            needsRefresh = true;
            return;
        }
        statusProc.running = true;
    }

    function toggle() {
        if (connected)
            disconnect();
        else
            connect();
    }

    function connect() {
        runCmd("protonvpn connect");
    }

    function disconnect() {
        runCmd("protonvpn disconnect");
    }

    function runCmd(cmd) {
        root.busy = true;
        cmdProc.command = ["sh", "-c", cmd + " 2>&1"];
        cmdProc.running = true;
    }

    readonly property Process statusProc: Process {
        command: ["sh", "-c", "protonvpn status 2>&1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                root.connected = false;
                root.serverName = "";
                root.load = "";
                root.protocol = "";
                for (let i = 0; i < lines.length; i++) {
                    const l = lines[i].trim();
                    if (l.startsWith("Status:")) {
                        root.connected = /^connected$/i.test(l.slice(7).trim());
                    } else if (l.startsWith("Server:")) {
                        root.serverName = l.slice(7).trim();
                    } else if (l.startsWith("Load:")) {
                        root.load = l.slice(5).trim();
                    } else if (l.startsWith("Protocol:")) {
                        root.protocol = l.slice(9).trim();
                    }
                }
                if (root.needsRefresh) {
                    root.needsRefresh = false;
                    statusProc.running = true;
                }
            }
        }
    }

    readonly property Process cmdProc: Process {
        stdout: StdioCollector {
            onStreamFinished: {
                root.busy = false;
                let out = text.trim().split("\n");
                out = out.filter(l => !l.startsWith("Server list")
                                       && !/^Updated/.test(l.trim())
                                       && !/^Exception|^Traceback|SystemExit|asyncio/.test(l));
                const joined = out.join("\n").trim();
                root.lastOutput = /^ERROR|^Error|failed|error/i.test(joined) ? joined : "";
                refresh();
            }
        }
    }
}

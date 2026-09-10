pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool connected: false
    property string server: ""
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
                root.server = "";
                root.load = "";
                root.protocol = "";
                for (const raw of lines) {
                    const l = raw.trim();
                    const stMatch = l.match(/^Status:\s*(.*)$/);
                    if (stMatch) {
                        root.connected = /^connected$/i.test(stMatch[1].trim());
                        continue;
                    }
                    const srvMatch = l.match(/^Server:\s*(.*)$/);
                    if (srvMatch) {
                        root.server = srvMatch[1];
                        continue;
                    }
                    const ldMatch = l.match(/^Load:\s*(.*)$/);
                    if (ldMatch) {
                        root.load = ldMatch[1];
                        continue;
                    }
                    const prMatch = l.match(/^Protocol:\s*(.*)$/);
                    if (prMatch) {
                        root.protocol = prMatch[1];
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

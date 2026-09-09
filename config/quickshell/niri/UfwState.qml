pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool enabled: false
    property bool loaded: false
    property var rules: []
    property string logging: "off"
    property string defaultIncoming: "deny"
    property string defaultOutgoing: "allow"

    function refresh() {
        statusProc.running = true;
    }

    function toggleUfw() {
        if (enabled)
            runUfw("disable");
        else
            runUfw("enable");
    }

    function addRule(action, port, protocol, from) {
        let cmd = "sudo ufw " + action + " " + port;
        if (protocol !== "")
            cmd += "/" + protocol;
        if (from !== "")
            cmd += " from " + from;
        runUfw(cmd);
    }

    function deleteRule(num) {
        runUfw("sudo ufw delete " + num);
    }

    function reload() {
        runUfw("sudo ufw reload");
    }

    function runUfw(cmd) {
        ufwProc.command = ["sh", "-c", cmd + " 2>&1"];
        ufwProc.running = true;
    }

    readonly property Process statusProc: Process {
        command: ["sh", "-c", "sudo ufw status verbose 2>&1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                root.enabled = lines[0]?.includes("active") || false;
                root.rules = [];
                let i = 1;
                while (i < lines.length) {
                    const l = lines[i].trim();
                    if (l.startsWith("Default:")) {
                        const parts = l.replace("Default:", "").trim().split(/\s+/);
                        root.defaultIncoming = parts[0] || "deny";
                        root.defaultOutgoing = parts[1] || "allow";
                    } else if (l.startsWith("Logging:")) {
                        root.logging = l.replace("Logging:", "").trim().split(/\s+/)[0] || "off";
                    } else if (l && !l.startsWith("---") && !l.startsWith("To") && !l.startsWith("Skipping")) {
                        const p = l.split(/\s+/);
                        if (p.length >= 3) {
                            root.rules.push({
                                "num": root.rules.length + 1,
                                "to": p[0],
                                "action": p[1],
                                "from": p[2],
                                "details": p.slice(3).join(" ")
                            });
                        }
                    }
                    i++;
                }
                root.loaded = true;
            }
        }
    }

    readonly property Process ufwProc: Process {
        stdout: StdioCollector {
            onStreamFinished: refresh()
        }
    }
}

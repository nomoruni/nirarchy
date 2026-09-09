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
    property string lastOutput: ""

    function refresh() {
        statusProc.running = false;
        statusProc.running = true;
    }

    function toggleUfw() {
        if (enabled)
            runUfw("sudo ufw disable");
        else
            runUfw("sudo ufw enable");
    }

    function addRule(action, port, protocol, from) {
        let cmd = "sudo ufw " + action + " " + port;
        if (protocol === "tcp" || protocol === "udp")
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
                const newRules = [];
                for (const raw of lines) {
                    const l = raw.trim();
                    if (!l)
                        continue;
                    const logMatch = l.match(/^Logging:\s+(\S+)/);
                    if (logMatch) {
                        root.logging = logMatch[1];
                        continue;
                    }
                    const def = l.match(/^Default:\s+(deny|allow|reject)\s*\(incoming\),\s*(deny|allow|reject)\s*\(outgoing\)/);
                    if (def) {
                        root.defaultIncoming = def[1];
                        root.defaultOutgoing = def[2];
                        continue;
                    }
                    if (l.startsWith("Status:")
                        || l.startsWith("New profiles:")
                        || l.startsWith("Skipping")
                        || l.startsWith("To")
                        || l.startsWith("--"))
                        continue;
                    const p = l.split(/\s+/);
                    if (p[0] === "Anywhere" && /^\(v[46]\)$/.test(p[1] || "")) {
                        p[0] = "Anywhere " + p[1];
                        p.splice(1, 1);
                    }
                    if (p.length >= 4
                        && /^(ALLOW|DENY|REJECT|LIMIT)$/.test(p[1])
                        && /^(IN|OUT|FWD|IN,OUT|IN,FWD|FWD,OUT|IN,OUT,FWD)$/.test(p[2])) {
                        newRules.push({
                            "num": newRules.length + 1,
                            "to": p[0],
                            "action": p[1],
                            "from": p[3],
                            "details": p.slice(4).join(" ")
                        });
                    }
                }
                root.rules = newRules;
                root.loaded = true;
            }
        }
    }

    readonly property Process ufwProc: Process {
        stdout: StdioCollector {
            onStreamFinished: {
                let out = text.trim().split("\n");
                out = out.filter(l => !/\(v6\)$/.test(l.trim()));
                const joined = out.join("\n");
                root.lastOutput = /^ERROR|^Error|Invalid|Bad|failed/i.test(joined) ? joined : "";
                refresh();
            }
        }
    }
}

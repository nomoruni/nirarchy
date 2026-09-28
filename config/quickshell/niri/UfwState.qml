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
    property bool needsRefresh: false

    function refresh() {
        if (statusProc.running) {
            needsRefresh = true;
            return;
        }
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
        const ids = String(num).split(",").map(s => s.trim()).filter(s => s !== "");
        const cmds = ids.map(id => "printf 'y\\n' | sudo ufw delete " + id).join(" && ");
        runUfw(cmds);
    }

    function reload() {
        runUfw("sudo ufw reload");
    }

    function runUfw(cmd) {
        ufwProc.command = ["sh", "-c", cmd + " 2>&1"];
        ufwProc.running = true;
    }

    readonly property Process statusProc: Process {
        command: ["sh", "-c", "sudo ufw status numbered 2>&1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                root.enabled = /^Status:\s*active\b/.test(lines[0] || "") || false;
                const newRules = [];
                for (const l of lines) {
                    if (l.startsWith("Status:")
                        || l.startsWith("New profiles:")
                        || l.startsWith("Skipping")
                        || l.startsWith("To")
                        || l.startsWith("--"))
                        continue;
                    // Extract rule text after the "N]" prefix, matching the original logic
                    const rm = l.match(/^\[([0-9,\s]+)\]\s+(.+)$/);
                    let ruleText = l;
                    let ruleNum = "";
                    if (rm) {
                        ruleNum = rm[1].replace(/\s+/g, "");
                        ruleText = rm[2];
                    }
                    const p = ruleText.split(/\s+/);
                    // ----- Identify format & parse -----
                    // Format 1: v6 variant (e.g. [ 3] 3329 (v6) ALLOW IN Anywhere (v6))
                    // p[0] = identifier, p[1] = "(v6)", p[2] = ACTION, p[3] = DIRECTION, p[4] = FROM, p[5] = "(v6)"
                    let ruleEntry = null;
                    if (p.length >= 5
                        && /^(ALLOW|DENY|REJECT|LIMIT)$/.test(p[2])
                        && /^(IN|OUT|FWD|IN,OUT|IN,FWD|FWD,OUT|IN,OUT,FWD)$/.test(p[3])
                        && /^\(v[46]\)$/.test(p[1] || "")) {
                        ruleEntry = {
                            "num": ruleNum !== "" ? ruleNum : String(newRules.length + 1),
                            "to": p[0] + " " + p[1],       // e.g. "3329 (v6)" — (v6) in the name
                            "action": p[2],
                            "direction": p[3],
                            "from": p[4],
                            "details": ""                  // (v6) already in "to"
                        };
                    }
                    // Format 2: Standard with "Anywhere" prefix (e.g. [1] Anywhere ALLOW IN 192.168.122.0/24)
                    if (!ruleEntry && p[0] === "Anywhere") {
                        if (p.length >= 4
                            && /^(ALLOW|DENY|REJECT|LIMIT)$/.test(p[1])
                            && /^(IN|OUT|FWD|IN,OUT|IN,FWD|FWD,OUT|IN,OUT,FWD)$/.test(p[2])) {
                            ruleEntry = {
                                "num": ruleNum !== "" ? ruleNum : String(newRules.length + 1),
                                "to": p[0],
                                "action": p[1],
                                "direction": p[2],
                                "from": p[3],
                                "details": p.slice(4).join(" ")
                            };
                        }
                    }
                    // Format 3: Verbose format (e.g. [3] 224.0.0.251 5353 on enp+ ALLOW IN Anywhere # comment)
                    // p[0] = IP, p[1] = port, p[2] = "on", p[3] = interface, p[4] = ACTION, p[5] = DIRECTION, p[6] = FROM
                    if (!ruleEntry && p.length >= 7 && p[0] !== "Anywhere"
                        && p[2] === "on"
                        && /^(ALLOW|DENY|REJECT|LIMIT)$/.test(p[4])
                        && /^(IN|OUT|FWD|IN,OUT|IN,FWD|FWD,OUT|IN,OUT,FWD)$/.test(p[5])) {
                        ruleEntry = {
                            "num": ruleNum !== "" ? ruleNum : String(newRules.length + 1),
                            "to": p.slice(0, 4).join(" "),        // IP + port + on + interface
                            "action": p[4],
                            "direction": p[5],
                            "from": p[6],
                            "details": p.slice(7).join(" ")
                        };
                    }
                    if (ruleEntry) {
                        newRules.push(ruleEntry);
                    }
                }
                root.rules = newRules;
                root.loaded = true;
                if (root.needsRefresh) {
                    root.needsRefresh = false;
                    statusProc.running = true;
                }
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
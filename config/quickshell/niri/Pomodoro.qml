pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property int workDuration: 25 * 60
    property int breakDuration: 5 * 60
    property int longBreakDuration: 15 * 60
    property int sessionsBeforeLong: 4

    property string mode: "idle"
    property int remaining: 0
    property int sessions: 0
    property bool running: false
    property int endTimestamp: 0

    readonly property string cacheFile: Quickshell.env("HOME") + "/.cache/nirarchy/pomodoro.json"

    function formattedTime() {
        const m = Math.floor(remaining / 60);
        const s = remaining % 60;
        return (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s;
    }

    function modeIcon() {
        if (mode === "work")
            return "󰔛";
        if (mode === "break" || mode === "longbreak")
            return "󰔠";
        return "";
    }

    function modeLabel() {
        if (mode === "work")
            return "Work";
        if (mode === "break")
            return "Break";
        if (mode === "longbreak")
            return "Long Break";
        return "Pomodoro";
    }

    function start() {
        if (running) {
            running = false;
            saveState();
            return;
        }
        if (mode === "idle") {
            mode = "work";
            remaining = workDuration;
        }
        endTimestamp = Date.now() / 1000 + remaining;
        running = true;
        saveState();
    }

    function reset() {
        running = false;
        mode = "idle";
        remaining = 0;
        endTimestamp = 0;
        saveState();
    }

    function skip() {
        advanceMode();
        if (mode !== "idle") {
            endTimestamp = Date.now() / 1000 + remaining;
            running = true;
        }
        saveState();
    }

    function advanceMode() {
        running = false;
        if (mode === "work") {
            sessions++;
            if (sessions >= sessionsBeforeLong) {
                mode = "longbreak";
                remaining = longBreakDuration;
                sessions = 0;
            } else {
                mode = "break";
                remaining = breakDuration;
            }
        } else {
            mode = "work";
            remaining = workDuration;
        }
    }

    function saveState() {
        const data = JSON.stringify({
            workDuration: workDuration,
            breakDuration: breakDuration,
            longBreakDuration: longBreakDuration,
            sessionsBeforeLong: sessionsBeforeLong,
            mode: mode,
            remaining: remaining,
            sessions: sessions,
            running: running,
            endTimestamp: endTimestamp
        });
        saveProc.command = ["sh", "-c", "mkdir -p $(dirname " + cacheFile + ") && echo '" + data + "' > " + cacheFile];
        saveProc.running = true;
    }

    function loadState() {
        loadProc.running = true;
    }

    readonly property Process saveProc: Process {
        command: ["true"]
    }

    readonly property Process loadProc: Process {
        command: ["cat", cacheFile]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text.trim());
                    if (data.workDuration) root.workDuration = data.workDuration;
                    if (data.breakDuration) root.breakDuration = data.breakDuration;
                    if (data.longBreakDuration) root.longBreakDuration = data.longBreakDuration;
                    if (data.sessionsBeforeLong) root.sessionsBeforeLong = data.sessionsBeforeLong;
                    root.mode = data.mode || "idle";
                    root.remaining = data.remaining || 0;
                    root.sessions = data.sessions || 0;
                    root.running = data.running || false;
                    root.endTimestamp = data.endTimestamp || 0;
                    if (root.running && root.endTimestamp > 0) {
                        const now = Date.now() / 1000;
                        root.remaining = Math.max(0, Math.round(root.endTimestamp - now));
                        if (root.remaining <= 0) {
                            root.advanceMode();
                            if (root.mode !== "idle") {
                                root.endTimestamp = Date.now() / 1000 + root.remaining;
                                root.running = true;
                            }
                            root.saveState();
                        }
                    }
                } catch (e) {}
            }
        }
    }

    function setDurations(work, brk, lbrk, sessions) {
        workDuration = work;
        breakDuration = brk;
        longBreakDuration = lbrk;
        sessionsBeforeLong = sessions;
        saveState();
    }

    Timer {
        interval: 1000
        running: root.running
        repeat: true
        onTriggered: {
            if (!root.running)
                return;
            const now = Date.now() / 1000;
            root.remaining = Math.max(0, Math.round(root.endTimestamp - now));
            if (root.remaining <= 0) {
                root.advanceMode();
                if (root.mode !== "idle") {
                    root.endTimestamp = Date.now() / 1000 + root.remaining;
                    root.running = true;
                } else {
                    root.running = false;
                }
                root.saveState();
            }
        }
    }

    Component.onCompleted: loadState()
}

pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// MPD controller backed by mpc (mirrors Player.qml's single shell round-trip).
Singleton {
    id: root

    property bool available: false
    property string status: ""
    property string title: ""
    property string artist: ""
    property string album: ""
    property real position: 0
    property real length: 0
    property int volume: -1
    property string queuePos: ""

    readonly property bool playing: status === "playing"
    readonly property bool hasTrack: title !== ""
    readonly property bool canControl: available && (status === "playing" || status === "paused")
    readonly property string displayTitle: title.length > 21 ? title.slice(0, 20) + "…" : title

    function fmtTime(s) {
        if (!isFinite(s) || s < 0)
            return "0:00";
        const m = Math.floor(s / 60);
        const sec = Math.floor(s % 60);
        return m + ":" + (sec < 10 ? "0" : "") + sec;
    }

    // "m:ss" or "h:mm:ss" -> seconds
    function parseMss(s) {
        const parts = String(s).split(":").map(x => parseInt(x, 10));
        if (parts.length === 0 || parts.some(x => !isFinite(x)))
            return 0;
        let sec = 0;
        for (let i = 0; i < parts.length; i++)
            sec = sec * 60 + (parts[i] || 0);
        return sec;
    }

    // One shell round-trip gathering everything via mpc.
    function pollCommand() {
        return [
            "if ! mpc status >/dev/null 2>&1; then printf 'ST|\\nTI|\\nAR|\\nAL|\\nPO|\\nLN|\\nVO|\\nQP|\\n'; exit 0; fi",
            "printf 'ST|%s\\n' \"$(mpc status %state% 2>/dev/null)\"",
            "TI=$(mpc -f '%title%' current 2>/dev/null); [ -n \"$TI\" ] || TI=$(mpc -f '%file%' current 2>/dev/null | sed 's#.*/##; s/\\.[^.]*$//')",
            "printf 'TI|%s\\n' \"$TI\"",
            "printf 'AR|%s\\n' \"$(mpc -f '%artist%' current 2>/dev/null)\"",
            "printf 'AL|%s\\n' \"$(mpc -f '%album%' current 2>/dev/null)\"",
            "printf 'PO|%s\\n' \"$(mpc status %currenttime% 2>/dev/null)\"",
            "printf 'LN|%s\\n' \"$(mpc status %totaltime% 2>/dev/null)\"",
            "printf 'VO|%s\\n' \"$(mpc status %volume% 2>/dev/null)\"",
            "printf 'QP|%s\\n' \"$(mpc status 2>/dev/null | sed -n 's/.*#\\([0-9]*\\/[0-9]*\\).*/\\1/p' | head -n1)\""
        ].join("\n");
    }

    function refresh() {
        pollProc.command = ["sh", "-c", pollCommand()];
        pollProc.running = true;
    }

    function runCmd(cmd) {
        cmdProc.command = ["sh", "-c", cmd];
        cmdProc.running = true;
        cmdRefresh.restart();
    }

    function togglePlay() {
        runCmd("mpc toggle");
    }

    function next() {
        runCmd("mpc next");
    }

    function previous() {
        runCmd("mpc prev");
    }

    function setVolume(v) {
        const pct = Math.round(Math.max(0, Math.min(1, v)) * 100);
        runCmd("mpc volume " + pct);
    }

    function seek(ratio) {
        if (root.length <= 0)
            return;
        const sec = Math.max(0, Math.min(1, ratio)) * root.length;
        runCmd("mpc seek " + sec.toFixed(0));
    }

    readonly property Process pollProc: Process {
        command: ["true"]
        stdout: StdioCollector {
            onStreamFinished: {
                const fields = {};
                const lines = text.split("\n");
                for (let i = 0; i < lines.length; i++) {
                    const idx = lines[i].indexOf("|");
                    if (idx < 0)
                        continue;
                    fields[lines[i].slice(0, idx)] = lines[i].slice(idx + 1);
                }
                root.available = (fields["ST"] ?? "") !== "";
                root.status = fields["ST"] ?? "";
                root.title = fields["TI"] ?? "";
                root.artist = fields["AR"] ?? "";
                root.album = fields["AL"] ?? "";
                root.position = root.parseMss(fields["PO"] ?? "0");
                root.length = root.parseMss(fields["LN"] ?? "0");
                root.volume = parseInt(fields["VO"] ?? "-1", 10) || -1;
                root.queuePos = fields["QP"] ?? "";
            }
        }
    }

    readonly property Process cmdProc: Process {
        command: ["true"]
    }

    Timer {
        id: cmdRefresh

        interval: 400
        onTriggered: root.refresh()
    }

    Timer {
        interval: root.playing ? 1000 : 2500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
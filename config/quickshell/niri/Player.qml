pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool available: false
    property string status: ""
    property string playerName: ""
    property string title: ""
    property string artist: ""
    property string album: ""
    property real position: 0
    property real length: 0
    property real playerVolume: 0
    property var players: []
    property string selectedPlayer: ""

    readonly property bool playing: status === "Playing"
    readonly property bool hasTrack: title !== ""
    readonly property bool canControl: available && (status === "Playing" || status === "Paused")
    readonly property string displayTitle: title.length > 21 ? title.slice(0, 20) + "…" : title

    function fmtTime(s) {
        if (!isFinite(s) || s < 0)
            return "0:00";
        const m = Math.floor(s / 60);
        const sec = Math.floor(s % 60);
        return m + ":" + (sec < 10 ? "0" : "") + sec;
    }

    // Single shell round-trip gathering everything we need from the selected
    // player (falls back to the first available one).
    function pollCommand() {
        const sel = String(root.selectedPlayer).replace(/'/g, "");
        return [
            "p='" + sel + "'",
            "[ -n \"$p\" ] || p=$(playerctl -l 2>/dev/null | head -n1)",
            "if [ -z \"$p\" ]; then printf 'PL|\\nST|\\nLS|\\n'; exit 0; fi",
            "printf 'PL|%s\\n' \"$p\"",
            "printf 'ST|%s\\n' \"$(playerctl -p \"$p\" status 2>/dev/null)\"",
            "printf 'TI|%s\\n' \"$(playerctl -p \"$p\" metadata title 2>/dev/null | head -n1)\"",
            "printf 'AR|%s\\n' \"$(playerctl -p \"$p\" metadata artist 2>/dev/null | head -n1)\"",
            "printf 'AL|%s\\n' \"$(playerctl -p \"$p\" metadata album 2>/dev/null | head -n1)\"",
            "printf 'LN|%s\\n' \"$(playerctl -p \"$p\" metadata mpris:length 2>/dev/null | head -n1)\"",
            "printf 'PO|%s\\n' \"$(playerctl -p \"$p\" position 2>/dev/null)\"",
            "printf 'VO|%s\\n' \"$(playerctl -p \"$p\" volume 2>/dev/null)\"",
            "printf 'LS|%s\\n' \"$(playerctl -l 2>/dev/null | paste -sd, -)\""
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
        runCmd("playerctl play-pause");
    }

    function next() {
        runCmd("playerctl next");
    }

    function previous() {
        runCmd("playerctl previous");
    }

    function setVolume(v) {
        runCmd("playerctl volume " + Math.max(0, Math.min(1, v)).toFixed(2));
    }

    function seek(ratio) {
        if (root.length <= 0)
            return;
        const sec = Math.max(0, Math.min(1, ratio)) * root.length;
        runCmd("playerctl position " + sec.toFixed(1));
    }

    function selectPlayer(name) {
        root.selectedPlayer = name;
        root.refresh();
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
                const pl = fields["PL"] ?? "";
                root.playerName = pl;
                root.available = pl !== "";
                root.status = fields["ST"] ?? "";
                root.title = fields["TI"] ?? "";
                root.artist = fields["AR"] ?? "";
                root.album = fields["AL"] ?? "";
                const ln = parseInt(fields["LN"] ?? "0") || 0;
                root.length = ln > 0 ? ln / 1000000 : 0;
                root.position = parseFloat(fields["PO"] ?? "0") || 0;
                root.playerVolume = parseFloat(fields["VO"] ?? "0") || 0;
                const list = (fields["LS"] ?? "").split(",").filter(s => s !== "");
                root.players = list;
                if (root.selectedPlayer !== "" && list.indexOf(root.selectedPlayer) < 0)
                    root.selectedPlayer = "";
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

pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    function run(cmd) {
        runProc.command = ["sh", "-c", cmd];
        runProc.running = true;
    }

    function detached(cmd) {
        Quickshell.execDetached(["sh", "-c", cmd]);
    }

    readonly property Process runProc: Process {
        stdout: StdioCollector {}
        stderr: StdioCollector {}
    }
}

import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: niriState

    property string output
    property var visibleWorkspaces: []
    property int activeIdx: -1
    property bool urgent: false

    function focusWs(ws) {
        if (ws === null || ws === undefined)
            return;
        const arg = String(ws.id ?? (ws.idx + 1));
        Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", arg]);
    }

    function cycleWorkspace(dir) {
        const action = dir > 0 ? "focus-workspace-down" : "focus-workspace-up";
        Quickshell.execDetached(["niri", "msg", "action", action]);
    }

    Process {
        id: wsProc

        command: ["niri", "msg", "--json", "workspaces"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const all = JSON.parse(text);
                    const mine = all.filter(w => !niriState.output || w.output === niriState.output);
                    mine.sort((a, b) => a.idx - b.idx);
                    niriState.visibleWorkspaces = mine;
                    const act = mine.find(w => w.is_active);
                    niriState.activeIdx = act ? (act.num ?? (act.idx + 1)) : -1;
                    niriState.urgent = mine.some(w => w.is_urgent);
                } catch (e) {}
            }
        }
    }

    Process {
        id: eventStream

        running: true
        command: ["niri", "msg", "event-stream"]
        stdout: SplitParser {
            onRead: data => {
                if (/WorkspacesChanged|WorkspaceActiveChanged|WorkspaceUrgencyChanged/.test(data))
                    refreshTimer.restart();
            }
        }
    }

    Timer {
        id: refreshTimer

        interval: 100
        onTriggered: wsProc.running = true
    }

    Timer {
        interval: 500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: wsProc.running = true
    }
}

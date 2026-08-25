pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string themePath: home + "/.config/nirarchy/current/theme"
    readonly property string dataDir: home + "/.local/share/nirarchy"

    property var colors: ({
        "accent": "#7aa2f7",
        "cursor": "#c0caf5",
        "foreground": "#a9b1d6",
        "background": "#1a1b26",
        "selection_foreground": "#c0caf5",
        "selection_background": "#7aa2f7",
        "color0": "#32344a",
        "color1": "#f7768e",
        "color2": "#9ece6a",
        "color3": "#e0af68",
        "color4": "#7aa2f7",
        "color5": "#ad8ee6",
        "color6": "#449dab",
        "color7": "#787c99",
        "color8": "#444b6a",
        "color9": "#ff7a93",
        "color10": "#b9f27c",
        "color11": "#ff9e64",
        "color12": "#7da6ff",
        "color13": "#bb9af7",
        "color14": "#0db9d7",
        "color15": "#acb0d0"
    })

    readonly property color accent: colors.accent
    readonly property color fg: colors.foreground
    readonly property color bg: colors.background
    readonly property color red: colors.color1
    readonly property color green: colors.color2
    readonly property color yellow: colors.color3
    readonly property color dim: colors.color7
    readonly property color bgLight: Qt.lighter(colors.background, 1.35)

    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property int barHeight: 30
    readonly property int fontSize: 13

    function c(name) {
        return colors[name] ?? "#ff00ff";
    }

    function applyColors() {
        const txt = themeFile.text();
        if (!txt)
            return;
        const map = {};
        const lines = txt.split("\n");
        for (let i = 0; i < lines.length; i++) {
            const m = lines[i].match(/^([a-z0-9_]+)\s*=\s*"([^"]+)"/);
            if (m)
                map[m[1]] = m[2];
        }
        if (Object.keys(map).length > 0)
            root.colors = Object.assign({}, root.colors, map);
    }

    FileView {
        id: themeFile

        path: root.themePath + "/colors.toml"
        watchChanges: true
        onFileChanged: {
            reload();
            waitForJob();
            Qt.callLater(root.applyColors);
        }
        onLoaded: root.applyColors()
    }

    // Poll for theme switches: symlink swaps don't reliably fire inotify
    property string _lastTheme: ""

    Timer {
        interval: 1500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: nameFile.reload()
    }

    FileView {
        id: nameFile

        path: root.home + "/.config/nirarchy/theme-name"
        onLoaded: {
            const name = text().trim();
            if (name && name !== root._lastTheme) {
                root._lastTheme = name;
                themeFile.reload();
                themeFile.waitForJob();
                root.applyColors();
            }
        }
    }

    Component.onCompleted: {
        _lastTheme = "";
        nameFile.reload();
        themeFile.reload();
        applyColors();
    }
}

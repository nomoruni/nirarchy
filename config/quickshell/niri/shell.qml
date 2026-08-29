//@ pragma UseQApplication

import Quickshell
import QtQuick

ShellRoot {
    Variants {
        model: Quickshell.screens

        Bar {}
    }

    ThemePicker {}
    PolkitDialog {}
    PrintPopup {}
}

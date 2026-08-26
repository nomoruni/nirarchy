<div align="center">

# 󰚰 Nirarchy

**The Omarchy experience, rebuilt for the [Niri](https://github.com/YaLTeR/niri) compositor.**

A complete, opinionated desktop shell: Quickshell top bar, Walker menus,
hyprlock, Tokyo Night theming across every surface, WiFi/Bluetooth managers,
calendar, theme picker with live previews — and [opencode](https://opencode.ai)
as its only AI agent.

</div>

---

## What you get

| Area | Details |
|---|---|
| **Compositor** | niri with Omarchy's signature cyan→green 45° gradient border, 5px gaps, `prefer-no-csd` |
| **Display manager** | SDDM with themed variants (logo, password entry, lock icons) — switches with theme |
| **Top bar** | Quickshell: workspace dots (filled = active), clock + calendar popup, weather, update/recording/idle/silence indicators, tray, wifi/bluetooth/volume/CPU/battery |
| **Managers** | In-bar WiFi and Bluetooth popup panels (nmcli/bluetoothctl), wiremix audio TUI |
| **Menus** | Walker + Elephant: app launcher, Nirarchy menu (Apps/Learn/Trigger/Style/Setup/Install/Remove/Update/System) |
| **Theming** | 8 themes (Tokyo Night default, Catppuccin, Everforest, Rose Pine, Gruvbox, Nord, Kanagawa, Osaka Jade) — one switch recolors the bar, foot terminals (even running ones), window borders, walker, mako, swayosd, lock screen, wallpaper, SDDM theme, and Papirus folder colors, live |
| **Theme picker** | Full-screen overlay with image previews, search, arrow/hjkl navigation, Enter to apply |
| **Lock & idle** | hyprlock with themed palette over blurred wallpaper; locks on sleep and on demand (never on idle) |
| **Screenshots** | smart region/window detection, satty editing, OCR text extraction, gpu-screen-recorder |
| **AI agent** | opencode on `Super+Shift+A`, opens in the focused terminal's cwd; ships `nirarchy` and `diagnose-crash` skills |
| **Crash watcher** | systemd-coredump monitor → "Process crashed" notification → click to diagnose with opencode |
| **Power** | TLP + tlp-pd (no power-profiles-daemon) |
| **Portals** | xdg-desktop-portal-wlr (screenshots/screen sharing) + xdg-desktop-portal-gtk (file chooser) — no nautilus dependency |

## Requirements

- Arch Linux (or Arch-based)
- [SDDM](https://github.com/sddm/sddm) display manager (installed automatically, with themed variants)
- `opencode` installed and configured if you want the AI features (optional)

## Install

On a fresh Arch installation:

```bash
git clone https://github.com/nomoruni/nirarchy.git
cd nirarchy
bash install.sh
```

The installer will ask you to select a keyboard variant (default: US International).

Then **log out and select "niri"** in your display manager.

The installer is idempotent and backs up any existing configs to `*.bak.<timestamp>`.
Useful flags: `--no-pkg` (skip packages), `--no-services` (skip systemd enablement).

To remove: `bash uninstall.sh`

## Essential keybinds

| Keys | Action |
|---|---|
| `Super + Return` | Terminal (foot) |
| `Super + Space` | App launcher |
| `Super + Alt + Space` | Nirarchy menu |
| `Super + Escape` | System menu (lock/suspend/logout) |
| `Super + Shift + K` | Keybinding cheat sheet |
| `Super + Shift + A` | opencode AI agent |
| `Super + Q` | Close window |
| `Super + W` | Browser |
| `Super + E` | File manager (pcmanfm) |
| `Super + F` / `Super + Shift + F` | Maximize / Fullscreen |
| `Super + 1..0` | Workspaces (dots on the bar) |
| `Super + S` | Scratchpad workspace |
| `Print` | Screenshot |
| `Super + Ctrl + Space` | Wallpaper picker |
| `Super + Shift + Ctrl + Space` | Theme picker |
| `Click clock` | Calendar |

Full list: `Super + Shift + K`.

## Troubleshooting

```bash
journalctl --user -u nirarchy-bar        # bar logs (auto-restarts on crash)
journalctl --user -u nirarchy-crash-watch
nirarchy-debug --print                   # full system report
nirarchy-debug --opencode                # report analyzed by opencode
```

## Credits

- [Omarchy](https://github.com/basecamp/omarchy) — design, theming, menu structure,
  crash-watch design and the omarchy.ttf brand glyph (MIT)
- [niri](https://github.com/YaLTeR/niri), [Quickshell](https://quickshell.outfoxxed.me),
  [Walker](https://github.com/abenz1267/walker) + [Elephant](https://github.com/abenz1267/elephant),
  [opencode](https://opencode.ai)

## License

MIT — see [LICENSE](LICENSE).

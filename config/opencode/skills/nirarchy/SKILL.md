---
name: nirarchy
description: >
  REQUIRED for end-user customization of this Linux desktop, window manager, or system
  config. Use when editing ~/.config/niri/, ~/.config/quickshell/niri/, ~/.config/walker/,
  ~/.config/mako/, ~/.config/foot/, ~/.config/hypr/ (hyprlock/hypridle only),
  ~/.config/nirarchy/, or ~/.local/share/nirarchy/ themes. Triggers: niri, window rules,
  animations, keybinds, monitors, gaps, borders, workspaces, quickshell bar, calendar,
  wifi/bluetooth popups, walker, terminal config, themes, wallpaper, night light, idle,
  lock screen, screenshots, reminders, swayosd, and user-facing nirarchy-* commands.
  Excludes COSMIC and KDE/Plasma configuration.
---

# Nirarchy Skill

Manage **Nirarchy** — an Omarchy-style desktop experience built on the **niri** Wayland
compositor with a **Quickshell** bar, themed in Tokyo Night by default. It replicates the
look and workflow of [Omarchy](https://omarchy.org/) (Hyprland) on niri.

## When This Skill MUST Be Used

**ALWAYS invoke this skill for requests involving ANY of these:**

- Editing ANY file in `~/.config/niri/config.kdl` (keybinds, layout, window rules, animations)
- Editing ANY file in `~/.config/quickshell/niri/` (bar, popups, theme picker, calendar)
- Editing `~/.config/walker/`, `~/.config/mako/`, `~/.config/foot/`, `~/.config/swayosd/`
- Editing `~/.config/hypr/hyprlock.conf` or `~/.config/hypr/hypridle.conf` (lock/idle only)
- Themes, wallpapers, fonts, colors, appearance
- Keybinds, workspaces, screenshots, screen recording, reminders
- Any `nirarchy-*` command behavior

**Do NOT use this skill for COSMIC or KDE/Plasma sessions** — they coexist on this machine
but are separate desktops.

## Critical Safety Rules

- `~/.local/share/nirarchy/themes/<name>/colors.toml` is the source of truth for a theme's
  palette. Edit it, then apply with `nirarchy-theme-set <name>`.
- `~/.local/share/nirarchy/default/` contains templates that `nirarchy-theme-set` regenerates
  from (walker css, mako include, foot colors, swayosd css). Editing generated files directly
  in `~/.config/walker/themes/`, `~/.config/mako/config`, `~/.config/nirarchy/current/` is
  POINTLESS — they are overwritten on every theme change. Change the generator or the template.
- The border block in `~/.config/niri/config.kdl` between `// NIRARCHY-THEME:BEGIN/END` is
  managed by `nirarchy-theme-set`. Never hand-edit inside the sentinels.
- `~/.config/foot/foot.ini` includes `~/.config/nirarchy/current/foot.ini` (generated).
  Set font/padding/behavior in foot.ini itself; colors come from the theme.

## System Architecture

| Component | Purpose | Config Location |
|-----------|---------|-----------------|
| **niri** | Wayland compositor | `~/.config/niri/config.kdl` |
| **Quickshell** | Top bar, wifi/bt popups, calendar, theme picker | `~/.config/quickshell/niri/` |
| **Walker + Elephant** | App launcher, dmenu menus | `~/.config/walker/`, `~/.config/elephant/` |
| **Foot** | Terminal (themed per palette) | `~/.config/foot/foot.ini` |
| **Mako** | Notifications | `~/.config/mako/config` (includes core.ini) |
| **SwayOSD** | Volume/brightness OSD | `~/.config/swayosd/style.css` |
| **hyprlock/hypridle** | Lock screen / idle+sleep lock | `~/.config/hypr/` |
| **TLP + tlp-pd** | Power management | `/etc/tlp.conf`, `tlpctl` |
| **iwd + NetworkManager** | WiFi backend (impala works) | `/etc/NetworkManager/conf.d/` |
| **opencode** | The AI agent (only agent) | `~/.config/opencode/` |

## Command Discovery

All user commands are `~/.local/bin/nirarchy-*` scripts. Key ones:

```bash
nirarchy-menu [submenu]            # Main menu (Super+Alt+Space); submenus: system, theme,
                                   #   background, toggle, capture, screenrecord, setup, power
nirarchy-theme-set <name>          # Apply theme: bar+foot+border+walker+mako+swayosd+lock+wallpaper
nirarchy-theme-picker [themes|backgrounds]  # Graphical preview picker (qs ipc)
nirarchy-capture-screenshot [mode] # smart|region|fullscreen, satty editing
nirarchy-capture-screenrecording [--with-desktop-audio|--with-microphone-audio|--stop-recording]
nirarchy-capture-text-extraction   # OCR region to clipboard
nirarchy-system-lock               # hyprlock (also fires before sleep)
nirarchy-toggle-{idle,nightlight,notification-silencing,bar}
nirarchy-scratchpad                # Toggle named "scratchpad" workspace
nirarchy-launch-{wifi,audio,bluetooth,files,walker}
nirarchy-agent                     # Open opencode in focused terminal's cwd
nirarchy-reminder <min> [msg]      # systemd-run based reminders; show|clear
nirarchy-debug [--print]           # System debug report (feeds opencode)
nirarchy-agent-crash [pid]         # Diagnose crash with opencode (uses diagnose-crash skill)
```

## Keybind Map (niri config.kdl)

Super+Return terminal · Super+W firefox · Super+Q close · Super+E files · Super+F maximize ·
Super+Shift+F fullscreen · Super+T float · Super+Space launcher · Super+Alt+Space menu ·
Super+Escape system menu · Super+Shift+K keybind list · Super+V clipboard · Super+S scratchpad ·
Super+Ctrl+L lock · Super+Shift+A / Super+Ctrl+Return opencode agent · Print screenshot ·
Super+Shift+Ctrl+Space theme picker · Super+Ctrl+Space background picker · click bar clock = calendar.

## Theme System

`nirarchy-theme-set <name>` reads `~/.local/share/nirarchy/themes/<name>/colors.toml`
(Tokyo Night default; also catppuccin, everforest, rose-pine, gruvbox, nord, kanagawa,
osaka-jade) and regenerates: quickshell palette (live, ~1.5s), foot `[colors-dark]`
(running terminals hot-reload), niri border gradient (sentinel block, hot-reloads),
walker CSS (+restart), mako colors (+reload), swayosd CSS (+restart), hyprlock vars,
and swaps the wallpaper from the theme's `backgrounds/`. Tokyo-night keeps the signature
cyan→green border; other themes derive from their accent.

## Conventions

- Bar/popup styling is square (radius 0) — keep it that way.
- The bar is a systemd user unit: `nirarchy-bar.service` (Restart=always). Toggle with
  `nirarchy-toggle-bar`, never by killing quickshell directly.
- Elephant must restart with the session (it holds NIRI_SOCKET); its unit has
  `PartOf=graphical-session.target`.
- New bar features are QML files in `~/.config/quickshell/niri/` (flat directory; types
  resolve per-directory). Popups use `PopupWindow` with `anchor.window` + `anchor.rect`.
  `grabFocus: true` makes niri dismiss popups — use `false`.

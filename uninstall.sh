#!/bin/bash
# Nirarchy uninstaller — removes configs, scripts, data and user services.
# System packages are NOT removed (they may be used by other setups).

set -uo pipefail

say() { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }

read -rp "Remove Nirarchy configs, scripts and data? [y/N] " a
[[ ${a,,} == y ]] || exit 0

say "Stopping and disabling user services"
systemctl --user disable --now nirarchy-bar.service 2>/dev/null
systemctl --user disable --now nirarchy-crash-watch.service 2>/dev/null
systemctl --user daemon-reload

say "Removing files"
rm -rf "$HOME/.config/quickshell/niri" \
  "$HOME/.config/systemd/user/nirarchy-bar.service" \
  "$HOME/.config/systemd/user/nirarchy-crash-watch.service" \
  "$HOME/.config/systemd/user/graphical-session.target.wants/nirarchy-bar.service" \
  "$HOME/.config/systemd/user/graphical-session.target.wants/nirarchy-crash-watch.service" \
  "$HOME/.config/opencode/skills/nirarchy" \
  "$HOME/.config/opencode/skills/diagnose-crash" \
  "$HOME/.local/bin/nirarchy-"* \
  "$HOME/.local/share/nirarchy" \
  "$HOME/.local/share/fonts/nirarchy.ttf" \
  "$HOME/.local/share/fonts/Doto-ExtraBold.ttf" \
  "$HOME/.local/share/nirarchy/nirarchy-menu-icon.png" \
  "$HOME/.cache/nirarchy" \
  "$HOME/.local/state/nirarchy" \
  "$HOME/.config/niri/config.kdl" \
  "$HOME/.config/hypr/hyprlock.conf" \
  "$HOME/.config/hypr/hypridle.conf" \
  "$HOME/.config/foot/foot.ini" \
  "$HOME/.config/swayosd" \
  "$HOME/.config/xdg-terminal-exec" \
  "$HOME/.config/elephant" \
  "$HOME/.config/walker/config.toml" \
  "$HOME/.config/mako/config" \
  "$HOME/.local/share/applications/io.github.nirimod.desktop" \
  "$HOME/.local/bin/nirimod"

say "Removing SDDM theme (requires sudo)"
sudo rm -rf /usr/share/sddm/themes/nirarchy
sudo rm -f /etc/sddm.conf.d/nirarchy.conf

say "Nirarchy removed."
echo "Note: system packages (niri, quickshell, walker, ...) were left installed."
echo "Your pre-Nirarchy configs were backed up as *.bak.<timestamp> during install."

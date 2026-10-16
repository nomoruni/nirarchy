#!/bin/bash
# ============================================================================
#  Nirarchy uninstaller
#
#  Removes everything install.sh set up: niri/quickshell user services,
#  configs, scripts, data, fonts, the SDDM theme, sudoers helper rules,
#  the NetworkManager wifi-backend override, and the niriarchy-only packages.
#
#  Tuned for switching to Plasma: the wifi backend is reverted to
#  wpa_supplicant and GTK is reset to Breeze. tlp (power management) and all
#  shared/general packages are left installed.
#
#  Safe to re-run.
#  Usage:  bash uninstall.sh [--yes] [--no-pkg]
#          --yes      don't ask for confirmation
#          --no-pkg   don't remove any packages
# ============================================================================

set -uo pipefail

ASSUME_YES=false
NO_PKG=false
for arg in "$@"; do
  case "$arg" in
  --yes | -y) ASSUME_YES=true ;;
  --no-pkg) NO_PKG=true ;;
  *)
    echo "Unknown option: $arg" >&2
    exit 1
    ;;
  esac
done

say() { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
ok() { printf '\033[1;32m  ✓ %s\033[0m\n' "$*"; }
note() { printf '\033[1;33m  ! %s\033[0m\n' "$*"; }

if [[ $EUID -eq 0 ]]; then
  echo "Error: run as your normal user (sudo is invoked only where needed)." >&2
  exit 1
fi

cat <<'EOF'
This will uninstall Nirarchy:
  • stop & remove the nirarchy user services (bar, crash-watch, elephant)
  • remove niri/quickshell configs, scripts, data, fonts and the SDDM theme
  • remove the nirarchy sudoers helper rules
  • revert the NetworkManager wifi backend to wpa_supplicant
  • reset GTK3/GTK4 to Breeze (Plasma default)
  • remove nirarchy-only packages (niri, quickshell-git, walker, elephant, ...)

Kept on purpose:
  • tlp / tlp-pd (power management)
  • shared packages (NetworkManager, bluez, foot, fonts, btop, fzf, ...)
  • your ~/.local/bin PATH entry (standard user bin dir)
EOF

if ! $ASSUME_YES; then
  read -rp $'\nProceed with uninstall? [y/N] ' a
  [[ ${a,,} == y ]] || exit 0
fi

# ----------------------------------------------------------------------------
say "Stopping and disabling user services"
systemctl --user disable --now nirarchy-bar.service 2>/dev/null || true
systemctl --user disable --now nirarchy-crash-watch.service 2>/dev/null || true
systemctl --user disable --now elephant.service 2>/dev/null || true
systemctl --user daemon-reload
ok "user services stopped"

# ----------------------------------------------------------------------------
say "Removing nirarchy files"
rm -rf \
  "$HOME/.config/quickshell/niri" \
  "$HOME/.config/systemd/user/nirarchy-bar.service" \
  "$HOME/.config/systemd/user/nirarchy-crash-watch.service" \
  "$HOME/.config/systemd/user/elephant.service" \
  "$HOME/.config/systemd/user/elephant.service.d" \
  "$HOME/.config/systemd/user/graphical-session.target.wants/nirarchy-bar.service" \
  "$HOME/.config/systemd/user/graphical-session.target.wants/nirarchy-crash-watch.service" \
  "$HOME/.config/systemd/user/graphical-session.target.wants/elephant.service" \
  "$HOME/.config/opencode/skills/nirarchy" \
  "$HOME/.config/opencode/skills/diagnose-crash" \
  "$HOME/.local/bin/nirarchy-"* \
  "$HOME/.local/bin/nirimod" \
  "$HOME/.local/share/applications/io.github.nirimod.desktop" \
  "$HOME/.local/share/nirarchy" \
  "$HOME/.local/share/fonts/nirarchy.ttf" \
  "$HOME/.local/share/fonts/Doto-ExtraBold.ttf" \
  "$HOME/.cache/nirarchy" \
  "$HOME/.local/state/nirarchy" \
  "$HOME/.config/niri/config.kdl" \
  "$HOME/.config/hypr/hyprlock.conf" \
  "$HOME/.config/hypr/hypridle.conf" \
  "$HOME/.config/foot/foot.ini" \
  "$HOME/.config/xdg-desktop-portal/niri-portals.conf" \
  "$HOME/.config/swayosd" \
  "$HOME/.config/xdg-terminal-exec" \
  "$HOME/.config/elephant" \
  "$HOME/.config/walker/config.toml" \
  "$HOME/.config/mako/config"
systemctl --user daemon-reload

# Remove now-empty nirarchy-only directories (best effort)
rmdir "$HOME/.config/quickshell" "$HOME/.config/niri" "$HOME/.config/hypr" \
  "$HOME/.config/foot" "$HOME/.config/walker" "$HOME/.config/mako" \
  "$HOME/.config/xdg-terminal-exec" "$HOME/.config/elephant" \
  "$HOME/.config/xdg-desktop-portal" 2>/dev/null || true

# Reset Papirus folder color to the default
papirus-folders -t Papirus -D -u 2>/dev/null || true
ok "files removed"

# ----------------------------------------------------------------------------
say "Resetting GTK3/GTK4 to Breeze (Plasma default)"
for ini in "$HOME/.config/gtk-3.0/settings.ini" "$HOME/.config/gtk-4.0/settings.ini"; do
  [[ -f $ini ]] || continue
  sed -i \
    -e 's/^gtk-theme-name=.*/gtk-theme-name=Breeze/' \
    -e 's/^gtk-icon-theme-name=.*/gtk-icon-theme-name=Breeze/' \
    -e 's/^gtk-cursor-theme-name=.*/gtk-cursor-theme-name=Breeze/' "$ini"
done
ok "GTK reset to Breeze"

# ----------------------------------------------------------------------------
say "Reverting NetworkManager wifi backend to wpa_supplicant (needs sudo)"
sudo systemctl enable --now wpa_supplicant.service 2>/dev/null || true
sudo rm -f /etc/NetworkManager/conf.d/wifi-backend.conf
sudo systemctl restart NetworkManager 2>/dev/null || true
sudo systemctl disable --now iwd.service 2>/dev/null || true
ok "wifi backend reverted to wpa_supplicant"

# ----------------------------------------------------------------------------
say "Removing SDDM theme and sudoers helper rules (needs sudo)"
sudo rm -rf /usr/share/sddm/themes/nirarchy
sudo rm -f /etc/sddm.conf.d/nirarchy.conf
sudo rm -f /usr/local/bin/nirarchy-sddm-apply /etc/sudoers.d/nirarchy-sddm
sudo rm -f /etc/sudoers.d/ufw
ok "SDDM theme + nirarchy sudoers rules removed"
note "SDDM falls back to your default session (Breeze / Plasma)."

# ----------------------------------------------------------------------------
if ! $NO_PKG; then
  say "Removing nirarchy-only packages"

  # Compositor / bar / niri-stack tooling — replaced by Plasma + its own apps.
  # AUR packages live in the local pacman db too, so one list is enough.
  NIR_PKGS=(
    niri quickshell quickshell-git mako hyprlock hypridle swaybg swayosd
    hyprpicker impala bluetui
    walker elephant xdg-terminal-exec
    elephant-desktopapplications elephant-clipboard elephant-symbols
    elephant-calc elephant-menus elephant-files
    xcursor-simp1e gtk-theme-arc-gruvbox-git
  )

  mapfile -t to_remove < <(pacman -Qq -- "${NIR_PKGS[@]}" 2>/dev/null | sort -u)
  if ((${#to_remove[@]})); then
    if sudo pacman -Rns --noconfirm -- "${to_remove[@]}"; then
      ok "removed: ${to_remove[*]}"
    else
      note "some packages are in use and were skipped"
    fi
  else
    ok "no nirarchy-only packages installed"
  fi
else
  say "Skipping package removal (--no-pkg)"
fi

# ----------------------------------------------------------------------------
say "Refreshing font cache"
fc-cache -f >/dev/null 2>&1 || true
ok "font cache"

# ----------------------------------------------------------------------------
say "Nirarchy removed."
cat <<'EOF'

  Kept on purpose:
    • tlp / tlp-pd (power management)
    • shared packages (NetworkManager, bluez, foot, fonts, btop, fzf, ...)

  Your pre-Nirarchy configs were backed up as *.bak.<timestamp> during install.

  Next step: log out and pick "Plasma" (Wayland) in SDDM.
EOF

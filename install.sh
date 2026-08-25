#!/bin/bash
# ============================================================================
#  Nirarchy — Omarchy experience on the Niri compositor
#  https://github.com/YOUR-USERNAME/nirarchy
#
#  Fresh-arch installer: packages, configs, services, themes.
#  Idempotent — safe to re-run. Existing configs are backed up.
#
#  Usage:  bash install.sh [--no-pkg] [--no-services]
#          --no-pkg       skip package installation (testing / partial runs)
#          --no-services  skip systemd service enablement
# ============================================================================

set -euo pipefail

NO_PKG=false
NO_SERVICES=false
for arg in "$@"; do
  case "$arg" in
  --no-pkg) NO_PKG=true ;;
  --no-services) NO_SERVICES=true ;;
  *) echo "Unknown option: $arg"; exit 1 ;;
  esac
done

# Resolve repo root (directory containing this script)
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ ! -d $REPO_DIR/bin || ! -d $REPO_DIR/config ]]; then
  echo "Error: run this script from the nirarchy repo root." >&2
  exit 1
fi

if [[ $EUID -eq 0 ]]; then
  echo "Error: run as your normal user (sudo is invoked only where needed)." >&2
  exit 1
fi

say() { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
ok() { printf '\033[1;32m  ✓ %s\033[0m\n' "$*"; }

# ----------------------------------------------------------------------------
say "Checking distribution"
if [[ ! -f /etc/arch-release ]]; then
  echo "Error: Nirarchy targets Arch Linux (or Arch-based distros at your own risk)." >&2
  exit 1
fi
ok "Arch Linux"

# ----------------------------------------------------------------------------
if ! $NO_PKG; then
  say "Installing repo packages (pacman)"
  sudo pacman -S --needed --noconfirm \
    niri quickshell \
    mako hyprlock hypridle swaybg swayosd \
    grim slurp satty wl-clipboard cliphist brightnessctl \
    pamixer pavucontrol playerctl \
    polkit-gnome tlp tlp-pd \
    foot ttf-jetbrains-mono-nerd ttf-liberation noto-fonts noto-fonts-emoji \
    hyprpicker impala bluetui btop eza fzf ripgrep fd bat zoxide starship fastfetch gum jq \
    xdg-desktop-portal-gtk xdg-desktop-portal-gnome \
    gpu-screen-recorder gammastep wiremix \
    tesseract tesseract-data-eng \
    networkmanager iwd bluez bluez-utils libqalculate \
    xwayland-satellite inxi expac
  ok "repo packages"

  say "Installing AUR packages (yay)"
  if ! command -v yay >/dev/null 2>&1; then
    say "yay not found — building it from source"
    sudo pacman -S --needed --noconfirm git base-devel go
    git clone https://aur.archlinux.org/yay.git /tmp/yay-build
    (cd /tmp/yay-build && makepkg -si --noconfirm)
    rm -rf /tmp/yay-build
  fi
  yay -S --needed --noconfirm \
    walker elephant xdg-terminal-exec \
    elephant-desktopapplications elephant-clipboard elephant-symbols \
    elephant-calc elephant-menus elephant-files
  ok "AUR packages"
else
  say "Skipping package installation (--no-pkg)"
fi

# ----------------------------------------------------------------------------
say "Deploying configs (existing files are backed up to *.bak.<timestamp>)"
STAMP=$(date +%s)
backup() {
  if [[ -e $1 && ! -L $1 ]]; then
    mv "$1" "$1.bak.$STAMP"
  fi
}

mkdir -p "$HOME/.config"

# niri
backup "$HOME/.config/niri"
mkdir -p "$HOME/.config/niri"
cp "$REPO_DIR/config/niri/config.kdl" "$HOME/.config/niri/config.kdl"

# quickshell shell
backup "$HOME/.config/quickshell/niri"
mkdir -p "$HOME/.config/quickshell/niri"
cp "$REPO_DIR/config/quickshell/niri/"*.qml "$HOME/.config/quickshell/niri/"

# hypr (lock/idle only — does not touch a real Hyprland install)
mkdir -p "$HOME/.config/hypr"
cp "$REPO_DIR/config/hypr/hyprlock.conf" "$HOME/.config/hypr/hyprlock.conf"
cp "$REPO_DIR/config/hypr/hypridle.conf" "$HOME/.config/hypr/hypridle.conf"

# foot
mkdir -p "$HOME/.config/foot"
cp "$REPO_DIR/config/foot/foot.ini" "$HOME/.config/foot/foot.ini"

# swayosd
mkdir -p "$HOME/.config/swayosd"
cp "$REPO_DIR/config/swayosd/style.css" "$HOME/.config/swayosd/style.css"

# walker
mkdir -p "$HOME/.config/walker"
cp "$REPO_DIR/config/walker/config.toml" "$HOME/.config/walker/config.toml"

# elephant
mkdir -p "$HOME/.config/elephant/menus"
cp "$REPO_DIR/config/elephant/"*.toml "$HOME/.config/elephant/" 2>/dev/null || true
cp "$REPO_DIR/config/elephant/menus/"*.lua "$HOME/.config/elephant/menus/" 2>/dev/null || true

# xdg-terminal-exec
mkdir -p "$HOME/.config/xdg-terminal-exec"
cp "$REPO_DIR/config/xdg-terminal-exec/config" "$HOME/.config/xdg-terminal-exec/config"

# systemd user units
mkdir -p "$HOME/.config/systemd/user"
cp "$REPO_DIR/config/systemd/user/"*.service "$HOME/.config/systemd/user/"
ok "configs"

# ----------------------------------------------------------------------------
say "Deploying scripts and data"
mkdir -p "$HOME/.local/bin" "$HOME/.local/share/nirarchy"
cp "$REPO_DIR/bin/"nirarchy-* "$HOME/.local/bin/"
chmod +x "$HOME/.local/bin/"nirarchy-*

mkdir -p "$HOME/.local/share/nirarchy/default/mako" \
  "$HOME/.local/share/nirarchy/default/walker/themes/omarchy-default" \
  "$HOME/.local/share/nirarchy/default/swayosd" \
  "$HOME/.local/share/nirarchy/etc/NetworkManager/conf.d" \
  "$HOME/.local/share/nirarchy/themes" \
  "$HOME/.local/share/fonts" \
  "$HOME/.local/state/nirarchy" \
  "$HOME/.cache/nirarchy"

cp "$REPO_DIR/data/default/mako/core.ini" "$HOME/.local/share/nirarchy/default/mako/"
cp "$REPO_DIR/data/default/walker/layout.xml" "$REPO_DIR/data/default/walker/style.css" \
  "$HOME/.local/share/nirarchy/default/walker/"
cp "$REPO_DIR/data/default/walker/themes/omarchy-default/"* \
  "$HOME/.local/share/nirarchy/default/walker/themes/omarchy-default/"
cp "$REPO_DIR/data/default/swayosd/config.toml" "$HOME/.local/share/nirarchy/default/swayosd/"
cp "$REPO_DIR/data/etc/NetworkManager/conf.d/wifi-backend.conf" \
  "$HOME/.local/share/nirarchy/etc/NetworkManager/conf.d/"
cp "$REPO_DIR/data/fonts/omarchy.ttf" "$HOME/.local/share/fonts/"

# Themes (colors, previews, wallpapers)
cp -r "$REPO_DIR/data/themes/." "$HOME/.local/share/nirarchy/themes/"
ok "scripts and data"

# opencode skills (only if opencode config exists or user opts in by presence of dir)
if [[ -d $HOME/.config/opencode ]]; then
  mkdir -p "$HOME/.config/opencode/skills"
  cp -r "$REPO_DIR/config/opencode/skills/nirarchy" "$HOME/.config/opencode/skills/" 2>/dev/null || true
  cp -r "$REPO_DIR/config/opencode/skills/diagnose-crash" "$HOME/.config/opencode/skills/" 2>/dev/null || true
  ok "opencode skills installed"
fi

# ----------------------------------------------------------------------------
say "Refreshing fonts"
fc-cache -f >/dev/null 2>&1 || true
ok "font cache"

# ----------------------------------------------------------------------------
if ! $NO_SERVICES; then
  say "Enabling system services"
  sudo systemctl enable --now NetworkManager 2>/dev/null || true
  systemctl enable --now bluetooth.service 2>/dev/null || true
  systemctl enable --now tlp.service 2>/dev/null || true
  systemctl enable --now tlp-pd.service 2>/dev/null || true
  systemctl disable --now power-profiles-daemon.service 2>/dev/null || true

  # iwd as NetworkManager's wifi backend (needed for impala)
  if ! grep -q 'wifi.backend' /etc/NetworkManager/conf.d/wifi-backend.conf 2>/dev/null; then
    sudo mkdir -p /etc/NetworkManager/conf.d
    sudo cp "$HOME/.local/share/nirarchy/etc/NetworkManager/conf.d/wifi-backend.conf" /etc/NetworkManager/conf.d/
    sudo systemctl disable --now wpa_supplicant.service 2>/dev/null || true
    sudo systemctl enable --now iwd.service 2>/dev/null || true
    sudo systemctl restart NetworkManager
  fi
  ok "system services"

  say "Enabling user services"
  systemctl --user daemon-reload
  # elephant: restart with every graphical session (holds NIRI_SOCKET)
  if systemctl --user list-unit-files | grep -q '^elephant.service'; then
    systemctl --user enable elephant.service 2>/dev/null || true
    mkdir -p "$HOME/.config/systemd/user/elephant.service.d"
    cat >"$HOME/.config/systemd/user/elephant.service.d/override.conf" <<'EOF'
[Unit]
PartOf=graphical-session.target
EOF
  fi
  systemctl --user enable --now nirarchy-bar.service 2>/dev/null || true
  systemctl --user enable --now nirarchy-crash-watch.service 2>/dev/null || true
  ok "user services"
else
  say "Skipping services (--no-services)"
fi

# ----------------------------------------------------------------------------
say "Ensuring ~/.local/bin is on PATH"
if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
  if command -v fish >/dev/null 2>&1; then
    if [[ ! $(fish -c 'echo $fish_user_paths' 2>/dev/null) =~ \.local/bin ]]; then
      fish -c 'set -U fish_user_paths $HOME/.local/bin $fish_user_paths' 2>/dev/null || true
    fi
  fi
  for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [[ -f $rc ]] && ! grep -q '.local/bin' "$rc"; then
      printf '\nexport PATH="$HOME/.local/bin:$PATH"\n' >>"$rc"
    fi
  done
fi
ok "PATH"

# ----------------------------------------------------------------------------
say "Applying default theme (tokyo-night)"
"$HOME/.local/bin/nirarchy-theme-set" tokyo-night || true
ok "theme applied"

rm -f "$HOME/.cache/nirarchy/firstrun"

cat <<'EOF'

  ✅  Nirarchy installed.

  Next steps:
    1. Log out.
    2. Pick "niri" in your display manager and log in.
    3. A welcome notification will show the essential keybinds:
       Super + Alt + Space  -> Nirarchy menu
       Super + Space        -> App launcher
       Super + Shift + K    -> keybinding cheat sheet
       Super + Shift + A    -> opencode AI agent

  Troubleshooting:  journalctl --user -u nirarchy-bar
  Debug report:     nirarchy-debug --print   (or --opencode)
EOF

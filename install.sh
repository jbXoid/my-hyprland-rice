#!/usr/bin/env bash
set -euo pipefail

# ─── Helper: check if running on Arch ─────────────────────
if ! command -v pacman &>/dev/null; then
    echo "This script is meant for Arch-based systems (pacman required)."
    exit 1
fi

# ─── 1. Ensure yay is available ──────────────────────────
if ! command -v yay &>/dev/null; then
    echo "yay not found. Installing yay-bin from AUR..."
    sudo pacman -S --needed --noconfirm git base-devel
    git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin
    cd /tmp/yay-bin
    makepkg -si --noconfirm
    cd -
    rm -rf /tmp/yay-bin
    echo "yay installed successfully."
fi

# ─── 2. Install required packages ────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PKGFILE="$SCRIPT_DIR/pkglist.txt"

if [ -f "$PKGFILE" ]; then
    echo "Installing packages from pkglist.txt..."
    mapfile -t packages < "$PKGFILE"
    yay -S --needed --noconfirm "${packages[@]}"
else
    echo "No pkglist.txt found – skipping package installation."
fi

# ─── 3. Symlink dotfiles ─────────────────────────────────
echo "Symlinking dotfiles..."
DOTFILES_DIR="$SCRIPT_DIR/dotfiles"

if [ -d "$DOTFILES_DIR" ]; then
    find "$DOTFILES_DIR" -type f | while read -r src; do
        rel="${src#$DOTFILES_DIR/}"
        dest="$HOME/$rel"
        mkdir -p "$(dirname "$dest")"

        # Backup existing non-symlink files
        if [ -e "$dest" ] && [ ! -L "$dest" ]; then
            echo "Backing up $dest → ${dest}.bak"
            mv "$dest" "${dest}.bak"
        fi

        ln -sfn "$src" "$dest"
    done
else
    echo "No dotfiles/ directory found – skipping dotfiles setup."
fi

# ─── 4. Place wallpapers ─────────────────────────────────
WALLPAPER_SRC="$SCRIPT_DIR/wallpapers"
WALLPAPER_DEST="$HOME/wallpapers"

if [ -d "$WALLPAPER_SRC" ]; then
    echo "Linking wallpapers into $WALLPAPER_DEST"
    if [ -e "$WALLPAPER_DEST" ] && [ ! -L "$WALLPAPER_DEST" ]; then
        echo "Backing up existing $WALLPAPER_DEST → ${WALLPAPER_DEST}.bak"
        mv "$WALLPAPER_DEST" "${WALLPAPER_DEST}.bak"
    fi
    ln -sfn "$WALLPAPER_SRC" "$WALLPAPER_DEST"
else
    echo "No wallpapers/ directory found – skipping wallpaper symlink."
fi

# ─── 5. Enable ly display manager ───────────────────────
echo "Enabling ly display manager..."
sudo systemctl enable ly@tty1.service
sudo systemctl set-default graphical.target

echo "All done! Reboot to see what i've done"

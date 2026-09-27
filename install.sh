#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DOTFILES_DIR="$SCRIPT_DIR/dotfiles"
WALLPAPERS_DIR="$SCRIPT_DIR/wallpapers"
PKGLIST="$SCRIPT_DIR/pkglist.txt"

CONFIG_DIR="$HOME/.config"
WALLPAPER_TARGET="$HOME/wallpapers"

echo "==> Installing packages..."

if ! command -v yay >/dev/null 2>&1; then
    echo "Error: yay is not installed."
    exit 1
fi

# Install only missing packages
while IFS= read -r pkg; do
    [[ -z $pkg || $pkg =~ ^# ]] && continue

    if ! pacman -Qi $pkg >/dev/null 2>&1; then
        echo "Installing $pkg..."
        yay -S --noconfirm $pkg
    else
        echo "$pkg already installed"
    fi
done < "$PKGLIST"


echo "==> Installing Oh-My-Zsh and Powerlevel10k theme..."

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"

sed -i 's|^ZSH_THEME=.*|ZSH_THEME="powerlevel10k/powerlevel10k"|' ~/.zshrc

echo "==> Creating config symlinks..."

mkdir -p "$CONFIG_DIR"

for dir in "$DOTFILES_DIR"/*; do
    [[ -d "$dir" ]] || continue

    name="$(basename "$dir")"
    target="$CONFIG_DIR/$name"

    if [[ -L "$target" || -e "$target" ]]; then
        echo "Removing existing $target"
        rm -rf "$target"
    fi

    ln -s "$dir" "$target"
    echo "Linked $name"
done

echo "==> Linking wallpapers..."

mkdir -p "$(dirname "$WALLPAPER_TARGET")"

if [[ -L "$WALLPAPER_TARGET" || -e "$WALLPAPER_TARGET" ]]; then
    rm -rf "$WALLPAPER_TARGET"
fi

ln -s "$WALLPAPERS_DIR" "$WALLPAPER_TARGET"

echo "==> Setup sounds..."
./sounds/setup-system-sounds.sh


echo "==> Done!"

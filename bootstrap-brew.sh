#!/usr/bin/env bash
# Non-Nix setup for Macs where Nix can't be installed (e.g. an MDM profile
# blocks the Nix Store volume). Re-run any time; every step is idempotent.
# Unlike the Nix setup, this never removes packages that aren't in the Brewfile.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

echo "==> Step 1: Homebrew"
if ! command -v brew >/dev/null 2>&1; then
  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  else
    echo "    Homebrew not found. Install it from https://brew.sh and re-run."
    exit 1
  fi
fi

echo "==> Step 2: brew bundle"
brew bundle --file "$DIR/Brewfile"

echo "==> Step 3: symlink this repo to ~/.dotfiles"
ln -sfn "$DIR" ~/.dotfiles

echo "==> Step 4: link config files (mirrors home.nix)"
link() {
  local src="$HOME/.dotfiles/$1" dest="$HOME/$2"
  mkdir -p "$(dirname "$dest")"
  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    echo "    backing up existing $dest to $dest.bak"
    mv "$dest" "$dest.bak"
  fi
  ln -sfn "$src" "$dest"
  echo "    $2 -> $1"
}
link home/.zshrc .zshrc
link home/.config/starship.toml .config/starship.toml
link home/.config/wezterm .config/wezterm
link home/.config/nvim .config/nvim
link home/.config/herdr .config/herdr
link home/.claude/settings.json .claude/settings.json
link home/.pi/agent/themes .pi/agent/themes
link home/.pi/agent/extensions .pi/agent/extensions
link home/.pi/agent/models.json .pi/agent/models.json
link home/.pi/agent/settings.json .pi/agent/settings.json
link home/AGENTS.md .claude/CLAUDE.md
link home/AGENTS.md .codex/AGENTS.md
link home/AGENTS.md .config/opencode/AGENTS.md

echo "==> Step 5: macOS defaults"
"$DIR/macos-defaults.sh"

echo "==> Done. Open a new terminal to pick up the shell config."

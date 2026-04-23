#!/usr/bin/env bash
# Bootstrap a fresh Mac from this dotfiles repo.
#
# Run from anywhere:
#   ~/.dotfiles/fresh.sh
#
# Steps (each idempotent — safe to re-run):
#   1. Install Homebrew (if absent), wire shellenv into ~/.zprofile
#   2. Install oh-my-zsh (if absent), unattended
#   3. Symlink every *.symlink file via installers/bootstrap.sh
#      (creates ~/.zshrc, ~/.gitconfig, ~/.gitconfig.local, ~/.mackup.cfg)
#   4. brew bundle from Brewfile
#   5. Install Python via pyenv (py/install.sh)
#   6. mackup restore (pulls app configs from iCloud)
#   7. Start netdata service (best-effort)
#   8. Apply macOS defaults from .macos (prompts; restarts Dock/Finder/etc.)

set -e

DOTFILES="$HOME/.dotfiles"
cd "$DOTFILES"

echo "==> Bootstrapping from $DOTFILES"

# 1. Homebrew
if ! command -v brew >/dev/null 2>&1; then
  echo "==> Installing Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# 2. oh-my-zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "==> Installing oh-my-zsh (unattended — won't exec into a new shell)"
  RUNZSH=no CHSH=no /bin/sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/HEAD/tools/install.sh)"
fi

# 3. Symlink configs (~/.zshrc → zsh/zshrc.symlink, etc.)
echo "==> Symlinking configs via installers/bootstrap.sh"
"$DOTFILES/installers/bootstrap.sh"

# Make sure the projects dir exists for `cd ~projects` and friends.
mkdir -p "$HOME/Developer/Projects"

# 4. Brew packages
echo "==> Installing brew packages from Brewfile (this may take a while)"
brew update
brew bundle --file "$DOTFILES/Brewfile"

# 5. Python via pyenv
echo "==> Installing Python via pyenv"
"$DOTFILES/py/install.sh"

# 6. Mackup restore
if command -v mackup >/dev/null 2>&1; then
  echo "==> Restoring app configs from iCloud via Mackup"
  mackup restore
fi

# 7. netdata (best-effort — won't fail the script)
brew services start netdata 2>/dev/null || true

# 8. macOS defaults — runs LAST because it restarts apps
echo ""
echo "==> Final step: apply macOS defaults from .macos"
echo "    This will run ~43KB of \`defaults write\` commands and restart Dock,"
echo "    Finder, SystemUIServer, and others. You can skip and run it later"
echo "    manually with:  sh ~/.dotfiles/.macos"
read -p "    Apply now? [y/N] " -r reply
if [[ "$reply" =~ ^[Yy]$ ]]; then
  source "$DOTFILES/.macos"
fi

echo ""
echo "==> Done. Open a new terminal."

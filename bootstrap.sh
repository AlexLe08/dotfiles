#!/usr/bin/env bash
# Symlinks dotfiles into $HOME. Safe to re-run.
# Any existing file is moved to ~/.dotfiles-backup/<timestamp>/ before linking.
#
# Usage:
#   ./bootstrap.sh --dry-run   # show what would happen, change nothing
#   ./bootstrap.sh             # do it

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

run() {
  if $DRY_RUN; then echo "    would run: $*"; else "$@"; fi
}

link() {
  local src="$DOTFILES/$1"
  local dest="$2"

  if [[ ! -e "$src" ]]; then
    echo "MISSING  $src (skipped)"
    return
  fi

  # Already linked correctly: nothing to do.
  if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
    echo "ok       $dest"
    return
  fi

  # Something else is there: back it up. Flatten the path so
  # ~/.ssh/config and ~/.config/ghostty/config don't collide.
  if [[ -e "$dest" || -L "$dest" ]]; then
    local backup_name
    backup_name="$(echo "${dest#"$HOME"/}" | tr '/' '_')"
    echo "backup   $dest -> $BACKUP_DIR/$backup_name"
    run mkdir -p "$BACKUP_DIR"
    run mv "$dest" "$BACKUP_DIR/$backup_name"
  fi

  run mkdir -p "$(dirname "$dest")"
  run ln -s "$src" "$dest"
  if $DRY_RUN; then echo "would link $dest -> $src"; else echo "linked   $dest -> $src"; fi
}

$DRY_RUN && echo "DRY RUN: nothing will be changed."
echo "Linking from $DOTFILES"
echo

# ~/.ssh must be private or ssh refuses to use it.
if [[ ! -d "$HOME/.ssh" ]]; then
  run mkdir -p "$HOME/.ssh"
fi
run chmod 700 "$HOME/.ssh"

link zsh/zprofile          "$HOME/.zprofile"
link zsh/zshrc             "$HOME/.zshrc"
link git/gitconfig         "$HOME/.gitconfig"
link git/gitignore_global  "$HOME/.gitignore_global"
link ssh/config            "$HOME/.ssh/config"
link ghostty/config        "$HOME/.config/ghostty/config"
link mise/config.toml      "$HOME/.config/mise/config.toml"

# Identity file is per-machine and never committed. Create it once.
if [[ ! -f "$HOME/.gitconfig.local" ]]; then
  echo "create   $HOME/.gitconfig.local (from example; EDIT IT)"
  run cp "$DOTFILES/git/gitconfig.local.example" "$HOME/.gitconfig.local"
else
  echo "ok       $HOME/.gitconfig.local (exists, left alone)"
fi

echo
if [[ -d "$BACKUP_DIR" ]] && ! $DRY_RUN; then
  echo "Backups are in $BACKUP_DIR. Diff them against the new files and"
  echo "move anything you still need into ~/.zshrc.local or ~/.zprofile.local."
fi
echo "Open a NEW terminal window to load the new shell config."

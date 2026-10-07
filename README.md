# dotfiles

My macOS development environment: apps, CLI tools, shell, Git, editor, and container config.
Built for web development on Apple Silicon (macOS 26).

Full walkthrough with rationale, per-phase verification, and troubleshooting: [SETUP.md](SETUP.md)

## Quick start (new Mac)

```bash
# 1. Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"

# 2. This repo (HTTPS via gh for now; SSH keys come in step 6)
brew install git gh
gh auth login
gh repo clone AlexLe08/dotfiles ~/dotfiles && cd ~/dotfiles

# 3. Apps and tools (restore Brewfile.local from backup first; it's not in Git)
brew bundle install --no-upgrade --file=Brewfile
brew bundle install --no-upgrade --file=Brewfile.local

# 4. macOS preferences (read it first), then set the screenshot folder by hand:
#    Cmd+Shift+5 > Options > Other Location > ~/Screenshots
./macos.sh

# 5. Symlink configs (preview first), then set identity in ~/.gitconfig.local
./bootstrap.sh --dry-run && ./bootstrap.sh

# 6. SSH key, GitHub, commit signing: SETUP.md, Phase 5

# 7. Runtimes and editor
mise install
xargs -L1 code --install-extension < vscode/extensions.txt

# 8. Containers: SETUP.md, Phase 9 (Colima start flags, SSD mount)
```

## Conventions

- Configs are **symlinked**, so tools that edit their own config edit this repo, and
  apps that edit them show up in `git status`.
- Machine-specific or private settings go in files that are never committed:
  `~/.gitconfig.local`, `~/.zprofile.local`, `~/.zshrc.local`, `~/.ssh/config.local`,
  and `~/dotfiles/Brewfile.local`.
- Homebrew installs system tools; mise installs language toolchains.
- Self-updating apps update themselves; check with `brew bundle check --no-upgrade`.
- Commit by staging files by name and reviewing `git diff --staged`.

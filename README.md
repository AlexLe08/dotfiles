# dotfiles

My macOS development environment: apps, CLI tools, shell, Git, and editor config.
Built for web development on Apple Silicon.

Full walkthrough with rationale and per-phase verification: [SETUP.md](SETUP.md)

## Quick start (new Mac)

```bash
# 1. Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"

# 2. This repo
git clone https://github.com/<you>/dotfiles.git ~/dotfiles && cd ~/dotfiles

# 3. Apps and tools
brew bundle --no-upgrade

# 4. macOS preferences (read it first)
./macos.sh

# 5. Symlink configs (preview first)
./bootstrap.sh --dry-run && ./bootstrap.sh

# 6. Identity: edit ~/.gitconfig.local, then generate an SSH key (SETUP.md, Phase 5)

# 7. Runtimes and editor
mise install
xargs -L1 code --install-extension < vscode/extensions.txt
```

## Conventions

- Configs are **symlinked**, so tools that edit their own config edit this repo.
- Machine-specific or private settings go in `~/.zshrc.local`, `~/.zprofile.local`,
  and `~/.gitconfig.local`. These are never committed.
- After installing something with brew: `brew bundle dump --force`, review, commit.

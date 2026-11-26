# Brewfile: everything this Mac should have installed.
# Install:   brew bundle --no-upgrade --file=~/dotfiles/Brewfile
# Check:     brew bundle check --no-upgrade --verbose --file=~/dotfiles/Brewfile
# Update:    brew bundle dump --force --file=~/dotfiles/Brewfile
# Do NOT run `brew bundle cleanup --force` unless you mean to uninstall
# everything that isn't listed here.

# ---- Core CLI ----
brew "git"                      # newer than Apple's bundled git
brew "gh"                       # GitHub CLI: auth, PRs, issues from the terminal
brew "mise"                     # runtime manager: Node, pnpm, Python, global CLIs
brew "starship"                 # prompt
brew "zsh-autosuggestions"
brew "zsh-syntax-highlighting"
brew "fzf"                      # fuzzy finder; Ctrl+R history search
brew "ripgrep"                  # fast grep (rg)
brew "fd"                       # fast find
brew "jq"                       # JSON on the command line
brew "bat"                      # cat with syntax highlighting
brew "tree"
brew "wget"
brew "tlrc"
brew "age"                      # file encryption (project dependency)
brew "typos-cli"                # spell checker; pre-commit hooks and check scripts run it
brew "gitleaks"                 # secret scanner; pre-commit hooks and check scripts run it

# ---- Containers ----
# Docker Desktop provides the docker CLI, compose, and buildx.
# Colima and OrbStack both work with that CLI via `docker context`.
brew "colima"                   # main engine for real projects (FOSS, no license strings)
cask "docker-desktop"           # learning; free under Docker's personal/small-business terms
cask "orbstack"                 # learning; free for personal, non-commercial use only

# ---- Terminal & editor ----
cask "ghostty"
cask "visual-studio-code"
# cask "cursor"                 # uncomment when you're ready to switch

# ---- Productivity ----
cask "raycast"                  # launcher + window management + clipboard history
cask "rustdesk"                 # remote desktop (open source); updated by brew, not its own updater

# Local LLM runtime for development (free, no API spend). Run on demand: `ollama serve`.
brew "ollama"

# AI coding agent CLI (stable channel; ~1 week behind latest, skips bad releases)
cask "claude-code"

# ---- Browsers ----
cask "google-chrome"
cask "firefox@developer-edition"

# ---- API & database tools ----
cask "bruno"                    # source of truth: collections live in your repos
cask "postman"                  # learning/familiarity; keep real secrets out of synced envs
cask "beekeeper-studio"

# ---- Design & recording ----
cask "figma"
cask "kap"                      # screen recording; demo GIFs for READMEs and PRs
cask "keycastr"                 # shows keystrokes on screen while recording

# ---- Fonts ----
cask "font-jetbrains-mono-nerd-font"

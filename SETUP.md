# Mac Mini Web Development Setup Plan

Revision 2 (October 2026). This version reflects a machine that already has iTerm2, Oh My Zsh, Volta, and VS Code installed, and adds Postman, OrbStack, and Docker Desktop alongside the original recommendations.

## How to use this document

Work through the phases in order. Each phase ends with a **Verify** section. Don't start the next phase until every check passes. Several phases edit the same files (your shell config especially), and a problem caught early is a five-minute fix, while a problem caught three phases later is an archaeology project.

The guiding principle: **everything should be reproducible.** As much as possible lives in the `~/dotfiles` repo (Brewfile, scripts, shell and Git config), so setting up the next Mac is a clone and a few commands, not an afternoon of clicking.

## What's in the dotfiles repo

| Path | Becomes | Purpose |
|---|---|---|
| `Brewfile` | n/a | Every CLI tool and app, installed with one command |
| `bootstrap.sh` | n/a | Symlinks config files into `$HOME`, backing up anything it replaces |
| `macos.sh` | n/a | macOS preferences via `defaults write` |
| `zsh/zprofile` | `~/.zprofile` | Homebrew environment for login shells |
| `zsh/zshrc` | `~/.zshrc` | Completions, history, mise, Starship, fzf, plugins |
| `git/gitconfig` | `~/.gitconfig` | Shared Git behavior |
| `git/gitconfig.local.example` | `~/.gitconfig.local` | Identity and signing (copied, never committed) |
| `git/gitignore_global` | `~/.gitignore_global` | macOS junk ignored in every repo |
| `ssh/config` | `~/.ssh/config` | Loads your GitHub key from Keychain |
| `ghostty/config` | `~/.config/ghostty/config` | Terminal font and behavior |
| `mise/config.toml` | `~/.config/mise/config.toml` | Global Node, pnpm, Python versions |
| `vscode/extensions.txt` | n/a | Editor extensions, installed with one command |

**Why symlinks instead of copies:** when a tool edits its own config (for example `mise use --global`), the change lands in the repo file through the link, so `git status` in `~/dotfiles` shows exactly what changed. Copies drift silently.

**Why a `.local` file pattern:** your identity, machine-specific paths, and anything secret stay in `~/.gitconfig.local`, `~/.zshrc.local`, and `~/.zprofile.local`, which are never committed. That keeps the repo public-safe and lets anyone fork it.

## Decisions at a glance

| Area | Choice | Alternatives considered | Why |
|---|---|---|---|
| Package manager | Homebrew + Brewfile | MacPorts, manual installs | Standard, covers CLI and GUI apps, declarative |
| Terminal | Ghostty (iTerm2 kept during trial) | Terminal.app, iTerm2, Warp | Free, native, fast; Warp wants an account and cloud features |
| Shell | Plain zsh + Starship + 2 plugins | Oh My Zsh, Prezto | Faster startup, you understand every line |
| Runtimes | mise | nvm, fnm, Volta, brew Node | Fast, polyglot (Node + Python), per-project pins; Volta's maintainers point to mise |
| JS package manager | pnpm (pinned per project) | npm, yarn, bun | Fast, disk-efficient, strict about phantom dependencies |
| Editor | VS Code now, Cursor later | Zed, WebStorm | Ecosystem; Cursor imports VS Code setup in one click |
| Git auth & signing | One SSH key for both | HTTPS, GPG, paid SSH agents | Simple, free, "Verified" badge on GitHub |
| API client | Bruno (source of truth) + Postman (learning) | Insomnia | Bruno collections are files in your repo; Postman is industry-familiar |
| Database GUI | Beekeeper Studio | TablePlus, DBeaver | Open source, light, no artificial limits |
| Launcher & windows | Raycast | Spotlight, Alfred, Rectangle | One free app replaces three |
| Containers | Colima (main), Docker Desktop + OrbStack (learning) | n/a | Colima has no license strings for a project seeking users |

---

## Phase 0: Baseline and inventory

### 0a. System Settings (by hand)

These are security-relevant one-time settings, better done in the GUI so you see what you're agreeing to.

- **Software Update:** install pending updates; enable automatic security responses and system files.
- **Privacy & Security > FileVault:** on. Store the recovery key somewhere other than this Mac.
- **Network > Firewall:** on.
- **Keyboard > Keyboard Shortcuts > Modifier Keys:** Caps Lock to Control (or Escape if you use Vim keys).
- **Energy (optional):** "Prevent automatic sleeping when the display is off," useful for long-running local jobs.
- **Time Machine:** back up to an external drive. Uncommitted work and local databases aren't on GitHub.

### 0b. Inventory and backups

You have existing tools, so record the current state before changing anything.

```bash
mkdir -p ~/setup-backup
cp ~/.zshrc ~/.zprofile ~/.gitconfig ~/setup-backup/ 2>/dev/null
ls -la ~/setup-backup

sw_vers                      # macOS version
uname -m                     # should print arm64 on Apple Silicon
echo $SHELL                  # should be /bin/zsh
brew --version               # is Homebrew already installed?
brew list --cask             # apps brew already manages
ls /Applications             # everything installed, brew or not
volta list all               # global Node tools to recreate in mise
git config --global --list   # current Git identity and settings
ls -la ~/.ssh                # existing keys?
```

Save this output somewhere (a note is fine). You'll need the Volta list in Phase 6, and the Applications list tells you which apps need `--adopt` in Phase 2.

### Verify

```bash
fdesetup status                                              # "FileVault is On."
/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate   # "enabled"
ls ~/setup-backup                                            # your backed-up files are there
```

---

## Phase 1: Homebrew

If `brew --version` worked in Phase 0, skip the install and just run `brew update`.

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"
```

Don't add the `shellenv` line to `~/.zprofile` by hand. The dotfiles `zprofile` does it, and bootstrap installs that in Phase 4. The installer also pulls in Xcode Command Line Tools.

### Verify

```bash
brew --version
brew doctor          # "Your system is ready to brew." Warnings are worth reading, not always fatal
xcode-select -p      # prints a path, e.g. /Library/Developer/CommandLineTools
which brew           # /opt/homebrew/bin/brew
```

---

## Phase 2: Dotfiles repo and Brewfile

```bash
# Unzip the dotfiles download into your home folder, then:
cd ~/dotfiles
git init
git add -A && git commit -m "Initial dotfiles"
```

Git may complain about identity on that first commit since bootstrap hasn't run yet. If so, skip the commit; you'll make it in Phase 5.

### Adopt apps you installed manually

`brew bundle` can't install over an app that was dragged into Applications. Adopt those apps instead, so brew takes over updates without touching your settings (settings live in `~/Library`, not inside the `.app`).

```bash
brew bundle check --verbose --file=~/dotfiles/Brewfile   # lists what's missing

# For each app that exists in /Applications but not in `brew list --cask`:
brew install --cask --adopt visual-studio-code
brew install --cask --adopt iterm2
# ...and so on
```

If adopt reports a version mismatch, update the app first, or use `--force` to let brew replace it.

### Install everything else

```bash
brew bundle --no-upgrade --file=~/dotfiles/Brewfile
```

`--no-upgrade` avoids surprise upgrades of tools you already rely on. This installs mise, Starship, and the zsh plugins, but nothing activates them until Phase 4, so your current shell keeps working exactly as before.

Never run `brew bundle cleanup --force` unless you intend to uninstall everything not in the Brewfile.

### Verify

```bash
brew bundle check --file=~/dotfiles/Brewfile   # "The Brewfile's dependencies are satisfied."
mise --version
starship --version
ls /Applications | grep -iE "ghostty|raycast|bruno|postman|beekeeper|orbstack|docker"
```

---

## Phase 3: macOS defaults

```bash
cd ~/dotfiles
less macos.sh        # read it first
chmod +x macos.sh
./macos.sh
```

Then log out and back in.

Two notes. Disabling press-and-hold removes the accent popup (é, ñ); delete that line if you need accents. Hidden files are not shown by default on purpose; toggle them with **Cmd+Shift+.** in Finder.

### Verify

```bash
defaults read NSGlobalDomain AppleShowAllExtensions          # 1
defaults read NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled   # 0
defaults read com.apple.screencapture location               # /Users/<you>/Screenshots
```

Take a screenshot (Cmd+Shift+3); it should land in `~/Screenshots`. Hold down a letter key in any text field; it should repeat quickly.

---

## Phase 4: Shell migration (Volta out, Oh My Zsh out, new config in)

This is the riskiest phase, so: **keep one terminal window open the whole time** as a lifeline, and do every test in a *new* window.

Order matters. Volta and Oh My Zsh both edit shell config, so remove both, then install the new config once.

### 4a. Measure the "before"

```bash
time zsh -i -c exit          # note the "total" number
grep -E '^(plugins|ZSH_THEME)' ~/.zshrc
grep -E '^(alias|export)' ~/.zshrc ~/.zprofile
```

The `plugins=(...)` line matters. The Oh My Zsh `git` plugin provides about 150 aliases (`gst`, `gco`, `gp`...). Write down the few you actually type; you'll add only those back. Copy any custom `export` lines (other than Volta and Oh My Zsh ones) for later.

### 4b. Remove Volta

Volta has no uninstall command.

```bash
brew uninstall volta 2>/dev/null   # only matters if it was a brew install
rm -rf ~/.volta
```

You don't need to hand-edit the `VOLTA_HOME` lines in `.zshrc` / `.zprofile`; bootstrap replaces both files in 4d (and backs up the originals).

Check projects for pinned versions. mise does not read the `"volta"` field in `package.json`:

```bash
grep -rl '"volta"' ~/path/to/your/projects --include=package.json
```

For each match, note the Node version. In Phase 6 you'll add a `mise.toml` or `.node-version` to that project.

### 4c. Remove Oh My Zsh

```bash
uninstall_oh_my_zsh
```

It may restore an old `~/.zshrc.pre-oh-my-zsh`. That's fine; bootstrap backs it up and replaces it next. If you used Powerlevel10k, its config file (`~/.p10k.zsh`) can be deleted; Starship replaces it.

### 4d. Install the new config

```bash
cd ~/dotfiles
chmod +x bootstrap.sh
./bootstrap.sh --dry-run     # read what it WOULD do
./bootstrap.sh               # do it
```

Bootstrap moves anything it replaces into `~/.dotfiles-backup/<timestamp>/`. Diff those backups against the new files and move anything you still need (custom exports, the aliases you wrote down) into `~/.zshrc.local`, or into `zsh/zshrc` itself if it belongs on every machine.

### 4e. Ghostty

Open Ghostty. The dotfiles config already sets the Nerd Font so Starship's icons render. Keep iTerm2 installed for a week or two; your shell config is shared between them. When you're done with iTerm2: export your profile (Settings > Profiles > Other Actions > Save Profile as JSON), then `brew uninstall --cask iterm2`, delete `~/Library/Preferences/com.googlecode.iterm2.plist`, and remove the `iterm2` line from the Brewfile.

### Verify (in a NEW Ghostty window)

```bash
ls -la ~/.zshrc ~/.zprofile ~/.gitconfig     # all point into ~/dotfiles
echo $HOMEBREW_PREFIX                        # /opt/homebrew
ls ~/.oh-my-zsh ~/.volta 2>&1                # both "No such file or directory"
time zsh -i -c exit                          # compare to the "before"
```

Also check by hand: the Starship prompt shows; typing `git ch` then Tab completes; Ctrl+R opens fuzzy history; a gray autosuggestion appears as you type a previous command. mise may warn about missing tools; that's expected until Phase 6.

---

## Phase 5: Git, SSH, GitHub

### Identity

Edit `~/.gitconfig.local` (created by bootstrap). Use your GitHub noreply address (GitHub > Settings > Emails) so your real email isn't in public commit history.

From now on, write identity with `git config --file ~/.gitconfig.local ...`. Plain `git config --global` writes to `~/.gitconfig`, which is now a symlink into your repo.

### SSH key

Skip key generation if Phase 0 showed an existing `id_ed25519` you want to keep.

```bash
ssh-keygen -t ed25519 -C "your-noreply-email"
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
```

### GitHub

```bash
gh auth login                                        # GitHub.com > SSH > choose your key
gh auth refresh -h github.com -s admin:ssh_signing_key
gh ssh-key add ~/.ssh/id_ed25519.pub --type signing
```

Now uncomment the `[commit]` and `[tag]` signing blocks in `~/.gitconfig.local`. Doing this before the key exists makes every commit fail, which is why it's off by default.

On `pull.rebase = true`: rebase-on-pull keeps history linear. If rebase conflicts make you uneasy, change it to `[pull] ff = only`, which refuses to pull when branches diverge and lets you decide.

### Verify

```bash
git config user.email                  # your noreply address
ssh -T git@github.com                  # "Hi <username>! You've successfully authenticated..."
gh auth status
cd ~/dotfiles && git add -A && git commit -m "Initial dotfiles"
git cat-file -p HEAD | grep -c gpgsig  # 1 = the commit is signed
```

Create a private `dotfiles` repo on GitHub (`gh repo create dotfiles --private --source=. --push`), open the commit on GitHub, and look for the "Verified" badge. Make it public later once you've confirmed nothing personal is in it.

---

## Phase 6: Runtimes with mise

The dotfiles already declare Node LTS, pnpm, and Python 3.13 in `mise/config.toml`. Install them:

```bash
mise install
```

### Recreate global tools from Volta

Use the `volta list all` output from Phase 0. Prefer mise's npm backend over `npm i -g`: npm globals are tied to one Node version and vanish when you upgrade Node, while `npm:` tools are pinned independently (Volta's best feature, kept).

```bash
mise use --global npm:typescript     # repeat for each global tool you had
```

These edit `mise/config.toml` through the symlink, so commit them in `~/dotfiles`.

### Migrate Volta-pinned projects

For each project that had a `"volta"` field:

```bash
cd ~/path/to/project
mise use node@20.11.1        # the version Volta had pinned; writes mise.toml
```

Commit that `mise.toml` to the project. Projects with `.nvmrc` or `.node-version` need nothing; the dotfiles config tells mise to read them.

### pnpm per project

Pin the package manager in each project's `package.json` with the `packageManager` field (e.g. `"packageManager": "pnpm@10.x.x"`), so every contributor uses the same version. Stay comfortable with npm too; most docs use it.

**Rule going forward:** never `sudo npm install -g`.

### Verify

```bash
mise doctor          # no errors
mise ls              # node, pnpm, python marked active
which node           # a path under ~/.local/share/mise, NOT .volta
node -v && pnpm -v && python --version
tsc -v               # (or whichever globals you recreated)
```

Then `cd` into a Volta-pinned project and confirm `node -v` matches its pinned version.

---

## Phase 7: Editor

```bash
xargs -L1 code --install-extension < ~/dotfiles/vscode/extensions.txt
```

Sign in to Settings Sync (Accounts icon, bottom left) with GitHub. Skip the Tailwind extension if you don't use Tailwind.

Lint and format **rules** belong in each project's repo (`eslint.config.js`, `.prettierrc`, `.editorconfig`), not in editor settings. The editor only reads them. That's what makes switching to Cursor painless later.

**Cursor, later:** uncomment `cask "cursor"` in the Brewfile and run `brew bundle`. On first launch it imports your VS Code extensions and settings. It uses the Open VSX registry, so a few Microsoft-owned extensions aren't available; everything here is fine. When it becomes your daily editor, change `core.editor` in `git/gitconfig` to `cursor --wait`.

**Optional AI completion:** GitHub Copilot's free tier needs only a GitHub account.

### Verify

```bash
code --list-extensions       # matches extensions.txt
git config core.editor       # code --wait
```

Run `git commit` with no `-m` in a test repo; VS Code should open the message, and closing the tab should complete the commit.

---

## Phase 8: Browsers and tools

- **Chrome:** primary DevTools, and what most users run.
- **Firefox Developer Edition:** best CSS Grid and Flexbox inspectors; your second engine.
- **Safari:** Settings > Advanced > "Show features for web developers." Every iOS browser is WebKit, so Safari testing is mobile testing.
- **Bruno:** source of truth for API requests. Store collections inside each project repo.
- **Postman:** for learning and familiarity. It needs a free account and syncs to the cloud by default, so **never put real API keys or tokens in shared environment values**; use Postman's Vault or keep secrets in Bruno and `.env`. Bruno can import Postman collections.
- **Beekeeper Studio:** database GUI for Postgres, MySQL, SQLite.
- **Raycast:** set it as the Cmd+Space launcher (disable Spotlight's shortcut in System Settings > Keyboard > Keyboard Shortcuts > Spotlight first). Under Extensions > Window Management, bind snapping shortcuts you'll remember. Enable Clipboard History.

### Verify

Open each app once and get past its first-run screens. In Safari, confirm the Develop menu appears. In Raycast, confirm Cmd+Space opens it and a window-snap shortcut works.

---

## Phase 9: Containers

All three engines can coexist. The key concept: **`docker` is only a client.** Docker Desktop, OrbStack, and Colima are three separate engines, each in its own VM. The CLI picks one through **contexts**. Docker Desktop provides the CLI, Compose, and Buildx, and all three engines use it.

```bash
# Colima first, since it's your main engine
colima start --cpu 4 --memory 4 --vm-type vz
docker context use colima
docker run --rm hello-world
```

Then open Docker Desktop and OrbStack once each to finish their setup. In both, **turn off "start at login"**.

Gotchas, in order of how likely they are to confuse you:

1. **Separate data.** Images, containers, and volumes don't cross engines. An "empty" database usually means the wrong context. Check `docker context show` first.
2. **Port collisions.** Two engines can't both bind 5432. Run one at a time.
3. **RAM.** Each VM reserves memory. Quit engines you aren't using: `colima stop`, and quit the Docker Desktop / OrbStack apps.
4. **Licensing.** OrbStack is free for personal learning only. Keep your real project's README on Colima (or Docker Desktop under its free terms) so contributors never hit a license wall.

### Verify

```bash
docker context ls                     # colima, desktop-linux, orbstack all listed
docker context use colima && docker run --rm hello-world
docker compose version
colima stop
```

Then, with only that engine running, repeat `docker context use <name> && docker run --rm hello-world` for `orbstack` and `desktop-linux`.

---

## Phase 10: Final check and push

```bash
brew doctor
brew bundle check --file=~/dotfiles/Brewfile
mise doctor
ssh -T git@github.com
docker context show
cd ~/dotfiles && git status            # clean, or commit what changed
git push
```

### Keeping it current

- Installed something new with brew? `brew bundle dump --force --file=~/dotfiles/Brewfile`, review the diff, commit.
- Changed a global runtime? `mise use --global ...` already edited the repo; commit.
- New Mac? Install Homebrew, clone `~/dotfiles`, then `brew bundle`, `./macos.sh`, `./bootstrap.sh`, create `~/.gitconfig.local`, and generate an SSH key.

### Rollback

- Shell broken: `rm ~/.zshrc && cp ~/setup-backup/.zshrc ~/.zshrc`, or restore from `~/.dotfiles-backup/<timestamp>/`. Always `rm` the symlink first: copying onto a symlink writes *through* it and overwrites the file in your repo.
- A macOS default you dislike: `defaults delete <domain> <key>` restores the system default, e.g. `defaults delete com.apple.dock autohide`, then `killall Dock`.

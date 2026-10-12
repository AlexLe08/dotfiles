# Mac Development Setup

Revision 3 (October 2026). Rewritten after a full phase-by-phase setup of a Mac mini (macOS 26, Apple Silicon), so every step here has actually been run, and every gotcha below was actually hit.

This document has two jobs:

1. **Rebuild a Mac from scratch** with this repo, in order, with a check after each phase.
2. **Record why things are the way they are**, so future-you doesn't undo a decision without knowing what it was protecting against.

## Principles

- **Reproducible.** Apps, tools, and config live in this repo. Setting up a new Mac is a clone and a handful of commands, not an afternoon of clicking.
- **Symlinked configs.** Files in `$HOME` are links into this repo. When a tool (or a third-party app) edits its config, the change shows up in `git status`. That visibility caught three apps editing these files during the original setup.
- **`.local` files for anything machine-specific or private.** Never committed (`.gitignore` has `*.local`). Keeps the repo safe to make public.
- **Verify every phase before starting the next.** A problem found right away is a minute's fix; found three phases later, it's an investigation.
- **Stage by name, review, then commit.** `git add <file>`, `git diff --staged`, `git commit`. Not `git commit -am`, which sweeps in every modified tracked file, including edits an app made behind your back.
- **If you can't explain why something is installed, it doesn't go in the Brewfile.**

## What's in the repo

| Path | Becomes | Purpose |
|---|---|---|
| `Brewfile` | n/a | Dev tools and apps, safe to publish |
| `bootstrap.sh` | n/a | Symlinks configs into `$HOME`; backs up anything it replaces; has `--dry-run` |
| `macos.sh` | n/a | macOS preferences via `defaults write` |
| `zsh/zprofile` | `~/.zprofile` | Login shells: Homebrew env, then `.zprofile.local`, then Docker Desktop's CLI first on PATH |
| `zsh/zshrc` | `~/.zshrc` | Unique PATH, completions, history, editor, mise, Starship, fzf, plugins |
| `git/gitconfig` | `~/.gitconfig` | Shared Git behavior (no identity) |
| `git/gitconfig.local.example` | `~/.gitconfig.local` | Template for identity and signing (copied once, never committed) |
| `git/gitignore_global` | `~/.gitignore_global` | macOS junk ignored in every repo |
| `ssh/config` | `~/.ssh/config` | Includes `~/.ssh/config.local`, then GitHub key + Keychain |
| `ghostty/config` | `~/.config/ghostty/config` | Font, Option-as-Alt, theme |
| `mise/config.toml` | `~/.config/mise/config.toml` | Global Node, pnpm, Python |
| `vscode/extensions.txt` | n/a | Short core list of editor extensions |

**Not in the repo, on purpose:**

| File | Holds |
|---|---|
| `~/dotfiles/Brewfile.local` | Personal apps (media, chat, games). Backed up by Time Machine, not GitHub |
| `~/.gitconfig.local` | Name, email, signing key, signing switches, `allowed_signers` path |
| `~/.zprofile.local` | Machine-specific login settings (e.g. OrbStack's shell integration) |
| `~/.zshrc.local` | Machine-specific interactive settings (currently unused) |
| `~/.ssh/config.local` | Machine-specific SSH includes (e.g. OrbStack's `orb` host) |

## Decisions at a glance

| Area | Choice | Why |
|---|---|---|
| Package manager | Homebrew + `Brewfile` / `Brewfile.local` | Declarative; two explicit files so personal apps never reach the public repo |
| System tools vs language tools | Homebrew for system tools, **mise for language toolchains** | Always obvious where something came from; no "which Python is this?" |
| Terminal | Ghostty | Free, native, fast |
| Shell | Plain zsh + Starship + 2 plugins (no Oh My Zsh) | You know what every line does |
| Node | `node = "24"` (major pin), per-project `.nvmrc` | The `lts` alias moves on someone else's schedule (Node 26 becomes LTS in late 2026) |
| JS package manager | pnpm globally; per project, whatever the lockfile says | Installing with the wrong one ignores the lockfile |
| Editor | VS Code; Settings Sync is the source of truth; Cursor later | Sync covers settings, keybindings, snippets; `extensions.txt` is just the core |
| Git auth + signing | One SSH key (passphrase + Keychain) for both | Simple, free, "Verified" on GitHub |
| API client | Bruno for real work, Postman for familiarity | Bruno collections are readable YAML files in the repo |
| Containers | **Colima** main; Docker Desktop and OrbStack for learning | Colima has no license strings for a project seeking users |
| `docker` CLI | Docker Desktop's (`~/.docker/bin`), first on PATH | Doesn't depend on a learning tool staying installed |
| Self-updating apps | **The app updates itself** | Two updaters means drift; macOS also blocks Homebrew from modifying some apps |

---

## Phase 0: Baseline

### 0a. System Settings, by hand

- **Software Update:** install everything pending first; enable automatic security responses.
- **FileVault:** on. Store the recovery key off this Mac.
- **Firewall:** on (Network → Firewall). Allow Node the first time a dev server listens.
- **Caps Lock → Control:** System Settings → Keyboard → Modifier Keys, **unless Karabiner-Elements is running**. Karabiner routes the keyboard through a virtual device, so do the remap in Karabiner → Simple Modifications instead.
- **Time Machine:** to an external drive.

### 0b. Inventory (when setting up a Mac that already has stuff on it)

```bash
mkdir -p ~/setup-backup
cp ~/.zshrc ~/.zprofile ~/.gitconfig ~/setup-backup/ 2>/dev/null
uname -m                          # arm64
brew --version                    # already installed?
brew list --cask; ls /Applications
brew leaves --installed-on-request   # formulae you asked for (not dependencies)
volta list all 2>/dev/null        # old global Node tools, if any
ls -la ~ | grep -E '\.(zshenv|zlogin|profile|bashrc|bash_profile)$'
```

`brew leaves --installed-on-request` is the inventory that matters. `brew list --formula` is mostly dependencies you never chose.

### Verify

```bash
fdesetup status                                                    # FileVault is On.
/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate   # enabled
```

---

## Phase 1: Homebrew

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"
```

On an existing install: `brew update`, then decide on upgrades. A one-time `brew upgrade` here is the right call: it's the cheapest moment to absorb breakage, and the only "upgrade everything" step in this plan.

**Read `brew doctor` warnings rather than guessing.** For deprecated formulae, `brew info <name>` names the reason and usually the replacement (`tldr` → `tlrc`). Untrusted third-party taps: trust the narrowest thing you need (`brew trust --formula ...`), or untap. To remove an unknown formula, look first: `brew info <name>` and `brew deps --installed --direct <name>`, then `brew uninstall` + `brew autoremove`. Config files left in `/opt/homebrew/etc` after an uninstall are kept on purpose; delete them by hand if you're sure.

### Verify

```bash
which -a brew                 # only /opt/homebrew/bin/brew
ls /usr/local/bin/brew 2>/dev/null && echo "INTEL BREW FOUND" || echo "clean"
brew doctor                   # Your system is ready to brew.
xcode-select -p               # CommandLineTools or Xcode.app, both fine
```

---

## Phase 2: This repo, then the Brewfiles

### 2a. Get the repo

The repo is private and SSH keys don't exist yet (Phase 5), so the first clone uses `gh` over HTTPS:

```bash
brew install git gh
gh auth login                                  # GitHub.com > HTTPS > browser login
gh repo clone AlexLe08/dotfiles ~/dotfiles
```

Keep dotfiles on the **internal drive**, at `~/dotfiles`. Every config in `$HOME` will link into it; on an external drive, an unmounted or slow-mounting disk silently breaks your shell, Git and SSH, and the mount path can change.

### 2b. Recreate `Brewfile.local`

It's not on GitHub. Restore it from Time Machine, or rewrite it:

```ruby
# Brewfile.local: personal apps for THIS machine. Not committed (see .gitignore).
# Install: brew bundle --no-upgrade --file=~/dotfiles/Brewfile.local
cask "keka"
cask "sublime-text"
cask "vesktop"
cask "vlc"
```

### 2c. Adopt apps already installed by hand

`brew bundle` fails on apps dragged into `/Applications`. Adopt them so Homebrew tracks them without touching settings (settings live in `~/Library`). Quit each app first; run one at a time.

```bash
brew bundle check --verbose --file=~/dotfiles/Brewfile   # lists what's missing
brew install --cask --adopt visual-studio-code           # repeat per app
```

On a version mismatch: update the app with its own updater and retry; `--force` only if that fails.

### 2d. Install

```bash
cd ~/dotfiles
brew bundle install --no-upgrade --file=Brewfile
brew bundle install --no-upgrade --file=Brewfile.local
```

**Ignore install caveats** telling you to edit `.zshrc` (zsh plugins) or `brew services start colima`. The repo's `zshrc` handles the plugins, and Colima is configured in Phase 9. **Don't launch OrbStack yet** (Phase 9).

`mise` prints a hint suggesting its own binary instead of Homebrew's. Measured on this machine: `mise hook-env` costs about 30ms per prompt, and Starship (about 43ms) is the larger cost. Keep Homebrew's.

### Verify

```bash
brew bundle check --no-upgrade --file=Brewfile          # satisfied
brew bundle check --no-upgrade --file=Brewfile.local    # satisfied
mise --version && starship --version && colima version
brew doctor
git status                                              # clean
```

---

## Phase 3: macOS defaults

```bash
mkdir -p ~/setup-backup/defaults
for d in NSGlobalDomain com.apple.finder com.apple.dock com.apple.screencapture com.apple.desktopservices; do
  defaults export "$d" ~/setup-backup/defaults/"$d".plist
done
less macos.sh && ./macos.sh
```

Then log out and back in (key repeat needs it).

**Manual step, every time:** Cmd+Shift+5 → Options → Other Location → `~/Screenshots`. Setting the location with `defaults write` broke screenshots on macOS 26 ("Unable to capture desktop image"); choosing it in the UI works, most likely because the UI grants folder access.

"Keep folders on top" only applies to windows **sorted by name**; Downloads sorts by Date Added, so it mixes. That's expected.

### Verify

```bash
defaults read NSGlobalDomain AppleShowAllExtensions                 # 1
defaults read NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled    # 0
defaults read com.apple.desktopservices DSDontWriteUSBStores        # 1
```

By hand: Cmd+Shift+3 saves to `~/Screenshots`; holding a key repeats; `"quotes"` stay straight in TextEdit; Dock hides.

---

## Phase 4: Shell

Keep one terminal window open and untouched as a lifeline; test everything in **new** windows.

### 4a. Migrating from Oh My Zsh and/or Volta (skip on a clean Mac)

```bash
time zsh -i -c exit                   # before-number (run 3x, use the warm ones)
find ~/.oh-my-zsh/custom -type f ! -name "example*"   # custom files OMZ auto-loads
grep -c "git " ~/.zsh_history          # sanity check for the alias count below
for a in $(alias | grep -E "^g[a-z0-9]*='git" | cut -d= -f1); do
  c=$(grep -cE "(^|;)${a}( |$)" ~/.zsh_history 2>/dev/null); [ "$c" -gt 0 ] && echo "$c $a"
done | sort -rn | head -15             # OMZ git aliases you actually use
```

Then remove them:

```bash
rm -rf ~/.volta                        # Volta has no uninstaller
cat ~/.zshenv ~/.profile               # Volta's installer writes PATH lines here
rm ~/.zshenv ~/.profile                # only if that's ALL they contain
rm -rf ~/.oh-my-zsh
rm -f ~/.zcompdump*                    # stale completion cache from OMZ
```

Check projects for `"volta"` pins first (mise doesn't read that field):
`grep -rl '"volta"' <projects-dir> --include=package.json --exclude-dir=node_modules`.

Removing Volta also removes its global tools (e.g. CLIs installed with `npm i -g`). Their config folders in `~` stay.

### 4b. Bootstrap

```bash
cd ~/dotfiles
./bootstrap.sh --dry-run
./bootstrap.sh
```

**Immediately** restore your Git identity, before any commit. Bootstrap replaced `~/.gitconfig`:

```bash
git config --file ~/.gitconfig.local user.name  "$(git config --file ~/setup-backup/.gitconfig user.name)"
git config --file ~/.gitconfig.local user.email "$(git config --file ~/setup-backup/.gitconfig user.email)"
```

On a fresh Mac, set them directly with `git config --file ~/.gitconfig.local user.name "..."`. Use your GitHub noreply address. Always write identity with `--file ~/.gitconfig.local`; `--global` writes into the repo through the symlink.

If `git init` runs before bootstrap, the branch is `master`: `git branch -m master main`.

### 4c. Ghostty

Open Ghostty; the config is already linked. **Ghostty only allows comments on their own line.** A trailing `# comment` becomes part of the value and makes the setting invalid. Always run `ghostty +validate-config` after editing.

`macos-option-as-alt = left` lets left Option act as Alt (Option+. inserts the previous command's last argument) while right Option still types `é ©`. Option+←/→ word-jumping works either way, so it's not a test of this setting.

When SSHing into servers, `TERM=xterm-ghostty` may be unknown there ("unknown terminal type"). Ghostty's shell-integration options can handle this; set it up when you first hit it.

### Verify (new window)

```bash
ls -la ~/.zshrc ~/.zprofile ~/.gitconfig ~/.ssh/config     # all -> ~/dotfiles/...
echo $PATH | tr ':' '\n' | sort | uniq -d                  # prints nothing
git config user.email && git config init.defaultBranch     # your noreply / main
ghostty +validate-config && echo "config valid"
for i in 1 2 3; do time zsh -i -c exit; done
echo hi   # comment                                         # prints just: hi
```

By hand: Starship prompt; `git ch<Tab>` completes; Ctrl+R opens fzf; gray autosuggestions; `ls` green, `lss` red.

**Startup time:** about 200ms warm on this machine, and accepted. Profiling showed `compinit` dominates; the completion cache is reused normally (it's rebuilt once whenever the set of completion files changes, which is the 500ms first run you'll sometimes see). Ruled out: working directory, Docker completions, a running Colima VM. If it gets noticeably worse, profile it (see Troubleshooting).

---

## Phase 5: SSH key, GitHub, signing

### 5a. Key

```bash
ssh-keygen -t ed25519 -C "<your-noreply-email>"     # default path; SET a passphrase
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
```

A passphrase protects every copy of the key, including Time Machine's. The Keychain means you won't retype it.

Never reuse a CI deploy key (e.g. `github-actions-deploy`) as a personal key.

### 5b. GitHub

```bash
gh auth refresh -h github.com -s admin:public_key,admin:ssh_signing_key
gh config set git_protocol ssh
gh ssh-key add ~/.ssh/id_ed25519.pub --type authentication --title "Mac mini"
gh ssh-key add ~/.ssh/id_ed25519.pub --type signing --title "Mac mini (signing)"
git -C ~/dotfiles remote set-url origin git@github.com:AlexLe08/dotfiles.git
```

The first SSH connection asks you to confirm GitHub's host key. Compare it to GitHub's published fingerprints (ED25519: `SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU`) before typing yes.

### 5c. Signing

```bash
git config --file ~/.gitconfig.local commit.gpgsign true
git config --file ~/.gitconfig.local tag.gpgSign true
echo "$(git config user.email) $(cat ~/.ssh/id_ed25519.pub)" > ~/.ssh/allowed_signers
git config --file ~/.gitconfig.local gpg.ssh.allowedSignersFile ~/.ssh/allowed_signers
```

Turn signing on only **after** the key exists; before that, every commit fails. If signing later fails or asks for the passphrase (e.g. after a restart): `ssh-add --apple-use-keychain ~/.ssh/id_ed25519`.

### 5d. Retire old keys

Order matters: add the new key, **verify** (push something and see "Verified"), then `gh ssh-key delete <id>` and delete the old files. Revoking on GitHub is what makes old copies (e.g. in backups) useless.

### Verify

```bash
ssh -T git@github.com                                  # Hi <username>!
ssh -vT git@github.com 2>&1 | grep -iE "offering|authenticated"   # offers id_ed25519
git --no-pager log --show-signature -1                 # Good "git" signature
gh ssh-key list                                        # only current keys
```

On GitHub, the latest commit shows **Verified**. Older unsigned commits show no badge; don't rewrite history to sign them.

---

## Phase 6: Runtimes with mise

```bash
mise doctor          # "problems" before install are just "not installed yet"
mise install
```

`mise doctor` reporting "tool X is not installed" before `mise install` is the expected state, not an error.

**Per project:** add a version pin if missing. `.nvmrc` rather than `mise.toml`, because every Node tool and CI service reads `.nvmrc`:

```bash
echo "24" > .nvmrc
```

mise reads `.nvmrc` / `.node-version` / `.python-version` because of `idiomatic_version_file_enable_tools` in `mise/config.toml`; recent mise versions don't by default. Use the package manager matching the lockfile (`package-lock.json` → npm, `pnpm-lock.yaml` → pnpm). Projects on Node 20 are past end-of-life (April 2026): bump them to 24 and run their tests.

Global CLIs that should survive Node upgrades: `mise use --global npm:<package>`. Python tooling (`uv`): `mise use --global uv` when a Python project needs it, not before.

Never `sudo npm install -g`.

### Verify

```bash
mise doctor                  # No problems found
mise ls                      # node 24.x, pnpm, python 3.13
which -a python3             # mise's first, /usr/bin/python3 last
```

Then in a real project: `mise ls --current`, `node -v` matches its pin, install, run the dev server.

---

## Phase 7: Editor

**Settings Sync is the source of truth** (Accounts icon → Backup and Sync Settings, GitHub). `vscode/extensions.txt` is a short core list for bootstrapping, not a mirror:

```bash
xargs -L1 code --install-extension < ~/dotfiles/vscode/extensions.txt
```

Removed during setup, and why: `vs-code-prettier-eslint` (double-formats alongside the separate Prettier and ESLint extensions), Live Server (unmaintained; Vite does it), Code Runner (runs outside the project's environment), Auto Rename Tag, Trailing Spaces and color extensions (built into VS Code now). Tailwind's extension belongs in a project's `.vscode/extensions.json` recommendations, not the core list.

Key user settings (Settings Sync carries these):

```json
"[javascript][typescript][javascriptreact][typescriptreact][json][jsonc][css][scss][html][markdown]": {
  "editor.defaultFormatter": "esbenp.prettier-vscode"
},
"editor.formatOnSave": true,
"prettier.requireConfig": true,
"files.autoSave": "onFocusChange",
"editor.linkedEditing": true,
"files.trimTrailingWhitespace": true,
"files.insertFinalNewline": true,
"editor.renderWhitespace": "trailing",
"[markdown]": { "files.trimTrailingWhitespace": false },
"terminal.integrated.fontFamily": "JetBrainsMono Nerd Font"
```

Why: Prettier is set **per language**, not globally, so Python files don't hit a formatter that can't handle them. `requireConfig` stops Prettier reformatting projects that don't use it. `onFocusChange` instead of `afterDelay`, because format-on-save does **not** run on `afterDelay` auto-saves. The Markdown exception exists because two trailing spaces are a line break there.

**Cursor later:** uncomment its Brewfile line; it imports VS Code's setup in one click; it uses Open VSX, so some Microsoft extensions aren't available. Change `core.editor` and `EDITOR` to `cursor --wait` in the same commit.

### Verify

```bash
git commit --allow-empty      # in a scratch repo: VS Code opens; closing the tab finishes the commit
```

Prettier test with a `.ts` file: blank lines are cleaned in a project with a Prettier config, untouched in one without.

---

## Phase 8: Browsers and tools

- **Safari:** Settings → Advanced → "Show features for web developers". Every iOS browser is WebKit.
- **Bruno:** collections are folders of YAML (`opencollection.yml` plus one `.yml` per request), stored inside each project repo. Name requests in kebab-case so files have no spaces. `timeout: 0` means no timeout; set one for real collections.
- **Postman:** free account. It syncs to the cloud; never store real secrets in environment values (use Vault, or `.env` + Bruno).
- **Beekeeper Studio:** SQLite or Postgres (Phase 9).
- **Raycast:** free Cmd+Space from Spotlight first (Keyboard Shortcuts → Spotlight), then set Raycast's hotkey. Bind window-management hotkeys. Clipboard History records everything you copy, including API keys: exclude password managers and keep history short.

---

## Phase 9: Containers

The `docker` command is only a client. Docker Desktop, OrbStack and Colima are separate engines, each in its own VM, with **separate images, containers and volumes**. The CLI picks one via **contexts**. Run one engine at a time (port clashes, RAM).

### 9a. Colima (main engine)

```bash
colima start \
  --vm-type vz \
  --mount-type virtiofs \
  --cpu 4 \
  --memory 4 \
  --ssh-config=false \
  --mount "$HOME:w" \
  --mount "/Volumes/<YourSSD>:w"
```

- Specifying any `--mount` replaces Colima's default home-folder mount, so list `$HOME` too. Without the SSD mount, containers see empty folders for projects on the external drive.
- `--ssh-config=false` stops Colima adding an `Include` to `~/.ssh/config` (which is in this repo) on every start. If your Colima version rejects the flag, set `sshConfig: false` in `~/.colima/default/colima.yaml`.
- Settings are saved; later, plain `colima start` / `colima stop`. Don't start it at login.

Test the SSD mount reads **and** writes:

```bash
T="/Volumes/<YourSSD>/colima-mount-test"; mkdir -p "$T" && echo "from mac" > "$T/in.txt"
docker run --rm -v "$T:/data" alpine sh -c 'cat /data/in.txt && echo "from container" > /data/out.txt'
cat "$T/out.txt"; rm -rf "$T"
```

### 9b. A real database

```yaml
services:
  db:
    image: postgres:18
    environment:
      POSTGRES_USER: dev
      POSTGRES_PASSWORD: dev
      POSTGRES_DB: playground
    ports:
      - "127.0.0.1:5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U dev -d playground"]
      interval: 2s
      timeout: 3s
      retries: 10
volumes:
  pgdata:
```

Pin the major version (new majors can't read old data). Bind ports to `127.0.0.1` so the database isn't on your network. Postgres 18's image mounts at `/var/lib/postgresql` (older guides show `.../data`). Real credentials go in a gitignored `.env`. `docker compose down` keeps data; **`down -v` deletes it**. `psql` uses a pager: add `-P pager=off`.

### 9c. Docker Desktop and OrbStack (learning)

- Turn off **start at login** in both. Docker Desktop: Resources → Memory 4 GB.
- OrbStack: decline its offer to migrate Docker Desktop data.
- **Docker Desktop switches the context to itself on launch and doesn't switch back on quit.** After any Desktop or OrbStack session: quit the app, then `colima start` or `docker context use colima`.
- Both apps edit shell and SSH files on launch. Because those files are symlinks into this repo, you'll see it in `git status`. How each is handled:

| Edit | By | Where it lives now |
|---|---|---|
| PATH line for `~/.docker/bin` | Docker Desktop | `zsh/zprofile`, prepended and guarded, wrapped in Docker Desktop's own marker comments. With its markers present, Desktop stops re-adding its block (tested) |
| Completions block (runs `compinit` again) | Docker Desktop | Replaced by one guarded `FPATH` line in `zsh/zshrc` before the single `compinit` |
| `source ~/.orbstack/shell/init.zsh` | OrbStack | `~/.zprofile.local` |
| `Include ~/.orbstack/ssh/config` | OrbStack | `~/.ssh/config.local` |
| `Include ~/.colima/ssh_config` | Colima | Removed; `--ssh-config=false` |

OrbStack also points `/usr/local/bin/docker` at itself. Docker Desktop's CLI being first on PATH means `docker` keeps working if OrbStack is ever uninstalled.

If a tool reports "Cannot connect to the Docker daemon" while `docker ps` works in the terminal, it's ignoring contexts and using `/var/run/docker.sock`. Point that tool at Colima's socket (`docker context ls` shows it).

### Verify

```bash
which -a docker                 # ~/.docker/bin/docker first
docker context show             # colima
docker context ls               # colima, default, desktop-linux, orbstack
git -C ~/dotfiles status --short   # empty, even after launching Desktop/OrbStack and restarting Colima
```

---

## Phase 10: Final check and upkeep

```bash
brew doctor
brew bundle check --no-upgrade --file=~/dotfiles/Brewfile
brew bundle check --no-upgrade --file=~/dotfiles/Brewfile.local
mise doctor | tail -1
ssh -T git@github.com
docker context show
git -C ~/dotfiles status -sb        # ## main...origin/main
```

### Upkeep

- **New brew package:** add it to the right Brewfile by hand (or `brew bundle dump --force` and sort the result), review, commit.
- **Self-updating apps** (VS Code, Postman, Chrome...) update themselves. `brew outdated --greedy` will list them anyway; plain `brew outdated` is the check that matches this policy.
- **Homebrew can't modify some apps** when run from a terminal without macOS's **App Management** permission (`chown: ... Operation not permitted`). Prefer the app's own updater. Granting App Management to the terminal lets *any* command there modify apps; only do it if you truly need it.
- **After launching Docker Desktop or OrbStack:** `git -C ~/dotfiles status` and `docker context use colima`.
- **Committing:** `git add <file>`, `git diff --staged`, `git commit`, `git push`. Starship's `⇡` means unpushed commits.

---

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `extra command-line argument "#"`, or words after `#` passed to a command | zsh doesn't allow comments in typed commands by default | `setopt INTERACTIVE_COMMENTS` (in `zshrc`) |
| Ghostty: `invalid value "true  # ..."` | Ghostty doesn't support end-of-line comments | Comments on their own line; `ghostty +validate-config` |
| Command output takes over the screen; `q` to quit | A pager (`less`) | `git --no-pager ...`, `psql -P pager=off` |
| `zsh: no matches found: ~/.zcompdump*` | zsh errors on wildcards that match nothing | Means there's nothing there |
| Screenshot: "Unable to capture desktop image" | Location set with `defaults write` | Set it via Cmd+Shift+5 → Options |
| Duplicate PATH entries | `/etc/paths.d/homebrew` plus `brew shellenv` | `typeset -U path PATH`; leave the system file alone |
| Shell edits appear in `git status` you didn't make | An app edited a symlinked config | Diff it, `git restore`, move the line to a `.local` file |
| Docker commands fail after using Docker Desktop | Context left on `desktop-linux` | `docker context use colima` |
| Containers see empty project folders | Path not mounted into Colima's VM | `--mount "/Volumes/<YourSSD>:w"` (plus `$HOME:w`) |
| `brew upgrade` on an app: `Operation not permitted` | macOS App Management protection | Use the app's own updater |
| Global Node version changed by itself | `node = "lts"` follows new LTS releases | Pin a major: `node = "24"` |
| An app's change landed in an unrelated commit | `git commit -am` stages everything | Stage by name; review `--staged` |
| Shell startup got slower | Usually `compinit` | Profile (below) |
| `brew uninstall`: "already an App at '/opt/homebrew/Caskroom/...'" | A leftover copy in Homebrew's storage folder | Look at both copies first, then `brew uninstall --cask --zap --force <name>` |

**Profiling shell startup** (temporary edit, undone by Git):

```bash
cd ~/dotfiles
{ echo 'zmodload zsh/zprof'; cat zsh/zshrc; echo 'zprof | head -20'; } > /tmp/zshrc.prof
cat /tmp/zshrc.prof > zsh/zshrc
zsh -i -c exit
git restore zsh/zshrc
```

`zprof` measures shell functions only; the `eval "$(...)"` lines run separate programs, so time those individually with `time (mise activate zsh >/dev/null)` and similar. Per-prompt costs (`mise hook-env`, `starship prompt`) matter more than startup, since you pay them after every command.

## Rollback

- **Shell config:** `rm ~/.zshrc && cp ~/.dotfiles-backup/<timestamp>/.zshrc ~/.zshrc`. Always `rm` the symlink first: copying onto a symlink writes *through* it into the repo.
- **macOS defaults:** `defaults delete <domain> <key>` for one setting; `defaults import <domain> ~/setup-backup/defaults/<domain>.plist` for a whole domain.
- **Any repo file:** `git restore <file>` (uncommitted) or `git revert <commit>` (committed).

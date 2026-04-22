# dotfiles-mac

Personal Mac configuration that lets a fresh machine come up reasonably close to the current one. Repo: [`b00llish/dotfiles-mac`](https://github.com/b00llish/dotfiles-mac).

This repo handles **shell, git, Brew packages, macOS defaults, and the bootstrap glue**. App-level settings (Sublime, iTerm, etc.) are handled separately by **Mackup**, which syncs those configs through **iCloud**.

---

## Lay of the land

```
.dotfiles/
├── README.md                      ← this file
├── fresh.sh                       ← legacy bootstrap (see "Known Issues")
├── ssh.sh                         ← generates ed25519 SSH key for GitHub
├── Brewfile                       ← every brew/cask/mas package
├── .macos                         ← 43KB of `defaults write` commands
├── .gitignore_global              ← intended global gitignore (NOT currently linked — see Known Issues)
├── .zshrc-old                     ← stale, can be archived (see Known Issues)
│
├── installers/
│   ├── bootstrap.sh               ← interactive symlink installer (links every *.symlink)
│   ├── install.sh                 ← finds & runs every */install.sh subscript
│   └── dot                        ← runs xcode + macos defaults
│
├── zsh/                           ← active zsh setup (sourced by ~/.zshrc)
│   ├── zshrc.symlink              ← top-level entry point; ~/.zshrc → here
│   ├── config                     ← env vars, p10k instant-prompt, paths
│   ├── plugins                    ← antigen + bundles + p10k theme
│   ├── named-dirs                 ← ~projects, ~dotfiles, ~rdi shortcuts
│   ├── aliases                    ← `reload`, `gst`, `projects`, etc.
│   ├── funcs                      ← `ibit`, `rdi-cost` shell functions
│   ├── p10k.zsh                   ← powerlevel10k config (uses POWERLEVEL9K_* prefix for back-compat)
│   ├── plugins.zwc                ← compiled cache for plugins file
│   └── vscode                     ← VSCode `code` shim (not installed by default)
│
├── git/
│   ├── gitconfig.symlink          ← user/aliases/credential — links to ~/.gitconfig.local? (see Known Issues)
│   ├── gitconfig.local.symlink    ← empty placeholder; ~/.gitconfig.local → here
│   ├── git_unpushed.sh            ← `git diffall` alias backs this
│   ├── plog.sh                    ← `git plog` alias backs this
│   └── sync_with_upstream.sh      ← `git syncu` alias backs this
│
├── mackup/
│   └── mackup.cfg.symlink         ← engine = icloud; ignores zsh/iterm2/ssh
│
├── macos/
│   └── settings                   ← additional macOS tweaks (currently unused)
│
├── py/
│   ├── install.sh                 ← `pyenv install 3.11.5` + poetry config
│   └── pyproject.toml             ← reference Python project template
│
├── xcode/
│   └── defaults                   ← Xcode `defaults write` commands
│
└── bin/
    └── treed.sh                   ← directory tree helper
```

### Active symlinks in `~`

| Home file | Points to | Notes |
|---|---|---|
| `~/.zshrc` | `~/.dotfiles/zsh/zshrc.symlink` | active, this is the only zsh entry point that matters |
| `~/.gitconfig.local` | `~/.dotfiles/git/gitconfig.local.symlink` | empty placeholder; harmless |
| `~/.zshenv` | `~/Dropbox/Mackup/.zshenv` | **stale** — see Known Issues |
| `~/.zlogin` | `~/Dropbox/Mackup/.zlogin` | **stale** — see Known Issues |
| `~/.gitconfig`, `~/.aliases`, `~/.bashrc`, `~/.npmrc`, `~/.psqlrc`, ... | `~/Library/Mobile Documents/com~apple~CloudDocs/Mackup/...` | managed by Mackup over iCloud |

### How the active zsh load actually flows

`~/.zshrc` → `zsh/zshrc.symlink`, which sources, in order:

1. `zsh/config` — `$ZSH=~/.oh-my-zsh`, p10k instant prompt, `SSH_AUTH_SOCK` (1Password), gcloud PATH, BTC env vars
2. `zsh/plugins` — sets `plugins=(git sublime z)` for oh-my-zsh to consume
3. `$ZSH/oh-my-zsh.sh` — full oh-my-zsh load (reads `plugins=(...)` set in step 2)
4. `zsh/p10k.zsh` — sets the `POWERLEVEL9K_*` variables that drive the p10k prompt (p10k respects the legacy prefix)
5. `zsh/named-dirs` — registers `~projects`, `~dotfiles`, `~library`, `~rdi`
6. `zsh/aliases` — every `gst`/`pull`/`push`/`reload` alias
7. `zsh/funcs` — `ibit`, `rdi-cost` functions
8. pyenv init + poetry PATH + zsh-completions
9. (At end of file) sources `zsh-autosuggestions`, then `powerlevel10k.zsh-theme`, then `zsh-syntax-highlighting` from Homebrew (in that order — syntax-highlighting must be last)

### What's installed where

- **Homebrew packages backing the shell:** `powerlevel10k`, `pyenv`, `zsh-autosuggestions`, `zsh-syntax-highlighting`, `zsh-completions`
- **oh-my-zsh plugins:** `git`, `sublime`, `z` (declared in `zsh/plugins`)
- **Mac App Store apps via mas:** see `Brewfile` (1Password Safari, Crypto Pro, Drafts, HP Smart, NextDNS, Raivo OTP, WireGuard, etc.)
- **Mackup ignored apps** (i.e., this repo manages them, not Mackup): `iterm2`, `ssh`, `zsh`

---

## Setting up a fresh Mac

> The original `fresh.sh` has bugs (see Known Issues). Until those are fixed, follow this manual sequence.

1. Sign into **1Password**.
2. Generate an SSH key and add to GitHub:
   ```sh
   curl https://raw.githubusercontent.com/b00llish/dotfiles-mac/HEAD/ssh.sh | sh -s "b00llish@pm.me"
   pbcopy < ~/.ssh/id_ed25519.pub
   # then paste into github.com/settings/keys
   ```
3. Clone this repo:
   ```sh
   git clone git@github.com:b00llish/dotfiles-mac.git ~/.dotfiles
   ```
4. Install Homebrew (if not present), then everything in the Brewfile:
   ```sh
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   brew bundle --file ~/.dotfiles/Brewfile
   ```
5. Symlink the configs that this repo owns:
   ```sh
   cd ~/.dotfiles && ./installers/bootstrap.sh
   ```
   This walks every `*.symlink` file (anywhere up to depth 2) and creates `~/.<basename>` pointing at it. Today that means `~/.zshrc`, `~/.gitconfig.local`, and `~/.mackup.cfg`.
6. Restore Mackup-managed configs from iCloud:
   ```sh
   mackup restore
   ```
7. Apply macOS defaults (this restarts several apps; do it last):
   ```sh
   sh ~/.dotfiles/.macos
   ```
8. Open a new terminal and confirm the prompt loads cleanly.

---

## Periodic maintenance

Recommended cadence: **monthly skim, quarterly deeper pass**.

| When | What to do |
|---|---|
| Every few weeks | `brew bundle dump --force --file ~/.dotfiles/Brewfile` to capture newly installed packages, review the diff, commit. |
| Every few weeks | `brew bundle cleanup --file ~/.dotfiles/Brewfile` to see what's installed but missing from the Brewfile (decide: add or uninstall). |
| Quarterly | `mackup list` and `mackup restore --dry-run` to see what Mackup would touch. Run actual `mackup backup` if you've configured a new app you want synced. |
| Quarterly | Review `zsh/aliases` and `zsh/funcs` — prune dead aliases, promote any `~/.zshrc.local` one-offs that have stuck. |
| When prompt changes | `p10k configure` regenerates `~/.p10k.zsh`. If you want it tracked, copy it into `~/.dotfiles/zsh/` and source it from `zshrc.symlink`. |
| When you change anything in `.dotfiles` | `cd ~/.dotfiles && git status && git add -p && git commit && git push`. |

### How to add a new alias / function

- Aliases → append to `zsh/aliases`.
- Functions → append to `zsh/funcs`.
- Either way, run `reload` (after the Known Issues below are fixed) or `exec zsh` to pick up the change.

### How to add a new tracked dotfile

1. Move/copy the file into `~/.dotfiles/<area>/<name>.symlink` (the trailing `.symlink` is required for `installers/bootstrap.sh` to pick it up).
2. Re-run `~/.dotfiles/installers/bootstrap.sh`. It will create `~/.<name>` → the symlink target.
3. Commit.

### How to add a new Brew package

1. `brew install <pkg>` (or `brew install --cask <pkg>`).
2. `brew bundle dump --force --file ~/.dotfiles/Brewfile`, review the diff, commit.

---

## Known issues / cleanup backlog

These are real bugs found while auditing. Each is independent — fix as you have time.

### 1. `reload` hangs and prints `command not found: spaceship_prompt` ✅ FIXED 2026-04-22

**Root cause:** `zshrc.symlink` was sourcing `zsh/spaceship`, which set `PROMPT='${${${$(spaceship_prompt)//...}}}'`. Spaceship-prompt is no longer installed (replaced by powerlevel10k via antigen), so every prompt redraw failed with "command not found", and re-sourcing in an active shell layered the broken PROMPT on top of the working one.

**Fix:** removed the `source .../zsh/spaceship` line from `zshrc.symlink`. The `zsh/spaceship` file is left in place but unused; safe to delete in a future cleanup.

### 2. Broken pyenv quoting in `zshrc.symlink` ✅ FIXED 2026-04-22

**Root cause:** Lines 29–30 of `zshrc.symlink` were missing closing quotes:
```zsh
PYENV_ROOT="$HOME/.pyenv          # no closing "
PATH="$PYENV_ROOT/bin:$PATH       # no closing "
```
zsh treats those as multi-line strings, swallowing the next several lines into the variable. PYENV_ROOT and PATH ended up containing newlines and `if` statement fragments. pyenv was never properly initialized; the user has been falling back on the brew-installed `pyenv` binary via `/opt/homebrew/bin`.

**Fix:** added closing quotes and `export`s.

### 3. `~/.zshenv` and `~/.zlogin` symlinked to Dropbox/Mackup, not iCloud/Mackup

Every other Mackup-synced file in `~` points to `~/Library/Mobile Documents/com~apple~CloudDocs/Mackup/`. These two still point to `~/Dropbox/Mackup/` from the pre-iCloud era. Contents:
- `.zshenv` — old prezto-style "warning: don't edit PATH from .zshenv.local" message
- `.zlogin` — RVM (Ruby Version Manager) shim; not currently relied on

**Recommendation:** Either (a) move the iCloud/Mackup copies of these in, then `rm` and re-symlink to the iCloud path, or (b) drop both symlinks entirely if you no longer use prezto/RVM. Most likely (b).

### 4. `fresh.sh` has broken symlink commands

- `ln -s .zshrc $HOME/.zshrc` — relative path with no source file in cwd; would create a dangling symlink.
- `ln -s ./.mackup.cfg $HOME/.mackup.cfg` — same issue; the actual file lives at `mackup/mackup.cfg.symlink`.

**Recommendation:** Replace the symlink section with a call to `installers/bootstrap.sh`. The bootstrap script already does the right thing (walks every `*.symlink`).

### 5. `installers/bootstrap.sh` references missing `gitconfig.local.symlink.example`

`setup_gitconfig` runs only when `git/gitconfig.local.symlink` is missing, so on a fresh machine where the file already exists in the repo (as an empty file), this branch never runs — but if it ever does, it'll fail because `gitconfig.local.symlink.example` doesn't exist.

**Recommendation:** Either delete the `setup_gitconfig` function or create the `.example` template.

### 6. `~/.gitconfig` is Mackup'd but `~/.dotfiles/git/gitconfig.symlink` exists

`bootstrap.sh` would happily try to install `gitconfig.symlink` → `~/.gitconfig`, but that target is already owned by Mackup (which sets `name = b00llish`, `pr = !sh ~/.dotfiles/git/pull_request.sh`, etc.). Currently the dotfiles `gitconfig.symlink` has no effect because nothing symlinks to it.

**Decision needed:** either (a) make this repo authoritative for `.gitconfig` and remove from Mackup, or (b) delete `git/gitconfig.symlink` and let Mackup own it. Option (a) is more git-friendly (changes are versioned).

### 7. `git pr` alias points to nonexistent script

`gitconfig.symlink` and the Mackup'd `.gitconfig` both define `pr = !sh ~/.dotfiles/git/pull_request.sh`, but no `pull_request.sh` exists. `git pr` will silently no-op. Either remove the alias or write the script (or replace with `gh pr create`).

### 8. `.gitignore_global` exists but isn't wired up

`.dotfiles/.gitignore_global` has solid global ignores (`.DS_Store`, `.idea/`, `.vscode`, packages, logs). But the active `core.excludesfile` in `gitconfig.symlink` is `~/.dotfiles/.gitignore` (only 2 lines). Recommendation: either point `core.excludesfile = ~/.dotfiles/.gitignore_global`, or merge the contents.

### 9. Plugin manager ✅ RESOLVED 2026-04-22

Migrated off antigen. `zsh/plugins` now sets `plugins=(git sublime z)` for oh-my-zsh's native plugin loader. Non-OMZ plugins (`zsh-autosuggestions`, `powerlevel10k`, `zsh-syntax-highlighting`) are sourced directly from `$HOMEBREW_PREFIX` at the end of `zshrc.symlink`. Brewfile updated to include all three so a fresh Mac install gets them; `antigen` package uninstalled.

### 10. `.zshrc-old` is dead weight

4KB of stale config from before the antigen+p10k migration. Recommendation: delete (it's already in git history if you ever want it back).

### 11. README's "command will halt after installing oh-my-zsh; re-run" is no longer true

Old `fresh.sh` had logic that exited mid-install. The current one doesn't. (Already corrected in this rewrite.)

### 12. `installers/install.sh` runs `py/install.sh`, which pins Python 3.11.5

`py/install.sh` does `pyenv install 3.11.5 && pyenv global 3.11.5`. That version is now ~2 years old. Bump to a current 3.12.x or 3.13.x when convenient.

---

## Quick reference

| Want to... | Do this |
|---|---|
| Reload shell after editing aliases/funcs | `reload` (or `exec zsh`) |
| Add a new alias | edit `zsh/aliases`, then `reload` |
| Add a new shell function | edit `zsh/funcs`, then `reload` |
| Add a new brew package and persist it | `brew install foo && brew bundle dump --force --file ~/.dotfiles/Brewfile` |
| Edit dotfiles in your editor | `dotfiles` (alias for `cd $DOTFILES`) |
| See where a `~/.<file>` symlink points | `readlink ~/.foo` |
| See what Mackup is syncing | `mackup list` |
| Sync a newly Mackup-managed app | `mackup backup` |
| Pull Mackup config to a new machine | `mackup restore` |

# dotfiles-mac

Personal Mac configuration that lets a fresh machine come up reasonably close to the current one. Repo: [`b00llish/dotfiles-mac`](https://github.com/b00llish/dotfiles-mac).

This repo handles **shell, git, Brew packages, macOS defaults, and the bootstrap glue**. App-level settings (Sublime, iTerm, etc.) are handled separately by **Mackup**, which syncs those configs through **iCloud**.

---

## Lay of the land

```
.dotfiles/
├── README.md                      ← this file
├── fresh.sh                       ← end-to-end bootstrap (run on a new Mac)
├── ssh.sh                         ← generates ed25519 SSH key for GitHub
├── Brewfile                       ← every brew/cask/mas package
├── .macos                         ← 43KB of `defaults write` commands
├── .gitignore_global              ← global gitignore (wired up via core.excludesfile)
│
├── installers/
│   ├── bootstrap.sh               ← symlink installer (links every *.symlink); idempotent
│   ├── install.sh                 ← finds & runs every */install.sh subscript
│   └── dot                        ← runs xcode + macos defaults
│
├── zsh/                           ← active zsh setup (sourced by ~/.zshrc)
│   ├── zshrc.symlink              ← top-level entry point; ~/.zshrc → here
│   ├── config                     ← env vars, p10k instant-prompt, paths
│   ├── plugins                    ← `plugins=(git sublime z)` for oh-my-zsh
│   ├── named-dirs                 ← ~projects, ~dotfiles, ~rdi shortcuts
│   ├── aliases                    ← `reload`, `gst`, `projects`, etc.
│   ├── funcs                      ← `ibit`, `rdi-cost` shell functions
│   ├── p10k.zsh                   ← powerlevel10k config (uses POWERLEVEL9K_* prefix for back-compat)
│   ├── plugins.zwc                ← compiled cache for plugins file
│   └── vscode                     ← VSCode `code` shim (not installed by default)
│
├── git/
│   ├── gitconfig.symlink          ← active ~/.gitconfig source (versioned in this repo)
│   ├── gitconfig.local.symlink    ← empty placeholder for machine-specific overrides
│   ├── git_unpushed.sh            ← `git diffall` alias backs this
│   ├── plog.sh                    ← `git plog` alias backs this
│   └── sync_with_upstream.sh      ← `git syncu` alias backs this
│
├── mackup/
│   └── mackup.cfg.symlink         ← engine = icloud; ignores git/iterm2/ssh/zsh
│
├── macos/
│   └── settings                   ← additional macOS tweaks (currently unused)
│
├── py/
│   ├── install.sh                 ← `pyenv install 3.12.8` + poetry config
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
| `~/.zshrc` | `~/.dotfiles/zsh/zshrc.symlink` | active, the only zsh entry point that matters |
| `~/.gitconfig` | `~/.dotfiles/git/gitconfig.symlink` | versioned in this repo (was Mackup before 2026-04-22) |
| `~/.gitconfig.local` | `~/.dotfiles/git/gitconfig.local.symlink` | empty placeholder for machine-specific overrides |
| `~/.mackup.cfg`, `~/.aliases`, `~/.bashrc`, `~/.npmrc`, `~/.psqlrc`, ... | `~/Library/Mobile Documents/com~apple~CloudDocs/Mackup/...` | managed by Mackup over iCloud |

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
- **Mackup ignored apps** (i.e., this repo manages them, not Mackup): `git`, `iterm2`, `ssh`, `zsh`

---

## Setting up a fresh Mac

1. Sign into **1Password**.
2. Clone this repo (over HTTPS — no SSH key needed yet):
   ```sh
   git clone https://github.com/b00llish/dotfiles-mac.git ~/.dotfiles
   ```
3. Run the bootstrap:
   ```sh
   ~/.dotfiles/fresh.sh
   ```
   This installs Homebrew, installs oh-my-zsh, runs `installers/bootstrap.sh` to symlink every `*.symlink` file (`~/.zshrc`, `~/.gitconfig`, `~/.gitconfig.local`, `~/.mackup.cfg`), brew-bundles everything from the Brewfile, installs Python via pyenv, runs `mackup restore` to pull app configs from iCloud, and finally prompts before applying the macOS defaults from `.macos`. Each step is idempotent — safe to re-run.
4. (Optional) generate an SSH key for GitHub if you want SSH protocol for any repos:
   ```sh
   ~/.dotfiles/ssh.sh "b00llish@pm.me"
   pbcopy < ~/.ssh/id_ed25519.pub
   # add at https://github.com/settings/keys (Authentication Key)
   ```
   All current repos use HTTPS + the gh OAuth token in the keychain, so this is only needed if you want to add SSH-protocol remotes.
5. Open a new terminal and confirm the prompt loads cleanly.

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
- Either way, run `reload` (or `exec zsh`) to pick up the change.

### How to add a new tracked dotfile

1. Move/copy the file into `~/.dotfiles/<area>/<name>.symlink` (the trailing `.symlink` is required for `installers/bootstrap.sh` to pick it up).
2. Re-run `~/.dotfiles/installers/bootstrap.sh`. It will create `~/.<name>` → the symlink target.
3. Commit.

### How to add a new Brew package

1. `brew install <pkg>` (or `brew install --cask <pkg>`).
2. `brew bundle dump --force --file ~/.dotfiles/Brewfile`, review the diff, commit.

---

## Changelog

### 2026-04-22 — full audit + cleanup pass

A round of bug-hunting and modernization. No outstanding backlog as of this date.

**Shell:**
- Fixed `reload` hang. `zshrc.symlink` was sourcing `zsh/spaceship`, which set `PROMPT='${$(spaceship_prompt)...}'` — spaceship-prompt is no longer installed (replaced by p10k via antigen), so every prompt redraw was failing.
- Fixed broken pyenv quoting in `zshrc.symlink` (missing closing `"` on PYENV_ROOT/PATH lines was making zsh swallow the next several lines into the string). pyenv had been silently uninitialized, falling back on the brew binary.
- Migrated off antigen → oh-my-zsh native `plugins=(git sublime z)` array + direct brew sources for `zsh-autosuggestions`, `powerlevel10k`, `zsh-syntax-highlighting` (in that order; syntax-highlighting must be last). All three brew packages added to Brewfile.
- Renamed `zsh/powerlevel9k` → `zsh/p10k.zsh` (file was always p10k config — POWERLEVEL9K_* prefix is p10k's back-compat). Deleted `zsh/spaceship` and `zsh/p10k.sh` (both unused).
- Deleted stale `~/.zshenv` and `~/.zlogin` symlinks (pointed to `~/Dropbox/Mackup/` from pre-iCloud era; held inert prezto / RVM shims).
- Deleted `.zshrc-old` (4KB of pre-antigen config; recoverable from git history).

**Git:**
- Moved `~/.gitconfig` ownership from Mackup → this repo (symlinked to `git/gitconfig.symlink`). Two divergent configs were merged into one versioned file. Added `git` to Mackup's `applications_to_ignore` so it won't try to take it back. Restored the dormant aliases: `git lazy`, `git syncu`, `git parent`, `git last`, `git plog`, `git diffall`, `git contributors`, `git remotes`, `git amend`.
- Wired up `core.excludesfile = ~/.dotfiles/.gitignore_global` (was a dead pointer to a nonexistent `~/.gitignore` — global ignores were silently a no-op).
- Replaced `git pr = !sh ~/.dotfiles/git/pull_request.sh` (script never existed) with `git pr = !gh pr create`.
- Disabled `commit.gpgsign` (was prompting 1Password on every commit — solo dev on private repos doesn't need signed commits; flip to `true` if that ever changes).
- Switched `dotfiles-mac` remote from SSH → HTTPS to match every other repo and let GitHub Desktop push without the 1Password SSH agent dance. (Underlying SSH issue: the 1Password key `id_ed25519_github` is registered to GitHub as a *signing key* but not an *authentication key* — fix at github.com/settings/ssh/new if you ever want SSH protocol back.)

**Install scripts:**
- Rewrote `fresh.sh` as an idempotent end-to-end bootstrap: brew → oh-my-zsh → `bootstrap.sh` symlinks → brew bundle → pyenv → mackup restore → netdata → macOS defaults (with a y/N prompt). Old version had broken `ln -s .zshrc` / `ln -s ./.mackup.cfg` lines.
- Removed dead `setup_gitconfig` branch from `installers/bootstrap.sh` (referenced a nonexistent `.example` template).
- Fixed latent infinite-recursion bug in `installers/install.sh` (`find . -name install.sh` was finding itself).
- Bumped `py/install.sh` from Python 3.11.5 → 3.12.8.

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

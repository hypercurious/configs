# configs

Personal dotfiles, organized by portability: anything reusable everywhere lives
in `shared/`, anything that only makes sense on one operating system lives under
that OS's directory.

## Layout

```
shared/                 works on Linux, macOS and Windows
  vim/vimrc             editor config (no OS-specific paths)
  vim/ftplugin/         filetype mappings (c, gitcommit)
  vim/templates/        new-file templates (C, Python solution)
  git/gitconfig         git settings; identity is included from ~/.gitconfig.local
  git/gitignore_global  global ignore file
  shell/profile.sh      portable shell environment, sourced by every OS rc
  shell/aliases.sh      portable aliases
  shell/functions.sh    portable functions (clipcopy, mkcd, kpod)

macos/                  macOS only
  zsh/zshrc             Homebrew, oh-my-zsh, nvm, macOS aliases
  zsh/zshenv            PATH for non-interactive shells
  aerospace/            AeroSpace tiling WM config + window-routing scripts
  linearmouse/          per-device pointer/scroll settings
  homebrew/Brewfile     packages and casks

linux/                  Linux only
  zsh/zshrc             same shape as the macOS rc, Linux paths

windows/                Windows only
  cmd/alias.cmd         cmd.exe prompt and DOSKEY aliases
  install.ps1           bootstrap script

scripts/install.sh      bootstrap script for macOS and Linux
```

Cross-platform apps keep their generic config in `shared/` and only the
OS-specific parts under the OS directory — the shell configs are the clearest
example: the macOS and Linux `zshrc` files each do their own PATH/package-manager
setup and then source `shared/shell/profile.sh`.

## Prerequisites

- `git` and `vim`
- [oh-my-zsh](https://ohmyz.sh) — the zsh configs source it and skip it silently
  when it is missing, so install it first to get the prompt and completions:
  `sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"`
- macOS only: [Homebrew](https://brew.sh), for the Brewfile

## Install

Clone to `~/configs` (the shell config defaults to that path; override with
`CONFIGS_DIR`) and run the bootstrap script for your OS.

macOS / Linux:

```sh
git clone https://github.com/<you>/configs.git ~/configs
cd ~/configs
./scripts/install.sh --dry-run   # preview
./scripts/install.sh
```

macOS packages:

```sh
brew bundle --file=~/configs/macos/homebrew/Brewfile
```

Windows (elevated PowerShell, or with Developer Mode enabled):

```powershell
git clone https://github.com/<you>/configs.git $HOME\configs
cd $HOME\configs
powershell -ExecutionPolicy Bypass -File .\windows\install.ps1
```

The installers symlink files into place and back up anything already there as
`<file>.backup-<timestamp>`. Re-running them is safe: files that already point
at this repo are left alone.

## After installing

The installer creates three untracked files holding everything machine-,
account. The first one needs editing before you commit
anything; the rest are optional.

### 1. Git identity — required

`~/.gitconfig.local` is created with placeholders. Until you edit it, your
commits are authored by `Your Name <you@example.com>`:

```ini
[user]
	name = Your Name
	email = you@example.com
```

To use a different identity for work repos, point them at a second file:

```sh
git config --global includeIf.gitdir:~/work/.path ~/.gitconfig.work
printf '[user]\n\temail = you@company.com\n' > ~/.gitconfig.work
```

### 2. Anything your old shell config had

The installer replaced `~/.zshrc` and backed the old one up as
`~/.zshrc.backup-<timestamp>`. Third-party shell integrations that lived there —
conda, nvm variants, vendor CLIs — are **not** carried over. Copy the lines you
still want into `~/.shell.local`, which `shared/shell/profile.sh` sources last:

```sh
# ~/.shell.local — credentials, work-only aliases, per-host paths.

# Namespace-to-service mapping for kpod(), as <namespace-substring>:<service>.
# The first pair whose substring appears in the namespace wins; with no match,
# the namespace name is used as the service name.
export KPOD_SERVICE_MAP='api:api-server,web:web-frontend'
```

### 3. macOS window routing — optional

`~/.config/aerospace/local.env` tunes the AeroSpace routing scripts. Every value
has a generic default, so set these only if you want profile-specific routing:

```sh
# Literal title suffix identifying a Chrome profile   -> workspace 2
CHROME_WORK_PROFILE_SUFFIX=' - Google Chrome - Profile Name'

# Extended regular expressions
CHROME_MEETING_REGEX='(Google Meet|Calendar)'         # -> workspace 3
TERM_LOG_REGEX='(docker compose.*logs|stern|tail -f)' # -> workspace 5
```

### 4. Restart your shell

```sh
exec zsh
```

Then check it took: `ll` is aliased, `git st` works, and `vim` opens with
relative line numbers.

## Secrets

Nothing secret is tracked in this repo. Keep API keys,
cloud credentials, internal hostnames and internal service names in the local
files above — or better, in the tool's own credential store, such as
`~/.aws/credentials`. Everything tracked here works with generic defaults when
those files are absent.

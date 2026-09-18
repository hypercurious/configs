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
`<file>.backup-<timestamp>`.

## Secrets and machine-local settings

Nothing secret or employer-specific is tracked here. Three untracked files,
created by the installer, hold everything machine- or account-specific:

- `~/.gitconfig.local` — git identity (`user.name`, `user.email`)
- `~/.shell.local` — credentials, work-only aliases, per-host paths, and
  `KPOD_SERVICE_MAP` for `kpod()`; sourced last by `shared/shell/profile.sh`
- `~/.config/aerospace/local.env` — window-routing title patterns
  (`CHROME_WORK_PROFILE_SUFFIX`, `CHROME_MEETING_REGEX`, `TERM_LOG_REGEX`)

Keep API keys, AWS credentials, internal hostnames and internal service names
out of `shared/` and the OS directories — put them in the local files above.
Everything tracked here works with generic defaults when those files are absent.

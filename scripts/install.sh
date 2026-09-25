#!/usr/bin/env bash
# Bootstrap a macOS or Linux machine from this repo.
#
#   ./scripts/install.sh            # ask what to set up
#   ./scripts/install.sh --yes      # set up everything, installing what is missing
#   ./scripts/install.sh --dry-run  # show what would happen, change nothing
#
# Each tool (git, vim, oh-my-zsh, and on macOS the Brewfile, AeroSpace and
# LinearMouse) gets one yes/no question: use the repo's config for it, and
# install it first if it is missing. Every answer defaults to no.
#
# The shared shell profile, aliases and functions are always set up. With
# oh-my-zsh chosen, ~/.zshrc is replaced by the repo's zshrc; otherwise your
# own rc files are kept and just gain a line that loads the shared profile.
#
# Replaced files are backed up to <path>.backup-<timestamp> first.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STAMP="$(date +%Y%m%d%H%M%S)"
DRY_RUN=0
ASSUME_YES=0

usage() { sed -n '2,17p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=1 ;;
        -y|--yes)  ASSUME_YES=1 ;;
        -h|--help) usage; exit 0 ;;
        *)         echo "Unknown option: $arg" >&2; usage >&2; exit 1 ;;
    esac
done

case "$(uname -s)" in
    Darwin) OS="macos" ;;
    Linux)  OS="linux" ;;
    *)      echo "Unsupported OS: $(uname -s). On Windows run windows/install.ps1." >&2; exit 1 ;;
esac

OMZ_DIR="$HOME/.oh-my-zsh"
OMZ_INSTALLER="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
BREW_INSTALLER="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"

log() { printf '%s\n' "$*"; }
has() { command -v "$1" >/dev/null 2>&1; }

# ask "question": succeeds on yes. Defaults to no, and to no when there is no
# terminal to ask on, unless --yes was given.
ask() {
    [ "$ASSUME_YES" -eq 1 ] && return 0
    [ -t 0 ] || return 1
    local reply
    read -r -p "$1 [y/N] " reply || return 1
    case "$reply" in
        [yY]|[yY][eE][sS]) return 0 ;;
        *)                 return 1 ;;
    esac
}

# run cmd...: execute, or only print it under --dry-run.
run() {
    if [ "$DRY_RUN" -eq 1 ]; then
        log "would  run $*"
        return 0
    fi
    "$@"
}

# installed <tool>: whether the tool is usable right now.
installed() {
    case "$1" in
        # macOS ships a /usr/bin/git stub that only works once the Xcode
        # Command Line Tools are installed.
        git)       has git && { [ "$OS" != "macos" ] || [ "$(command -v git)" != /usr/bin/git ] ||
                                xcode-select -p >/dev/null 2>&1; } ;;
        oh-my-zsh) [ -f "$OMZ_DIR/oh-my-zsh.sh" ] ;;
        *)         has "$1" ;;
    esac
}

# --- installing ----------------------------------------------------------------
# Homebrew may be installed but not yet on PATH in a fresh shell.
load_brew() {
    local brew
    for brew in /opt/homebrew/bin/brew /usr/local/bin/brew; do
        if [ -x "$brew" ]; then
            eval "$("$brew" shellenv)"
            return 0
        fi
    done
    return 1
}

ensure_brew() {
    has brew && return 0
    ask "Homebrew is needed to install packages. Install Homebrew?" || return 1
    if [ "$DRY_RUN" -eq 1 ]; then
        log "would  install Homebrew from $BREW_INSTALLER"
        return 0
    fi
    NONINTERACTIVE=$ASSUME_YES /bin/bash -c "$(curl -fsSL "$BREW_INSTALLER")"
    load_brew
}

APT_UPDATED=0
SUDO=""
[ "$(id -u)" -ne 0 ] && SUDO="sudo"

# pkg_install <package>...: install with the platform's package manager.
pkg_install() {
    if [ "$OS" = "macos" ]; then
        ensure_brew || return 1
        run brew install "$@"
    elif has apt-get; then
        if [ "$APT_UPDATED" -eq 0 ]; then
            run $SUDO apt-get update
            APT_UPDATED=1
        fi
        run $SUDO apt-get install -y "$@"
    elif has dnf; then
        run $SUDO dnf install -y "$@"
    elif has pacman; then
        run $SUDO pacman -S --needed --noconfirm "$@"
    elif has zypper; then
        run $SUDO zypper install -y "$@"
    else
        log "No supported package manager found; install $* yourself."
        return 1
    fi
}

install_omz() {
    local dep
    for dep in zsh git curl; do
        installed "$dep" || pkg_install "$dep" || return 1
    done
    if [ "$DRY_RUN" -eq 1 ]; then
        log "would  install oh-my-zsh from $OMZ_INSTALLER"
        return 0
    fi
    # Keep ~/.zshrc: it is replaced by the repo's zshrc further down.
    KEEP_ZSHRC=yes sh -c "$(curl -fsSL "$OMZ_INSTALLER")" "" --unattended
}

# want <tool> <config description>: succeeds if the user wants the repo's
# config for this tool, installing the tool first when it is missing.
want() {
    local tool="$1" config="$2"

    if installed "$tool"; then
        if ask "$tool is installed. Use the repo's $config?"; then
            return 0
        fi
        log "skip   $tool"
        return 1
    fi

    if ! ask "$tool is not installed. Install it and use the repo's $config?"; then
        log "skip   $tool"
        return 1
    fi
    if [ "$tool" = "oh-my-zsh" ]; then
        install_omz || return 1
    else
        pkg_install "$tool" || return 1
    fi
    [ "$DRY_RUN" -eq 1 ] || installed "$tool"
}

# --- linking -------------------------------------------------------------------
link() {
    local src="$REPO_DIR/$1" dest="$2"

    if [ ! -e "$src" ]; then
        log "skip   $1 (not in repo)"
        return
    fi

    if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
        log "ok     $dest"
        return
    fi

    if [ "$DRY_RUN" -eq 1 ]; then
        log "would  link $dest -> $src"
        return
    fi

    mkdir -p "$(dirname "$dest")"
    if [ -e "$dest" ] || [ -L "$dest" ]; then
        mv "$dest" "$dest.backup-$STAMP"
        log "backup $dest -> $dest.backup-$STAMP"
    fi
    ln -s "$src" "$dest"
    log "link   $dest -> $src"
}

# hook_rc <file>: make an rc file this repo does not own load the shared shell
# profile, by appending a marked block once.
HOOK_MARKER="# configs: load the shared shell profile"
hook_rc() {
    local rc="$1"

    # The rc file already is one of the repo's (from an earlier install).
    if [ -L "$rc" ]; then
        case "$(readlink "$rc")" in
            "$REPO_DIR"/*) log "ok     $rc"; return ;;
        esac
    fi

    if [ -f "$rc" ] && grep -qF "$HOOK_MARKER" "$rc"; then
        log "ok     $rc"
        return
    fi

    if [ "$DRY_RUN" -eq 1 ]; then
        log "would  hook $rc"
        return
    fi

    printf '\n%s\nexport CONFIGS_DIR="%s"\n. "$CONFIGS_DIR/shared/shell/profile.sh"\n' \
        "$HOOK_MARKER" "$REPO_DIR" >> "$rc"
    log "hook   $rc"
}

# create_local <file> <template>: write an untracked, machine-local file once.
GITCONFIG_LOCAL_CREATED=0
create_local() {
    local file="$1" template="$2"

    [ -f "$file" ] && return
    if [ "$DRY_RUN" -eq 1 ]; then
        log "would  create $file"
        return
    fi
    mkdir -p "$(dirname "$file")"
    printf '%s\n' "$template" > "$file"
    log "create $file"
    [ "$file" = "$HOME/.gitconfig.local" ] && GITCONFIG_LOCAL_CREATED=1
    return 0
}

# --- 1. questions and installs -----------------------------------------------
log "Setting up $OS from $REPO_DIR"
[ "$DRY_RUN" -eq 1 ] && log "(dry run: nothing will be changed)"
if [ "$OS" = "macos" ] && ! has brew; then
    load_brew || true
fi
log ""

USE_GIT=0; want git       "git config (aliases, push/pull defaults, global gitignore)" && USE_GIT=1
USE_VIM=0; want vim       "vim config"                                                && USE_VIM=1
USE_OMZ=0; want oh-my-zsh "zsh config (oh-my-zsh, theme, plugins)"                    && USE_OMZ=1

if [ "$OS" = "macos" ] && ask "Install the Homebrew packages and apps from the Brewfile?"; then
    if ensure_brew; then
        run brew bundle --file="$REPO_DIR/macos/homebrew/Brewfile"
    fi
fi

USE_AEROSPACE=0
USE_LINEARMOUSE=0
if [ "$OS" = "macos" ]; then
    if { has aerospace || [ -d /Applications/AeroSpace.app ]; } &&
       ask "AeroSpace is installed. Use the repo's AeroSpace config?"; then
        USE_AEROSPACE=1
    fi
    if [ -d /Applications/LinearMouse.app ] &&
       ask "LinearMouse is installed. Use the repo's LinearMouse config?"; then
        USE_LINEARMOUSE=1
    fi
fi

# With oh-my-zsh set up, offer zsh as the login shell too.
if [ "$USE_OMZ" -eq 1 ] && [ "$(basename "${SHELL:-}")" != "zsh" ] &&
   ask "Make zsh your default shell?"; then
    run chsh -s "$(command -v zsh || echo /bin/zsh)"
fi

# --- 2. config ----------------------------------------------------------------
log ""

# Shell: always. With oh-my-zsh chosen, zsh gets the repo's zshrc; otherwise
# the existing rc files are kept and just load the shared profile.
if [ "$USE_OMZ" -eq 1 ]; then
    link "$OS/zsh/zshrc" "$HOME/.zshrc"
    if [ "$OS" = "macos" ]; then
        link macos/zsh/zshenv "$HOME/.zshenv"
    fi
elif installed zsh; then
    hook_rc "$HOME/.zshrc"
fi
if ! installed zsh || [ "$(basename "${SHELL:-}")" = "bash" ]; then
    if [ "$OS" = "macos" ]; then
        hook_rc "$HOME/.bash_profile"
    else
        hook_rc "$HOME/.bashrc"
    fi
fi
create_local "$HOME/.shell.local" "\
# Machine-local shell settings: credentials, work-only aliases, per-host paths.
# This file is intentionally NOT tracked in the configs repo.

# Namespace-to-service mapping used by kpod(), as <namespace-substring>:<service>:
# export KPOD_SERVICE_MAP='api:api-server,web:web-frontend'"

if [ "$USE_GIT" -eq 1 ]; then
    link shared/git/gitconfig        "$HOME/.gitconfig"
    link shared/git/gitignore_global "$HOME/.gitignore_global"
    create_local "$HOME/.gitconfig.local" "\
[user]
	name = Your Name
	email = you@example.com"
fi

if [ "$USE_VIM" -eq 1 ]; then
    link shared/vim/vimrc                          "$HOME/.vimrc"
    link shared/vim/ftplugin/c.vim                 "$HOME/.vim/ftplugin/c.vim"
    link shared/vim/ftplugin/gitcommit.vim         "$HOME/.vim/ftplugin/gitcommit.vim"
    link shared/vim/templates/template.c           "$HOME/.vim/templates/template.c"
    link shared/vim/templates/solution_template.py "$HOME/.vim/templates/solution_template.py"
fi

if [ "$USE_AEROSPACE" -eq 1 ]; then
    link macos/aerospace/aerospace.toml         "$HOME/.aerospace.toml"
    link macos/aerospace/route-chrome.sh        "$HOME/.config/aerospace/route-chrome.sh"
    link macos/aerospace/watch-window-titles.sh "$HOME/.config/aerospace/watch-window-titles.sh"
    create_local "$HOME/.config/aerospace/local.env" "\
# Machine-local AeroSpace window-routing patterns.
# This file is intentionally NOT tracked in the configs repo.

# Title suffix that identifies your work Chrome profile, e.g.
# CHROME_WORK_PROFILE_SUFFIX=' - Google Chrome - Work Profile Name'
CHROME_WORK_PROFILE_SUFFIX=''

# Extra title patterns, as extended regular expressions.
# CHROME_MEETING_REGEX='(Google Meet|Calendar)'
# TERM_LOG_REGEX='(docker compose.*logs|kubectl.*logs|stern|tail -f|logs)'"
fi

if [ "$USE_LINEARMOUSE" -eq 1 ]; then
    link macos/linearmouse/linearmouse.json "$HOME/.config/linearmouse/linearmouse.json"
fi

# --- 3. next steps ------------------------------------------------------------
log ""
log "Done. Next steps:"
if [ "$GITCONFIG_LOCAL_CREATED" -eq 1 ]; then
    log "  - put your name and email in ~/.gitconfig.local"
fi
if [ "$USE_OMZ" -eq 1 ] && [ "$REPO_DIR" != "$HOME/configs" ]; then
    log "  - the repo's zshrc expects it at ~/configs: move it there, or export"
    log "    CONFIGS_DIR=\"$REPO_DIR\" before zsh starts"
fi
log "  - restart your shell"

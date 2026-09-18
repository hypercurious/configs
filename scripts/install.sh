#!/usr/bin/env bash
# Bootstrap a machine from this repo.
#
#   ./scripts/install.sh            # detect OS, link shared + OS-specific config
#   ./scripts/install.sh --dry-run  # show what would happen
#
# Existing files are backed up to <path>.backup-<timestamp> before being
# replaced with a symlink into this repo.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STAMP="$(date +%Y%m%d%H%M%S)"
DRY_RUN=0

[ "${1:-}" = "--dry-run" ] && DRY_RUN=1

case "$(uname -s)" in
    Darwin) OS="macos" ;;
    Linux)  OS="linux" ;;
    *)      echo "Unsupported OS: $(uname -s). On Windows run windows/install.ps1." >&2; exit 1 ;;
esac

log() { printf '%s\n' "$*"; }

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
        log "would  $dest -> $src"
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

# --- shared (all operating systems) ----------------------------------------
link shared/vim/vimrc                            "$HOME/.vimrc"
link shared/vim/ftplugin/c.vim                   "$HOME/.vim/ftplugin/c.vim"
link shared/vim/ftplugin/gitcommit.vim           "$HOME/.vim/ftplugin/gitcommit.vim"
link shared/vim/templates/template.c             "$HOME/.vim/templates/template.c"
link shared/vim/templates/solution_template.py   "$HOME/.vim/templates/solution_template.py"
link shared/git/gitconfig                        "$HOME/.gitconfig"
link shared/git/gitignore_global                 "$HOME/.gitignore_global"

# --- OS-specific ------------------------------------------------------------
link "$OS/zsh/zshrc" "$HOME/.zshrc"
if [ "$OS" = "macos" ]; then
    link macos/zsh/zshenv                        "$HOME/.zshenv"
    link macos/aerospace/aerospace.toml          "$HOME/.aerospace.toml"
    link macos/aerospace/route-chrome.sh         "$HOME/.config/aerospace/route-chrome.sh"
    link macos/aerospace/watch-window-titles.sh  "$HOME/.config/aerospace/watch-window-titles.sh"
    link macos/linearmouse/linearmouse.json      "$HOME/.config/linearmouse/linearmouse.json"
fi

# --- machine-local files (never tracked) ------------------------------------
if [ "$DRY_RUN" -eq 0 ]; then
    if [ ! -f "$HOME/.gitconfig.local" ]; then
        cat > "$HOME/.gitconfig.local" <<'TEMPLATE'
[user]
	name = Your Name
	email = you@example.com
TEMPLATE
        log "created $HOME/.gitconfig.local (fill in your identity)"
    fi

    if [ ! -f "$HOME/.shell.local" ]; then
        cat > "$HOME/.shell.local" <<'TEMPLATE'
# Machine-local shell settings: credentials, work-only aliases, per-host paths.
# This file is intentionally NOT tracked in the configs repo.

# Namespace-to-service mapping used by kpod(), as <namespace-substring>:<service>:
# export KPOD_SERVICE_MAP='api:api-server,web:web-frontend'
TEMPLATE
        log "created $HOME/.shell.local"
    fi

    if [ "$OS" = "macos" ] && [ ! -f "$HOME/.config/aerospace/local.env" ]; then
        mkdir -p "$HOME/.config/aerospace"
        cat > "$HOME/.config/aerospace/local.env" <<'TEMPLATE'
# Machine-local AeroSpace window-routing patterns.
# This file is intentionally NOT tracked in the configs repo.

# Title suffix that identifies your work Chrome profile, e.g.
# CHROME_WORK_PROFILE_SUFFIX=' - Google Chrome - Work Profile Name'
CHROME_WORK_PROFILE_SUFFIX=''

# Extra title patterns, as extended regular expressions.
# CHROME_MEETING_REGEX='(Google Meet|Calendar)'
# TERM_LOG_REGEX='(docker compose.*logs|kubectl.*logs|stern|tail -f|logs)'
TEMPLATE
        log "created $HOME/.config/aerospace/local.env"
    fi
fi

log ""
log "Done. Next steps:"
log "  - fill in ~/.gitconfig.local and ~/.shell.local"
if [ "$OS" = "macos" ]; then
    log "  - install packages:  brew bundle --file=$REPO_DIR/macos/homebrew/Brewfile"
fi
log "  - oh-my-zsh (if missing): sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\""
log "  - restart your shell"

# Shared, OS-agnostic shell environment.
# Sourced by the per-OS zshrc/bashrc after OS-specific PATH setup.

export EDITOR=vim
export VISUAL=vim
export PAGER=less
export LESS='-R'

export HISTSIZE=50000
export SAVEHIST=50000

CONFIGS_DIR="${CONFIGS_DIR:-$HOME/configs}"

[ -f "$CONFIGS_DIR/shared/shell/aliases.sh" ]   && . "$CONFIGS_DIR/shared/shell/aliases.sh"
[ -f "$CONFIGS_DIR/shared/shell/functions.sh" ] && . "$CONFIGS_DIR/shared/shell/functions.sh"

# Machine-local settings: secrets, per-host paths, work-only aliases.
# Never tracked in this repo.
[ -f "$HOME/.shell.local" ] && . "$HOME/.shell.local"

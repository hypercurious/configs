# Shared shell aliases (POSIX-compatible; sourced by bash and zsh on any OS).

alias ll='ls -la'
alias la='ls -A'
alias ..='cd ..'
alias ...='cd ../..'

alias g='git'
alias gs='git status --short --branch'
alias gd='git diff'
alias gl='git log --oneline --graph --decorate'

command -v bat >/dev/null 2>&1 && alias cat='bat --paging=never'

alias k='kubectl'

# Edit the configs that matter most.
alias rc='vim ~/.vimrc'

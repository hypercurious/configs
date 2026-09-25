# Shared shell aliases (POSIX-compatible; sourced by bash and zsh on any OS).

alias ll='ls -lah'
alias lt='ls -laht'
alias ltr='ls -lahtr'
alias la='ls -A'
alias ..='cd ..'
alias ...='cd ../..'
alias clr='clear'
alias cll='clear && ll'

# Let aliases expand after sudo.
alias sudo='sudo '

alias g='git'
alias gs='git status --short --branch'
alias gd='git diff'
alias gl='git log --oneline --graph --decorate'

command -v bat >/dev/null 2>&1 && alias cat='bat --paging=never'

alias k='kubectl'

# docker compose
alias dps='docker compose ps'
alias up='docker compose up -d'
alias upbuild='up --build'
alias down='docker compose down'
alias downup='down && up'
alias start='docker compose start'
alias stop='docker compose stop'
alias restart='docker compose restart'
alias pull='docker compose pull'
alias logs='docker compose logs -t -f --tail 150'

# python
alias py='python3'
alias pyv='cd && py -m venv temp && source temp/bin/activate'

# Edit the configs that matter most.
alias rc='vim ~/.zshrc'
alias src='source ~/.zshrc && echo .zshrc refreshed successfully'
alias vrc='vim ~/.vimrc'
alias al='vim "$CONFIGS_DIR/shared/shell/aliases.sh"'
alias sal='source "$CONFIGS_DIR/shared/shell/aliases.sh" && echo shared/shell/aliases.sh refreshed successfully'
alias h='sudoedit /etc/hosts'

# clipboard
alias copy='clipcopy'
alias uuid='uuidgen | copy'

# Open a path (default: current directory) in VS Code and close the terminal.
alias c='_c(){ if [[ $# -eq 0  ]]; then code . && exit; else code "$1" && exit; fi;}; _c'

# personal scripts
alias caps='py ~/caps_lock.py'
alias otp='pyv && python3 ~/otps/otp.py'
alias ookla='_ookla(){ cd ~/Desktop/speedtest && speedtest -f json-pretty > "$1"_speedtest.json;}; _ookla'
alias aoc='cd $HOME/scripts/advent-of-code/'

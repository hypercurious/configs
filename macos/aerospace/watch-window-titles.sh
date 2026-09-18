#!/bin/bash
# Continuously re-route Chrome and iTerm2 windows to workspaces based on their
# titles, for cases where the one-shot on-window-detected rules are not enough
# (titles that change after the window opens).
#
# Site-specific title patterns live in ~/.config/aerospace/local.env, which is
# not tracked in the configs repo. Recognised variables:
#
#   CHROME_WORK_PROFILE_SUFFIX  title suffix identifying the work profile
#   CHROME_MEETING_REGEX        titles treated as calendar/meeting windows
#   TERM_LOG_REGEX              terminal titles treated as log windows

shopt -s nocasematch

# shellcheck source=/dev/null
[ -f "$HOME/.config/aerospace/local.env" ] && . "$HOME/.config/aerospace/local.env"

CHROME_MEETING_REGEX="${CHROME_MEETING_REGEX:-(Google Meet|Calendar)}"
CHROME_WORK_PROFILE_SUFFIX="${CHROME_WORK_PROFILE_SUFFIX:-}"
TERM_LOG_REGEX="${TERM_LOG_REGEX:-(docker compose.*logs|kubectl.*logs|stern|tail -f|logs)}"

AEROSPACE="$(command -v aerospace 2>/dev/null || true)"

if [[ -z "$AEROSPACE" ]]; then
    exit 1
fi

PID_FILE="/tmp/aerospace-window-router-${UID}.pid"
LOG_FILE="/tmp/aerospace-router.log"

if [[ -f "$PID_FILE" ]]; then
    old_pid="$(cat "$PID_FILE" 2>/dev/null)"

    if [[ -n "$old_pid" ]] && kill -0 "$old_pid" 2>/dev/null; then
        exit 0
    fi
fi

echo "$$" > "$PID_FILE"
trap 'rm -f "$PID_FILE"' EXIT INT TERM

while true; do
    "$AEROSPACE" list-windows --all \
        --format $'%{window-id}\t%{app-bundle-id}\t%{workspace}\t%{window-title}' |
    while IFS=$'\t' read -r window_id bundle_id workspace title; do
        target_workspace=""

        case "$bundle_id" in
            com.google.Chrome)
                # Perimene na yparxei kanonikos Chrome title.
                [[ "$title" != *"Google Chrome"* ]] && continue

                # Calendar / Meet -> workspace 3
                if printf '%s' "$title" | grep -qE "$CHROME_MEETING_REGEX"; then

                    target_workspace="3"

                # Work profile -> workspace 2
                elif [[ -n "$CHROME_WORK_PROFILE_SUFFIX" &&
                        "$title" == *"$CHROME_WORK_PROFILE_SUFFIX" ]]; then

                    target_workspace="2"

                # Personal kai ola ta alla Chrome profiles -> workspace 4
                else
                    target_workspace="4"
                fi
                ;;

            com.googlecode.iterm2)
                # Log / tail windows -> workspace 5
                if printf '%s' "$title" | grep -qE "$TERM_LOG_REGEX"; then
                    target_workspace="5"
                fi
                ;;
        esac

        if [[ -n "$target_workspace" &&
              "$workspace" != "$target_workspace" ]]; then

            printf '%s | %s | %s -> %s | %s\n' \
                "$(date '+%Y-%m-%d %H:%M:%S')" \
                "$bundle_id" \
                "$workspace" \
                "$target_workspace" \
                "$title" \
                >> "$LOG_FILE"

            "$AEROSPACE" move-node-to-workspace \
                --window-id "$window_id" \
                "$target_workspace" \
                >/dev/null 2>&1
        fi
    done

    sleep 0.5
done

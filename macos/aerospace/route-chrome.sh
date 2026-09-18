#!/bin/bash
# Route a newly opened Chrome window to a workspace based on its title.
#
# Site-specific title patterns live in ~/.config/aerospace/local.env, which is
# not tracked in the configs repo. Recognised variables:
#
#   CHROME_WORK_PROFILE_SUFFIX  title suffix identifying the work profile
#                               (e.g. ' - Google Chrome - Work Profile Name')
#   CHROME_MEETING_REGEX        titles treated as calendar/meeting windows
#
# With no local.env present, meeting windows go to workspace 3 and everything
# else to workspace 4.

shopt -s nocasematch

# shellcheck source=/dev/null
[ -f "$HOME/.config/aerospace/local.env" ] && . "$HOME/.config/aerospace/local.env"

CHROME_MEETING_REGEX="${CHROME_MEETING_REGEX:-(Google Meet|Calendar)}"
CHROME_WORK_PROFILE_SUFFIX="${CHROME_WORK_PROFILE_SUFFIX:-}"

AEROSPACE="$(command -v aerospace 2>/dev/null || true)"
window_id="${AEROSPACE_WINDOW_ID:-${1:-}}"

if [[ -z "$AEROSPACE" || -z "$window_id" ]]; then
    exit 0
fi

title=""

# Perimene mexri o Chrome na arxikopoiisei ton teliko title.
for _ in {1..20}; do
    title="$(
        "$AEROSPACE" echo \
            --window-id "$window_id" \
            -- '%{window-title}' 2>/dev/null
    )" || exit 0

    if [[ "$title" == *"Google Chrome"* ]]; then
        break
    fi

    sleep 0.25
done

# Calendar / Meet -> workspace 3
if printf '%s' "$title" | grep -qE "$CHROME_MEETING_REGEX"; then

    target_workspace="3"

# Work profile -> workspace 2
elif [[ -n "$CHROME_WORK_PROFILE_SUFFIX" && "$title" == *"$CHROME_WORK_PROFILE_SUFFIX" ]]; then

    target_workspace="2"

# Personal kai ola ta alla Chrome profiles -> workspace 4
else
    target_workspace="4"
fi

printf '%s | %s | workspace %s\n' \
    "$(date '+%Y-%m-%d %H:%M:%S')" \
    "$title" \
    "$target_workspace" \
    >> /tmp/aerospace-router.log

"$AEROSPACE" move-node-to-workspace \
    --window-id "$window_id" \
    "$target_workspace"

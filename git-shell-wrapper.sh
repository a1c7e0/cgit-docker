#!/bin/bash
BASE="/var/lib/git"

# Extract command: prefer -c flag, fall back to SSH_ORIGINAL_COMMAND
if [ "$1" = "-c" ] && [ $# -ge 2 ]; then
    CMD="$2"
else
    CMD="$SSH_ORIGINAL_COMMAND"
fi

if [[ "$CMD" =~ ^git-(receive|upload)-pack\ \'(.+)\'$ ]]; then
    GIT_CMD="${BASH_REMATCH[1]}"
    RAW="${BASH_REMATCH[2]}"
    RAW="${RAW#/}"

    # Resolve repo path: try exact name first, then strip .git suffix
    FINAL="$BASE/$RAW"
    if [ ! -d "$FINAL" ]; then
        STRIPPED="${RAW%.git}"
        if [ "$STRIPPED" != "$RAW" ] && [ -d "$BASE/$STRIPPED" ]; then
            FINAL="$BASE/$STRIPPED"
        fi
    fi

    # Auto-create on push if repo doesn't exist
    if [ "$GIT_CMD" = "receive" ] && [ ! -d "$FINAL" ]; then
        mkdir -p "$(dirname "$FINAL")" 2>/dev/null
        git init --bare "$FINAL" >/dev/null 2>&1
        git -C "$FINAL" symbolic-ref HEAD refs/heads/main 2>/dev/null
        git -C "$FINAL" config http.uploadpack true 2>/dev/null
        OWNER=$(cat /var/lib/git/.owner_name 2>/dev/null)
        [ -n "$OWNER" ] && git -C "$FINAL" config gitweb.owner "$OWNER" 2>/dev/null
        chown -R git:git "$FINAL" 2>/dev/null
    fi

    CMD="git-${GIT_CMD}-pack '$FINAL'"
fi

exec git-shell -c "$CMD"

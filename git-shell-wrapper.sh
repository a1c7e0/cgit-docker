#!/bin/bash
BASE="/var/lib/git"

CMD=""
for arg in "$@"; do
    [ "$arg" = "-c" ] && shift && CMD="$1" && break
    shift
done
[ -z "$CMD" ] && CMD="$SSH_ORIGINAL_COMMAND"

if echo "$CMD" | grep -qE "^git-(receive|upload)-pack "; then
    GIT_CMD=$(echo "$CMD" | grep -oE "^git-(receive|upload)-pack")
    RAW=$(echo "$CMD" | cut -d"'" -f2)
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
    if [ "$GIT_CMD" = "git-receive-pack" ] && [ ! -d "$FINAL" ]; then
        mkdir -p "$(dirname "$FINAL")" 2>/dev/null
        git init --bare "$FINAL" >/dev/null 2>&1
        git -C "$FINAL" symbolic-ref HEAD refs/heads/main 2>/dev/null
        git -C "$FINAL" config http.uploadpack true 2>/dev/null
        chown -R git:git "$FINAL" 2>/dev/null
    fi

    CMD="$GIT_CMD '$FINAL'"
fi

exec git-shell -c "$CMD"

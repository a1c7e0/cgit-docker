#!/bin/bash
# Poll /secrets/authorized_keys and sync to /home/git/.ssh/
SRC=/secrets/authorized_keys
DST=/home/git/.ssh/authorized_keys
CHECKSUM=""

mkdir -p /home/git/.ssh
chown git:git /home/git/.ssh
chmod 700 /home/git/.ssh

# Initial sync
if [ -f "$SRC" ]; then
    cp "$SRC" "$DST"
    chown git:git "$DST"
    chmod 600 "$DST"
    CHECKSUM=$(md5sum "$SRC" | cut -d' ' -f1)
    echo "[sync-keys] initial sync done, checksum=$CHECKSUM"
else
    echo "[sync-keys] WARNING: $SRC not found, waiting..."
fi

# Poll every 3 seconds
while true; do
    sleep 3
    [ -f "$SRC" ] || { echo "[sync-keys] $SRC still missing"; continue; }
    NEW=$(md5sum "$SRC" | cut -d' ' -f1)
    [ "$NEW" = "$CHECKSUM" ] && continue
    cp "$SRC" "$DST"
    chown git:git "$DST"
    chmod 600 "$DST"
    echo "[sync-keys] synced, old=$CHECKSUM new=$NEW"
    CHECKSUM="$NEW"
done

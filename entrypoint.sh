#!/bin/bash
set -e

chmod +x /home/git/git-shell-wrapper \
         /home/git/sync-keys.sh \
         /var/www/cgit/filters/about-formatting.sh \
         /var/www/cgit/filters/syntax-highlighting.py \
         /var/www/cgit/filters/html-converters/*

# Persist OWNER_NAME for SSH sessions (git-shell-wrapper)
[ -n "$OWNER_NAME" ] && echo "$OWNER_NAME" > /var/lib/git/.owner_name

mkdir -p /var/cache/cgit /var/lib/git /home/git/.ssh
chown -R git:git /var/lib/git /var/cache/cgit

git config --global --add safe.directory '*'

chmod 700 /home/git/.ssh

# SSH host keys: use from /secrets/ssh if available, else generate and persist
if [ -f /secrets/ssh/ssh_host_ed25519_key ]; then
    for f in /secrets/ssh/ssh_host_*; do
        cp "$f" /etc/ssh/
    done
    echo "[init] SSH keys loaded from /secrets/ssh"
else
    ssh-keygen -A 2>/dev/null
    mkdir -p /secrets/ssh
    for f in /etc/ssh/ssh_host_*; do
        cp "$f" /secrets/ssh/
    done
    echo "[init] SSH keys generated and saved to /secrets/ssh"
fi

if [ ! -f /secrets/authorized_keys ]; then
    touch /secrets/authorized_keys
fi

for repo in /var/lib/git/*/; do
    [ -d "$repo" ] || continue
    git -C "$repo" config http.uploadpack true 2>/dev/null || true
    if [ -n "$OWNER_NAME" ] && [ -z "$(git -C "$repo" config --get gitweb.owner 2>/dev/null)" ]; then
        git -C "$repo" config gitweb.owner "$OWNER_NAME" 2>/dev/null || true
    fi
done

echo "[init] Starting authorized_keys watcher..."
/home/git/sync-keys.sh &

echo "[init] Starting..."
spawn-fcgi -s /run/fcgiwrap.sock -U nginx -G nginx -- /usr/bin/fcgiwrap
/usr/sbin/sshd
exec nginx -g 'daemon off;'

#!/usr/bin/env bash
set -euo pipefail

# Bind-mount /var/lib/nix-store to /nix.
# If /var/lib/nix-store is empty, seed it from the baked store in /usr/share/nix-store.

mkdir -p /usr/share/nix-store /var/lib/nix-store /nix

copy_seed_store() {
  if command -v rsync >/dev/null 2>&1; then
    rsync -aH --delete /usr/share/nix-store/ /var/lib/nix-store/
  else
    cp -a /usr/share/nix-store/. /var/lib/nix-store/
  fi
}

if ! mountpoint -q /nix; then
  if [ -z "$(ls -A /var/lib/nix-store 2>/dev/null)" ] && compgen -G "/usr/share/nix-store/*" >/dev/null; then
    copy_seed_store
  fi

  mount --bind /var/lib/nix-store /nix
  mount -o remount,bind,exec /nix

  # Ensure daemon paths exist and labels are sane.
  if command -v systemd-tmpfiles >/dev/null 2>&1; then
    systemd-tmpfiles --create /usr/lib/tmpfiles.d/nix-daemon.conf
  fi
  if command -v restorecon >/dev/null 2>&1; then
    restorecon -RF /var/lib/nix-store /nix || true
  fi
fi

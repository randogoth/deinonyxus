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

sync_missing_store() {
  # Ensure any baked store paths exist in /var without clobbering user additions.
  if command -v rsync >/dev/null 2>&1; then
    rsync -aH --ignore-existing /usr/share/nix-store/store/ /var/lib/nix-store/store/
  fi
}

ensure_system_profile() {
  local seed_profile="/usr/share/nix-store/var/nix/profiles/system"
  local target_profile="/var/lib/nix-store/var/nix/profiles/system"

  mkdir -p /var/lib/nix-store/var/nix/profiles

  if { [ ! -e "$target_profile" ] || [ -L "$target_profile" ] && [ ! -e "$(readlink -f "$target_profile")" ]; } \
     && { [ -e "$seed_profile" ] || [ -L "$seed_profile" ]; }; then
    cp -a "$seed_profile" "$target_profile"
  fi
}

if ! mountpoint -q /nix; then
  if [ -z "$(ls -A /var/lib/nix-store 2>/dev/null)" ] && compgen -G "/usr/share/nix-store/*" >/dev/null; then
    copy_seed_store
  fi

  ensure_system_profile
  sync_missing_store

  mount --bind /var/lib/nix-store /nix
  # Force an executable SELinux context on the bind mount so systemd can exec nix-daemon.
  # Use a permissive fallback if the label option is rejected.
  if ! mount -o remount,bind,exec,context=system_u:object_r:bin_t:s0 /nix 2>/dev/null; then
    mount -o remount,bind,exec /nix
  fi

  # Ensure daemon paths exist and labels are sane.
  if command -v systemd-tmpfiles >/dev/null 2>&1; then
    systemd-tmpfiles --create /usr/lib/tmpfiles.d/nix-daemon.conf
  fi
  if command -v restorecon >/dev/null 2>&1; then
    restorecon -RF /var/lib/nix-store /nix || true
  fi
fi

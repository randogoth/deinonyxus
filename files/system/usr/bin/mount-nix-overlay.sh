#!/usr/bin/env bash
set -euo pipefail

mkdir -p /usr/share/nix-store /var/lib/nix-store /var/cache/nix-store /nix

# Skip if already mounted to avoid errors on reload.
if mountpoint -q /nix; then
  exit 0
fi

mount -t overlay overlay \
  -o lowerdir=/usr/share/nix-store,upperdir=/var/lib/nix-store,workdir=/var/cache/nix-store \
  /nix

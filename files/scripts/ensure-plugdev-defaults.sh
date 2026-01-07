#!/usr/bin/env bash
set -euo pipefail

# Ensure new users are added to plugdev by default so OpenRazer udev rules work.
useradd_defaults=/etc/default/useradd
plugdev_group=plugdev

touch "$useradd_defaults"

if ! grep -q "^GROUPS=" "$useradd_defaults"; then
  printf 'GROUPS=%s\n' "$plugdev_group" >>"$useradd_defaults"
elif ! grep -Eq "^GROUPS=.*\\b${plugdev_group}\\b" "$useradd_defaults"; then
  # Append plugdev to any existing GROUPS setting.
  sed -i "s/^GROUPS=\\(.*\\)/GROUPS=\\1 ${plugdev_group}/" "$useradd_defaults"
fi

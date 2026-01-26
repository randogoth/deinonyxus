#!/bin/bash
set -euo pipefail

target="/etc/xdg/labwc/autostart"

if [ ! -x "$target" ]; then
  echo "labwc autostart missing or not executable: $target" >&2
  exit 1
fi

if ! grep -q "import-environment" "$target"; then
  echo "labwc autostart present but missing environment import: $target" >&2
  exit 1
fi

echo "labwc autostart present and executable: $target"

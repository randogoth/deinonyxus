#!/bin/sh
set -e
export PATH="/usr/bin:$PATH"
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

dest="$HOME/.config/labwc/menu.xml"
mkdir -p "$(dirname "$dest")"
export GHOSTTY_BIN="/usr/bin"
export DISTROBOX_BIN="/usr/bin"
export DBX_PATH="/usr/bin:/usr/local/bin"
export DMS_BIN="/usr/bin/dms"
export DMS_PATH="/usr/bin"

desired_logout="killall -s SIGTERM labwc"

# Ensure rc.xml points to the generated menu/theme if it doesn't already.
rc="$HOME/.config/labwc/rc.xml"
mkdir -p "$(dirname "$rc")"
cp -f /usr/share/dms/labwc-rc.xml "$rc"
settings_dir="$HOME/.config/DankMaterialShell"
settings_file="$settings_dir/settings.json"
mkdir -p "$settings_dir"
python3 - "$settings_file" "$desired_logout" <<'PY'
import json, sys, os
settings_path = sys.argv[1]
desired = sys.argv[2]
data = {}
if os.path.exists(settings_path):
    try:
        with open(settings_path, "r") as f:
            data = json.load(f)
    except Exception:
        data = {}
if data.get("customPowerActionLogout") != desired:
    data["customPowerActionLogout"] = desired
    os.makedirs(os.path.dirname(settings_path), exist_ok=True)
    with open(settings_path, "w") as f:
        json.dump(data, f, indent=2)
PY
cp -f /usr/share/dms/labwc-rc.xml "$rc"

tmp="$(mktemp)"
/usr/bin/labwc-menu-generator \
  --no-duplicates \
  --terminal-prefix "${GHOSTTY_BIN}/ghostty -e" \
  > "$tmp"

# Build final menu from the generator output, injecting DMS Settings and relocating distrobox desktop entries.
/usr/bin/python3 "${SCRIPT_DIR}/labwc-menu-postprocess.py" "$tmp" "$dest"

rm -f "$tmp"

# Reload labwc so the updated menu is picked up
if command -v labwc >/dev/null && pgrep -u "$UID" -x labwc >/dev/null; then
  labwc -r || true
fi

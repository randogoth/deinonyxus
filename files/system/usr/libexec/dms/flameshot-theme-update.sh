#!/bin/sh
# Sync Flameshot colors with current DMS palette.
set -e

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"
colors_json="$HOME/.cache/DankMaterialShell/dms-colors.json"
flameshot_ini="$config_dir/flameshot/flameshot.ini"
skel_flameshot_ini="/etc/skel/.config/flameshot/flameshot.ini"

mkdir -p "$(dirname "$flameshot_ini")"

# Seed the user config from /etc/skel if it doesn't exist yet.
if [ ! -f "$flameshot_ini" ] && [ -f "$skel_flameshot_ini" ]; then
  cp "$skel_flameshot_ini" "$flameshot_ini"
fi

# Ensure we have a config file even if the skel copy is missing.
if [ ! -f "$flameshot_ini" ]; then
  cat > "$flameshot_ini" <<'EOF'
[General]
uiLanguage=auto
EOF
fi

[ -f "$colors_json" ] || exit 0

primary=$(jq -r '.colors.dark.primary // empty' "$colors_json")
on_primary=$(jq -r '.colors.dark.on_primary // empty' "$colors_json")

# Fallbacks if JSON fields are missing.
[ -n "$primary" ] || primary="#d0bcff"
[ -n "$on_primary" ] || on_primary="#381e72"

python3 - "$flameshot_ini" "$primary" "$on_primary" <<'PY'
import sys
from configparser import ConfigParser

ini_path, primary, on_primary = sys.argv[1:]
config = ConfigParser(delimiters=('='), interpolation=None)
config.optionxform = str
config.read(ini_path, encoding="utf-8")

if "General" not in config:
    config["General"] = {}

general = config["General"]
general["uiColor"] = primary
general["contrastUiColor"] = on_primary
general["drawColor"] = primary
general["contrastOpacity"] = "188"

with open(ini_path, "w", encoding="utf-8") as f:
    config.write(f, space_around_delimiters=False)
PY

#!/bin/sh
# Sync Flameshot colors with current DMS palette.
set -e

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"
colors_json="$HOME/.cache/DankMaterialShell/dms-colors.json"
flameshot_ini="$config_dir/flameshot/flameshot.ini"

[ -f "$colors_json" ] || exit 0

mkdir -p "$(dirname "$flameshot_ini")"

primary=$(jq -r '.colors.dark.primary // empty' "$colors_json")
on_primary=$(jq -r '.colors.dark.on_primary // empty' "$colors_json")
surface_variant=$(jq -r '.colors.dark.surface_variant // empty' "$colors_json")

# Fallbacks if JSON fields are missing.
[ -n "$primary" ] || primary="#d0bcff"
[ -n "$on_primary" ] || on_primary="#381e72"
[ -n "$surface_variant" ] || surface_variant="#49454e"

cat > "$flameshot_ini" <<EOF
[General]
useGrimAdapter=true
autoCloseIdleDaemon=true
startupLaunch=true
saveAsFileExtension=jpg
# DMS-synced colors
uiColor=${primary}
contrastUiColor=${on_primary}
drawColor=${primary}
contrastOpacity=188
uiLanguage=auto
# Optional accent on selection/toolbar backgrounds
buttonColor=${surface_variant}
EOF

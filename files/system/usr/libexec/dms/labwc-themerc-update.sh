#!/bin/sh
set -e
export PATH="/usr/bin:/run/current-system/sw/bin:$PATH"

colors_json="$HOME/.cache/DankMaterialShell/dms-colors.json"
[ -f "$colors_json" ] || exit 0

primary=$(jq -r '.colors.dark.primary // empty' "$colors_json")
on_primary=$(jq -r '.colors.dark.on_primary // empty' "$colors_json")
surface=$(jq -r '.colors.dark.surface // empty' "$colors_json")
surface_variant=$(jq -r '.colors.dark.surface_variant // empty' "$colors_json")
on_surface=$(jq -r '.colors.dark.on_surface // empty' "$colors_json")
outline=$(jq -r '.colors.dark.outline // empty' "$colors_json")

# Update Ghostty background to match the DMS surface color without overwriting other settings.
ghostty_cfg="$HOME/.config/ghostty/config"
mkdir -p "$(dirname "$ghostty_cfg")"
if [ -f "$ghostty_cfg" ]; then
  perl -ni -e 'print unless /\\n/' "$ghostty_cfg"
fi
if [ -f "$ghostty_cfg" ] && grep -q '^background[[:space:]]*=' "$ghostty_cfg"; then
  sed -i "s/^background[[:space:]]*=.*/background = ${surface}/" "$ghostty_cfg"
else
  printf '\n# Set by labwc-themerc-update from DMS colors\nbackground = %s\n' "$surface" >> "$ghostty_cfg"
fi

theme_dir="$HOME/.themes/dms-labwc/openbox-3"
mkdir -p "$theme_dir"
cat > "$theme_dir/themerc" <<EOF
# Auto-generated from DMS colors
border.width: 1
          border.color: ${outline}
          padding.height: 6
          corner.radius: 6
          window.titlebar.padding.height: 4
          window.titlebar.padding.width: 8
          window.label.text.justify: center

          window.button.height: 20
          window.button.width: 28
          window.button.spacing: 2

          window.active.title.bg.color: ${surface_variant}
          window.active.label.text.color: ${on_surface}
          window.active.button.unpressed.bg.color: ${surface_variant}
          window.active.button.pressed.bg.color: ${primary}
          window.active.button.unpressed.image.color: ${on_surface}
          window.active.button.pressed.image.color: ${on_primary}

          window.inactive.title.bg.color: ${surface}
          window.inactive.label.text.color: ${on_surface}
          window.inactive.button.unpressed.bg.color: ${surface}
          window.inactive.button.unpressed.image.color: ${on_surface}

          menu.items.bg.color: ${surface}
          menu.items.text.color: ${on_surface}
          menu.items.active.bg.color: ${primary}
          menu.items.active.text.color: ${on_primary}
          menu.border.width: 1
          menu.border.color: ${outline}
          menu.separator.width: 1
          menu.separator.padding.width: 6
          menu.separator.padding.height: 3
          menu.separator.color: ${outline}
          menu.items.padding.x: 8
          menu.items.padding.y: 5
          menu.width.min: 160
          menu.width.max: 360

          osd.bg.color: ${surface_variant}
          osd.label.text.color: ${on_surface}
osd.border.width: 1
osd.window-switcher.padding: 10
EOF

# Reload labwc if it's running so the new theme takes effect
if command -v labwc >/dev/null && pgrep -u "$UID" -x labwc >/dev/null; then
  labwc -r || true
fi

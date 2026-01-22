#!/bin/sh
# Keep GTK (Thunar, etc.) aligned with DMS colors when matugen regenerates them.
set -e
export PATH="/usr/bin:/run/current-system/sw/bin:$PATH"

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"
gtk3_dir="$config_dir/gtk-3.0"
gtk4_dir="$config_dir/gtk-4.0"
gtk3_colors="$gtk3_dir/dank-colors.css"
gtk4_colors="$gtk4_dir/dank-colors.css"
colors_json="$HOME/.cache/DankMaterialShell/dms-colors.json"
settings_json="$config_dir/DankMaterialShell/settings.json"
theme_name=$(awk -F= '/^gtk-theme-name=/{print $2}' "$gtk3_dir/settings.ini" 2>/dev/null | head -n1)
[ -n "$theme_name" ] || theme_name="adw-gtk3"
theme3_path="/usr/share/themes/$theme_name/gtk-3.0/gtk.css"
theme4_path="/usr/share/themes/$theme_name/gtk-4.0/gtk.css"

# Bail if matugen hasn't produced the color files yet.
if [ ! -f "$gtk3_colors" ] && [ ! -f "$gtk4_colors" ]; then
  exit 0
fi

gtk_apply_script="/usr/share/quickshell/dms/scripts/gtk.sh"
if [ ! -x "$gtk_apply_script" ]; then
  exit 0
fi

"$gtk_apply_script" "$config_dir"

# Sync GTK icon theme with DMS preference (falls back to Papirus-Dark).
icon_theme=$(jq -r '.iconTheme // empty' "$settings_json" 2>/dev/null)
[ -n "$icon_theme" ] || icon_theme="Papirus-Dark"
if command -v gsettings >/dev/null 2>&1; then
  gsettings set org.gnome.desktop.interface icon-theme "$icon_theme" >/dev/null 2>&1 || true
fi
for ini in "$gtk3_dir/settings.ini" "$gtk4_dir/settings.ini"; do
  [ -f "$ini" ] || continue
  if grep -q '^gtk-icon-theme-name=' "$ini"; then
    sed -i "s/^gtk-icon-theme-name=.*/gtk-icon-theme-name=${icon_theme}/" "$ini"
  else
    printf '\n[Settings]\ngtk-icon-theme-name=%s\n' "$icon_theme" >> "$ini"
  fi
done

# Ensure the user gtk.css includes the base theme followed by DMS colors (no recursive imports).
mkdir -p "$gtk3_dir" "$gtk4_dir"
if [ -f "$theme3_path" ]; then
  rm -f "$gtk3_dir/gtk.css"
  {
    echo "@import url(\"$theme3_path\");"
    [ -f "$gtk3_colors" ] && echo "@import url(\"$gtk3_colors\");"
  } > "$gtk3_dir/gtk.css"

  if [ -f "$colors_json" ]; then
    primary=$(jq -r '.colors.dark.primary // empty' "$colors_json")
    on_primary=$(jq -r '.colors.dark.on_primary // empty' "$colors_json")
    surface=$(jq -r '.colors.dark.surface // empty' "$colors_json")
    surface_variant=$(jq -r '.colors.dark.surface_variant // empty' "$colors_json")
    on_surface=$(jq -r '.colors.dark.on_surface // empty' "$colors_json")
    outline=$(jq -r '.colors.dark.outline // empty' "$colors_json")
    cat >> "$gtk3_dir/gtk.css" <<EOF

/* DMS overrides */
@define-color window_bg_color ${surface};
@define-color window_fg_color ${on_surface};
@define-color view_bg_color ${surface};
@define-color view_fg_color ${on_surface};
@define-color headerbar_bg_color ${surface};
@define-color headerbar_fg_color ${on_surface};
@define-color sidebar_bg_color ${surface_variant};
@define-color sidebar_fg_color ${on_surface};
@define-color card_bg_color ${surface_variant};
@define-color card_fg_color ${on_surface};
@define-color popover_bg_color ${surface_variant};
@define-color popover_fg_color ${on_surface};
@define-color dialog_bg_color ${surface};
@define-color dialog_fg_color ${on_surface};
@define-color accent_bg_color ${primary};
@define-color accent_fg_color ${on_primary};
@define-color borders ${outline};
EOF
  fi
fi
if [ -f "$theme4_path" ]; then
  rm -f "$gtk4_dir/gtk.css"
  {
    echo "@import url(\"$theme4_path\");"
    [ -f "$gtk4_colors" ] && echo "@import url(\"$gtk4_colors\");"
  } > "$gtk4_dir/gtk.css"
fi

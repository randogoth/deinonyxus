#!/bin/sh
# Recolor Papirus folder icons without touching /usr (immutable-friendly).
# - builds a user overlay in ~/.local/share/icons/<theme> and relinks folder/user icons
#   to the chosen color, leaving the base theme in /usr untouched.
# - Usage: papirus-folder-override.sh [color] [theme]
#   * color: folder accent (e.g., teal, orange, red). Default: blue.
#   * theme: Papirus variant (Papirus, Papirus-Dark, Papirus-Light). Default: Papirus-Dark.
# - Note: sources colored assets from /usr/share/icons/Papirus (full color set) and applies
#   them to the requested variant overlay. Papirus needs to be available at that path. On
#   atomic systems either baked into the image or layered e.g. by using rpm-ostree.
set -e

color="${1:-blue}"
theme="${2:-Papirus-Dark}"
# Source assets from canonical Papirus (contains full color sets), regardless of variant.
source_theme="Papirus"
base_theme_dir="/usr/share/icons/$source_theme"
overlay="$HOME/.local/share/icons/$theme"
sizes="16x16 22x22 24x24 32x32 48x48 64x64 symbolic"

if [ ! -d "$base_theme_dir" ]; then
  echo "Theme '$theme' not found in /usr/share/icons" >&2
  exit 1
fi

mkdir -p "$overlay"
if [ ! -f "$overlay/index.theme" ] && [ -f "$base_theme_dir/index.theme" ]; then
  cp "$base_theme_dir/index.theme" "$overlay/index.theme"
fi

# Clear any existing overlay places dirs to avoid stale links from prior colors.
find "$overlay" -type d -path "*/places" -exec rm -rf {} + 2>/dev/null || true

# Iterate known sizes (and symbolic if present) to repoint folder/user icons.
for size in $sizes; do
  src_dir="$base_theme_dir/$size/places"
  [ -d "$src_dir" ] || continue
  dst_dir="$overlay/$size/places"
  mkdir -p "$dst_dir"

  for prefix in folder user; do
    for file_path in "$src_dir/$prefix-$color"*.svg; do
      [ -f "$file_path" ] || continue
      base="${file_path##*/}"
      target="${base/-$color/}" # strip the color suffix: folder.svg, user-home.svg, etc.
      ln -sf "$file_path" "$dst_dir/$target"
    done
  done
done

gtk-update-icon-cache -qf "$overlay" 2>/dev/null || true
echo "Papirus folder color set to '$color' for theme '$theme' (overlay at $overlay)"

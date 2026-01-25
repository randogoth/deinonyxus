kittytrail:
    echo "custom-shader = /usr/share/ghostty/cursor-shader.glsl" >> ~/.config/ghostty/config

[no-cd]
distrobox:
	#!/usr/bin/env bash
	set -euo pipefail
	boxes="$(distrobox list --no-color 2>/dev/null | awk -F'|' 'NR>1 {gsub(/^[ \t]+|[ \t]+$/,"",$2); print $2}' | sort -f)"
	if [[ -z "$boxes" ]]; then
	  echo "No distroboxes found." >&2
	  exit 1
	fi
	selection="$(printf '%s\n' "$boxes" | gum choose --header 'Select a distrobox to enter:')"
	[[ -n "$selection" ]] || exit 0
	distrobox enter "$selection"
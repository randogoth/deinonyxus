# Change Papirus folder color without touching /usr (immutable-friendly).
# Usage: just papirus-color COLOR="teal" THEME="Papirus-Dark"
papirus-color COLOR="nordic" THEME="Papirus-Dark":
    ~/.local/libexec/dms/papirus-folder-override.sh "{{COLOR}}" "{{THEME}}"

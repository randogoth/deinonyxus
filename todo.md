# Systemd/scripts cleanup
- Simplify `files/system/etc/xdg/labwc/autostart`: drop the `xdg-settings`/`xdg-mime` coercion (ship defaults once via `/etc/xdg` or skel), rely on enabled `*.path` units + graphical-session.target instead of reset-failed + manual starts, and keep the script focused on exporting session env into user systemd/dbus only.
- In `recipes/recipe.yml`, enable only the user path units (optionally `Persistent=true`) instead of both services and paths, and drop redundant autostart starts/reset-failed calls.
- Extend `files/system/usr/lib/systemd/user/labwc-menu-update.path` to watch `/usr/share/applications` so system package changes regenerate the menu.

# Labwc integration polish
- Trim `files/system/usr/libexec/dms/labwc-menu-update.sh`: remove duplicate `rc.xml` copy and the `customPowerActionLogout` rewrite; consider shipping rc.xml via /etc/xdg (or tmpfiles) and relying on skel `settings.json`.
- Split concerns in `files/system/usr/libexec/dms/labwc-themerc-update.sh`: keep Labwc theme generation only; move Ghostty defaults to `/etc/xdg/ghostty/config` or an opt-in sync service and stop editing user config.

# Dependencies
- Ensure required tools (`jq`, `perl`, `python3`) are present in the base image or explicitly installed for the DMS color/theme scripts.

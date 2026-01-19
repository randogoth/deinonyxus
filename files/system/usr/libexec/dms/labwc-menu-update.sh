#!/bin/sh
set -e
export PATH="/usr/bin:$PATH"

dest="$HOME/.config/labwc/menu.xml"
mkdir -p "$(dirname "$dest")"
export GHOSTTY_BIN="/usr/bin"
export DISTROBOX_BIN="/usr/bin"
export DBX_PATH="/usr/bin:/usr/local/bin"
export DMS_BIN="/usr/bin/dms"
export DMS_PATH="/usr/bin"

# Ensure rc.xml points to the generated menu/theme if it doesn't already.
rc="$HOME/.config/labwc/rc.xml"
mkdir -p "$(dirname "$rc")"
cp -f /usr/share/dms/labwc-rc.xml "$rc"

tmp="$(mktemp)"
/usr/bin/labwc-menu-generator \
  --no-duplicates \
  --terminal-prefix "${GHOSTTY_BIN}/ghostty -e" \
  > "$tmp"

# Build final menu from the generator output, injecting DMS Settings and relocating distrobox desktop entries.
/usr/bin/python3 - "$tmp" "$dest" <<'PY'
import sys
import os
import xml.etree.ElementTree as ET
from copy import deepcopy

tmp, dest = sys.argv[1], sys.argv[2]
ghostty_bin = os.environ["GHOSTTY_BIN"]
distrobox_bin = os.environ["DISTROBOX_BIN"]
dbx_path = os.environ["DBX_PATH"]
dms_bin = os.environ["DMS_BIN"]
dms_path = os.environ["DMS_PATH"]

tree = ET.parse(tmp)
root = tree.getroot()
root_menu = root.find(".//menu[@id='root-menu']") or root.find("./menu")
exclude_labels = {"ikhal"}

def ensure_terminal_entry():
    if root_menu is None:
        return
    # Avoid duplicates if already present.
    for child in root_menu.findall("item"):
        if (child.get("label") or "").strip().lower() == "terminal":
            return
    term_item = ET.Element("item", {"label": "Terminal", "icon": "utilities-terminal"})
    action = ET.SubElement(term_item, "action", {"name": "Execute"})
    cmd = ET.SubElement(action, "command")
    cmd.text = f"{ghostty_bin}/ghostty"
    # Insert at the top, followed by a separator for clarity.
    root_menu.insert(0, ET.Element("separator"))
    root_menu.insert(0, term_item)

def ensure_file_manager_entry():
    if root_menu is None:
        return
    for child in root_menu.findall("item"):
        if (child.get("label") or "").strip().lower() == "file manager":
            return
    fm_item = ET.Element("item", {"label": "File Manager", "icon": "system-file-manager"})
    action = ET.SubElement(fm_item, "action", {"name": "Execute"})
    cmd = ET.SubElement(action, "command")
    cmd.text = "thunar"
    # Place right after the Terminal entry if present; otherwise put at top.
    inserted = False
    for idx, child in enumerate(list(root_menu)):
        if child.tag == "item" and (child.get("label") or "").strip().lower() == "terminal":
            root_menu.insert(idx + 1, fm_item)
            inserted = True
            break
    if not inserted:
        root_menu.insert(0, fm_item)

def is_distro_item(item: ET.Element) -> bool:
    for action in item.findall("action"):
        cmd = (action.findtext("command") or "").lower()
        if "distrobox enter" in cmd:
            return True
    icon = (item.get("icon") or "").lower()
    return "distrobox" in icon

distro_items = []
def collect(elem: ET.Element):
    for child in list(elem):
        if child.tag == "item":
            label = (child.get("label") or "").strip().lower()
            if label in exclude_labels:
                elem.remove(child)
                continue
        if child.tag == "item" and is_distro_item(child):
            distro_items.append(deepcopy(child))
            elem.remove(child)
        elif child.tag == "menu":
            collect(child)

if root_menu is not None:
    collect(root_menu)
    ensure_terminal_entry()
    ensure_file_manager_entry()

def prune_empty_menus(elem: ET.Element, keep_root: bool = False):
    for child in list(elem):
        if child.tag == "menu":
            prune_empty_menus(child)
            # Drop menu if it has no item/menu children left.
            if len([c for c in child if c.tag in ("item", "menu")]) == 0:
                elem.remove(child)
    # root handled by caller

if root_menu is not None:
    prune_empty_menus(root_menu, keep_root=True)

def ensure_dms_settings():
    settings = root.find(".//menu[@label='Settings']") or root_menu
    if settings is None:
        return
    for child in settings.findall("item"):
        if child.get("label") == "DMS Settings":
            return
    item = ET.SubElement(settings, "item", {"label": "DMS Settings", "icon": "preferences-desktop"})
    action = ET.SubElement(item, "action", {"name": "Execute"})
    cmd = ET.SubElement(action, "command")
    cmd.text = (
        f"/bin/sh -c 'PATH={dms_path}:$PATH; export PATH; "
        "export XDG_CURRENT_DESKTOP=labwc; export QT_QPA_PLATFORM=wayland; "
        "export WAYLAND_DISPLAY=\"$${WAYLAND_DISPLAY:-wayland-0}\"; "
        "systemctl --user start dms.service >/dev/null || true; "
        f"exec {dms_bin} settings'"
    )

ensure_dms_settings()

def rewrite_distro_item(item: ET.Element):
    label = item.get("label") or ""
    if not label:
        return None
    original_cmd = ""
    for action in item.findall("action"):
        cmd_text = action.findtext("command")
        if cmd_text:
            original_cmd = cmd_text
            break
    container = label.lower()
    if original_cmd:
        parts = original_cmd.strip().replace('"', "'").split()
        if parts:
            maybe = parts[-1].strip("'").strip('"')
            if maybe:
                container = maybe
    inner_cmd = original_cmd.strip() if original_cmd else f"{distrobox_bin}/distrobox enter {container}"
    if inner_cmd.startswith(f"{ghostty_bin}/ghostty") and "distrobox enter" in inner_cmd:
        tail = inner_cmd.split("distrobox enter", 1)[1].strip()
        tail = tail.strip("'\"")
        if tail:
            inner_cmd = f"{distrobox_bin}/distrobox enter {tail}"
    title_prefixed = f"Distrobox: {label}"
    launch = (
        f"/bin/sh -c \"PATH={dbx_path}; export PATH; DISABLE_AUTO_TITLE=1 "
        f"{ghostty_bin}/ghostty --title='{title_prefixed}' -e {inner_cmd}\""
    )
    icon = item.get("icon") or "utilities-terminal"
    new_item = ET.Element("item", {"label": label, "icon": icon})
    action = ET.SubElement(new_item, "action", {"name": "Execute"})
    cmd = ET.SubElement(action, "command")
    cmd.text = launch
    return new_item

if root_menu is not None and distro_items:
    root_menu.append(ET.Element("separator"))
    db_menu = ET.Element("menu", {"id": "distrobox-list", "label": "Distrobox", "icon": "utilities-terminal"})
    for item in distro_items:
        new_item = rewrite_distro_item(item)
        if new_item is not None:
            db_menu.append(new_item)
    root_menu.append(db_menu)

try:
    ET.indent(tree, space="  ")
except Exception:
    pass
tree.write(dest, encoding="utf-8", xml_declaration=True)
PY

rm -f "$tmp"

# Reload labwc so the updated menu is picked up
if command -v labwc >/dev/null && pgrep -u "$UID" -x labwc >/dev/null; then
  labwc -r || true
fi

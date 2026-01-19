#!/usr/bin/python3
"""
Post-process the labwc menu generator output:
- ensure Terminal/File Manager entries
- add DMS Settings
- regroup Distrobox entries under a submenu
"""

import os
import sys
import xml.etree.ElementTree as ET
from copy import deepcopy


def load_env():
    return {
        "ghostty_bin": os.environ.get("GHOSTTY_BIN", "/usr/bin"),
        "distrobox_bin": os.environ.get("DISTROBOX_BIN", "/usr/bin"),
        "dbx_path": os.environ.get("DBX_PATH", "/usr/bin:/usr/local/bin"),
        "dms_bin": os.environ.get("DMS_BIN", "/usr/bin/dms"),
        "dms_path": os.environ.get("DMS_PATH", "/usr/bin"),
    }


def ensure_terminal_entry(root_menu, ghostty_bin):
    if root_menu is None:
        return
    for child in root_menu.findall("item"):
        if (child.get("label") or "").strip().lower() == "terminal":
            return
    term_item = ET.Element("item", {"label": "Terminal", "icon": "utilities-terminal"})
    action = ET.SubElement(term_item, "action", {"name": "Execute"})
    cmd = ET.SubElement(action, "command")
    cmd.text = f"{ghostty_bin}/ghostty"
    root_menu.insert(0, ET.Element("separator"))
    root_menu.insert(0, term_item)


def ensure_file_manager_entry(root_menu):
    if root_menu is None:
        return
    for child in root_menu.findall("item"):
        if (child.get("label") or "").strip().lower() == "file manager":
            return
    fm_item = ET.Element("item", {"label": "File Manager", "icon": "system-file-manager"})
    action = ET.SubElement(fm_item, "action", {"name": "Execute"})
    cmd = ET.SubElement(action, "command")
    cmd.text = "thunar"
    inserted = False
    for idx, child in enumerate(list(root_menu)):
        if child.tag == "item" and (child.get("label") or "").strip().lower() == "terminal":
            root_menu.insert(idx + 1, fm_item)
            inserted = True
            break
    if not inserted:
        root_menu.insert(0, fm_item)


def is_distro_item(item, distrobox_bin):
    for action in item.findall("action"):
        cmd = (action.findtext("command") or "").lower()
        if "distrobox" in cmd or "distrobox-enter" in cmd:
            return True
    icon = (item.get("icon") or "").lower()
    return "distrobox" in icon


def collect_and_prune(root_menu, distrobox_bin):
    distro_items = []
    exclude_labels = {"ikhal"}

    def collect(elem):
        for child in list(elem):
            if child.tag == "item":
                label = (child.get("label") or "").strip().lower()
                if label in exclude_labels:
                    elem.remove(child)
                    continue
            if child.tag == "item" and is_distro_item(child, distrobox_bin):
                distro_items.append(deepcopy(child))
                elem.remove(child)
            elif child.tag == "menu":
                collect(child)

    def prune_empty_menus(elem, keep_root=False):
        for child in list(elem):
            if child.tag == "menu":
                prune_empty_menus(child)
                if len([c for c in child if c.tag in ("item", "menu")]) == 0:
                    elem.remove(child)

    if root_menu is not None:
        collect(root_menu)
        prune_empty_menus(root_menu, keep_root=True)
    return distro_items


def ensure_dms_settings(root, root_menu, dms_path, dms_bin):
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


def rewrite_distro_item(item, distrobox_bin, ghostty_bin, dbx_path):
    label = item.get("label") or ""
    if not label:
        return None
    # Skip app entries launched inside containers (we only want the containers themselves).
    if "(on " in label:
        return None
    original_cmd = ""
    for action in item.findall("action"):
        cmd_text = action.findtext("command")
        if cmd_text:
            original_cmd = cmd_text
            break
    if "distrobox" not in original_cmd.lower():
        return None
    # If the command chains distrobox enter with an app (contains "--"), skip it.
    if "--" in original_cmd:
        return None
    container = label.lower()
    if original_cmd:
        parts = original_cmd.strip().replace('"', "'").split()
        if parts:
            # Prefer explicit "-n name" if present; otherwise fall back to last arg.
            if "-n" in parts:
                try:
                    idx = parts.index("-n")
                    maybe = parts[idx + 1].strip("'").strip('"')
                    if maybe:
                        container = maybe
                except Exception:
                    pass
            else:
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


def add_distro_menu(root_menu, distro_items, distrobox_bin, ghostty_bin, dbx_path):
    if root_menu is None or not distro_items:
        return
    root_menu.append(ET.Element("separator"))
    db_menu = ET.Element("menu", {"id": "distrobox-list", "label": "Distrobox", "icon": "utilities-terminal"})
    for item in distro_items:
        new_item = rewrite_distro_item(item, distrobox_bin, ghostty_bin, dbx_path)
        if new_item is not None:
            db_menu.append(new_item)
    root_menu.append(db_menu)


def main():
    if len(sys.argv) != 3:
        print("Usage: labwc-menu-postprocess.py <infile> <outfile>", file=sys.stderr)
        sys.exit(1)
    tmp, dest = sys.argv[1], sys.argv[2]
    env = load_env()

    tree = ET.parse(tmp)
    root = tree.getroot()
    root_menu = root.find(".//menu[@id='root-menu']") or root.find("./menu")

    ensure_terminal_entry(root_menu, env["ghostty_bin"])
    ensure_file_manager_entry(root_menu)
    distro_items = collect_and_prune(root_menu, env["distrobox_bin"])
    ensure_dms_settings(root, root_menu, env["dms_path"], env["dms_bin"])
    add_distro_menu(root_menu, distro_items, env["distrobox_bin"], env["ghostty_bin"], env["dbx_path"])

    try:
        ET.indent(tree, space="  ")
    except Exception:
        pass
    tree.write(dest, encoding="utf-8", xml_declaration=True)


if __name__ == "__main__":
    main()

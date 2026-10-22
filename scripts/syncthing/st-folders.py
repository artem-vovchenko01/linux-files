#!/usr/bin/env python3
# menu: Syncthing folders and .stignore: save|restore
"""Save or restore what Syncthing itself does not sync.

  st-folders.py save     copy each folder's .stignore next to the config
  st-folders.py restore  create every folder under $HOME with its marker
                         and its saved .stignore
  st-folders.py settle   turn pending #include lines back on once the
                         included file has synced

On a fresh machine run `restore` before Syncthing starts. Syncthing refuses
a folder whose path is missing (it could be an unplugged drive), and
.stignore files never travel between devices. Folders outside $HOME (the
external HDD) are left alone.

An #include of a missing file puts the folder in an error state, and an
erroring folder never syncs, so a synced include file such as
.stglobalignore would never arrive. `restore` writes such lines as
pending comments, `settle` turns them back on, and `save` always stores
the real line.
"""
import os
import shutil
import sys
import xml.etree.ElementTree as ET

HOME = os.path.expanduser("~")
CONF = os.path.join(HOME, "DATA/IT/configs/syncthing")
BACKUP = os.path.join(CONF, "stignore")
PENDING = "// st-folders pending: "


def folders():
    root = ET.parse(os.path.join(CONF, "config.xml")).getroot()
    for f in root.findall("folder"):
        path = os.path.expanduser(f.get("path") or "").rstrip("/")
        if f.get("id") and path.startswith(HOME + "/"):
            yield f.get("id"), path, f.findtext("markerName") or ".stfolder"


def park_missing_includes(text, folder):
    out = []
    for line in text.splitlines(keepends=True):
        inc = line.strip()
        if inc.startswith("#include ") and not os.path.exists(
                os.path.join(folder, inc[len("#include "):].strip())):
            line = PENDING + line
        out.append(line)
    return "".join(out)


def save():
    os.makedirs(BACKUP, exist_ok=True)
    for fid, path, _ in folders():
        src = os.path.join(path, ".stignore")
        if os.path.isfile(src):
            with open(src) as f:
                text = f.read().replace(PENDING, "")
            with open(os.path.join(BACKUP, fid + ".stignore"), "w") as f:
                f.write(text)
            print(f"saved {fid}")


def restore():
    for fid, path, marker in folders():
        os.makedirs(os.path.join(path, marker), exist_ok=True)
        dst = os.path.join(path, ".stignore")
        src = os.path.join(BACKUP, fid + ".stignore")
        if not os.path.exists(dst) and os.path.isfile(src):
            with open(src) as f:
                text = park_missing_includes(f.read(), path)
            with open(dst, "w") as f:
                f.write(text)
            print(f"ready {path} (with .stignore)")
        else:
            print(f"ready {path}")


def settle():
    for fid, path, _ in folders():
        dst = os.path.join(path, ".stignore")
        if not os.path.isfile(dst):
            continue
        with open(dst) as f:
            text = f.read()
        fixed = []
        for line in text.splitlines(keepends=True):
            inc = line[len(PENDING):] if line.startswith(PENDING) else ""
            name = inc.strip()[len("#include "):].strip()
            if inc and os.path.exists(os.path.join(path, name)):
                line = inc
            fixed.append(line)
        if "".join(fixed) != text:
            with open(dst, "w") as f:
                f.write("".join(fixed))
            print(f"settled {fid}")


if __name__ == "__main__":
    actions = {"save": save, "restore": restore, "settle": settle}
    if len(sys.argv) != 2 or sys.argv[1] not in actions:
        sys.exit(__doc__)
    actions[sys.argv[1]]()

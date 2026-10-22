#!/usr/bin/env python3
"""Save or restore what Syncthing itself does not sync.

  st-folders.py save     copy each folder's .stignore next to the config
  st-folders.py restore  create every folder under $HOME with its marker
                         and its saved .stignore

On a fresh machine run `restore` before Syncthing starts. Syncthing refuses
a folder whose path is missing (it could be an unplugged drive), and
.stignore files never travel between devices. Folders outside $HOME (the
external HDD) are left alone.
"""
import os
import shutil
import sys
import xml.etree.ElementTree as ET

HOME = os.path.expanduser("~")
CONF = os.path.join(HOME, "DATA/IT/configs/syncthing")
BACKUP = os.path.join(CONF, "stignore")


def folders():
    root = ET.parse(os.path.join(CONF, "config.xml")).getroot()
    for f in root.findall("folder"):
        path = os.path.expanduser(f.get("path") or "").rstrip("/")
        if f.get("id") and path.startswith(HOME + "/"):
            yield f.get("id"), path, f.findtext("markerName") or ".stfolder"


def save():
    os.makedirs(BACKUP, exist_ok=True)
    for fid, path, _ in folders():
        src = os.path.join(path, ".stignore")
        if os.path.isfile(src):
            shutil.copyfile(src, os.path.join(BACKUP, fid + ".stignore"))
            print(f"saved {fid}")


def restore():
    for fid, path, marker in folders():
        os.makedirs(os.path.join(path, marker), exist_ok=True)
        dst = os.path.join(path, ".stignore")
        src = os.path.join(BACKUP, fid + ".stignore")
        if not os.path.exists(dst) and os.path.isfile(src):
            shutil.copyfile(src, dst)
            print(f"ready {path} (with .stignore)")
        else:
            print(f"ready {path}")


if __name__ == "__main__":
    actions = {"save": save, "restore": restore}
    if len(sys.argv) != 2 or sys.argv[1] not in actions:
        sys.exit(__doc__)
    actions[sys.argv[1]]()

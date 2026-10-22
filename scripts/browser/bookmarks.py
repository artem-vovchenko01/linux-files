#!/usr/bin/env python3
"""Save or restore Chromium and Firefox bookmarks.

  bookmarks.py save            copy bookmarks into ~/DATA/IT/browser-bookmarks
  bookmarks.py restore         put them back into the browser profiles
  bookmarks.py restore --force also replace bookmarks a profile already has

Close both browsers before `restore`.

Chromium keeps bookmarks in <profile>/Bookmarks (JSON); restore copies the
file back. Firefox keeps dated JSON backups in <profile>/bookmarkbackups.
When Firefox finds a new places.sqlite, it restores the newest backup on
startup (PlacesBrowserStartup.sys.mjs). So restore places the saved backup,
moves places.sqlite aside, and the next Firefox start does the import.
Firefox needs a profile first: start it once, close it, then run restore.
Everything replaced is renamed to *.bak-<time>, never deleted.
"""
import configparser
import glob
import os
import shutil
import sqlite3
import subprocess
import sys
import time

HOME = os.path.expanduser("~")
STORE = os.path.join(HOME, "DATA/IT/browser-bookmarks")
CHROMIUM = os.path.join(HOME, ".config/chromium")
FIREFOX_DIRS = [os.path.join(HOME, ".config/mozilla/firefox"),
                os.path.join(HOME, ".mozilla/firefox")]
STAMP = time.strftime("%Y%m%d%H%M%S")


def running(name):
    return subprocess.run(["pgrep", "-x", name], capture_output=True).returncode == 0


def set_aside(path):
    if os.path.exists(path):
        os.rename(path, f"{path}.bak-{STAMP}")


def firefox_profiles():
    """Yield (name, path) for each Firefox profile, the install default first."""
    for base in FIREFOX_DIRS:
        ini = os.path.join(base, "profiles.ini")
        if not os.path.isfile(ini):
            continue
        cfg = configparser.RawConfigParser()
        cfg.read(ini)
        defaults = {cfg[s]["Default"] for s in cfg.sections() if s.startswith("Install")}
        found = []
        for s in cfg.sections():
            if s.startswith("Profile") and "Path" in cfg[s]:
                rel = cfg[s].get("IsRelative", "1") == "1"
                path = os.path.join(base, cfg[s]["Path"]) if rel else cfg[s]["Path"]
                found.append((cfg[s]["Path"] not in defaults, cfg[s].get("Name", s), path))
        for _, name, path in sorted(found):
            yield name, path


def visit_count(places):
    """A fresh profile has default bookmarks but no browsing history."""
    if not os.path.isfile(places):
        return 0
    db = sqlite3.connect(f"file:{places}?immutable=1", uri=True)
    try:
        return db.execute("select count(*) from moz_historyvisits").fetchone()[0]
    finally:
        db.close()


def save():
    for src in glob.glob(os.path.join(CHROMIUM, "*/Bookmarks")):
        profile = os.path.basename(os.path.dirname(src))
        dst = os.path.join(STORE, "chromium", profile)
        os.makedirs(dst, exist_ok=True)
        shutil.copyfile(src, os.path.join(dst, "Bookmarks"))
        print(f"chromium/{profile}: saved")
    for name, path in firefox_profiles():
        backups = sorted(glob.glob(os.path.join(path, "bookmarkbackups/bookmarks-*.jsonlz4")))
        if not backups:
            continue
        dst = os.path.join(STORE, "firefox", name)
        os.makedirs(dst, exist_ok=True)
        for old in glob.glob(os.path.join(dst, "*.jsonlz4")):
            os.remove(old)
        shutil.copy2(backups[-1], dst)
        print(f"firefox/{name}: saved {os.path.basename(backups[-1])[:30]}")


def restore(force):
    for name in ("chromium", "firefox"):
        if running(name):
            sys.exit(f"Close {name} first.")
    for src in glob.glob(os.path.join(STORE, "chromium/*/Bookmarks")):
        profile = os.path.basename(os.path.dirname(src))
        dst = os.path.join(CHROMIUM, profile, "Bookmarks")
        if os.path.exists(dst) and not force:
            print(f"chromium/{profile}: has bookmarks, skipped (use --force)")
            continue
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        set_aside(dst)
        shutil.copyfile(src, dst)
        print(f"chromium/{profile}: restored")
    profiles = list(firefox_profiles())
    for saved in glob.glob(os.path.join(STORE, "firefox/*/*.jsonlz4")):
        name = os.path.basename(os.path.dirname(saved))
        target = next((p for n, p in profiles if n == name), None)
        if target is None and profiles:
            target = profiles[0][1]
        if target is None:
            print("firefox: no profile yet; start Firefox once, close it, run again")
            break
        places = os.path.join(target, "places.sqlite")
        if visit_count(places) > 20 and not force:
            print(f"firefox/{name}: profile in use, skipped (use --force)")
            continue
        backup_dir = os.path.join(target, "bookmarkbackups")
        set_aside(backup_dir)
        os.makedirs(backup_dir)
        shutil.copy2(saved, backup_dir)
        for suffix in ("", "-wal", "-shm"):
            set_aside(places + suffix)
        print(f"firefox/{name}: restores on next Firefox start")
        break


if __name__ == "__main__":
    args = sys.argv[1:]
    if args == ["save"]:
        save()
    elif args and args[0] == "restore" and args[1:] in ([], ["--force"]):
        restore(force=bool(args[1:]))
    else:
        sys.exit(__doc__)

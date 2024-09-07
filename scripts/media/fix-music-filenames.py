#!/usr/bin/python3

import os
import re

# sometimes it changes й to и for some reason
for idx, filename in enumerate(os.listdir(".")):
    new_fname = re.sub(r"\s+", "_", filename)
    new_fname = re.sub(r"[()]+", "-", new_fname)
    new_fname = re.sub(r"[_-]*-[_-]*", "-", new_fname)
    new_fname = re.sub(r"&", "_and_", new_fname)
    new_fname = ''.join(ch for ch in new_fname if ch.isalnum() or ch in "_-.")
    new_fname = re.sub(r"_+", "_", new_fname)
    new_fname = re.sub(r"-+", "-", new_fname)
    new_fname = re.sub(r"^[-_]", "", new_fname)
    new_fname = re.sub(r"[-_]$", "", new_fname)
    new_fname = re.sub(r"[-_]\.mp3$", ".mp3", new_fname)
    new_fname = re.sub(r"[_-]*-[_-]*", "-", new_fname)
    if filename != new_fname:
        if os.path.exists(new_fname):
            print(f"WARNING: {new_fname} already exists, overwriting will happen")
        os.rename(filename, new_fname)
        print(f"{filename} -> {new_fname}")

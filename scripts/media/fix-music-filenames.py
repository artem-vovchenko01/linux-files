#!/usr/bin/python3

import os
import re

for idx, filename in enumerate(os.listdir(".")):
    new_fname = re.sub(r"\s+", "_", filename)
    new_fname = re.sub(r"[()]+", "-", new_fname)
    new_fname = re.sub(r"_*-_*", "-", new_fname)
    new_fname = re.sub(r"&", "_and_", new_fname)
    new_fname = ''.join(ch for ch in new_fname if ch.isalnum() or ch in "_-.")
    if os.path.exists(new_fname):
        print(f"WARNING: {new_fname} already exists, overwriting will happen")
    os.rename(filename, new_fname)
    print(f"{filename} -> {new_fname}")

#!/usr/bin/python3

import os
import sys
import re

pat1 = sys.argv[1]
pat2 = sys.argv[2]
print("You want to do the following:")
print(f"re.sub(fr\"{pat1}\", fr\"{pat2}\", filename)")
print("Press Return to continue, ^C to cancel")
input()

for idx, filename in enumerate(os.listdir(".")):
    new_fname = re.sub(fr"{pat1}", fr"{pat2}", filename)
    new_fname = re.sub(r"[()]+", "-", new_fname)
    new_fname = re.sub(r"_*-_*", "-", new_fname)
    new_fname = ''.join(ch for ch in new_fname if ch.isalnum() or ch in "_-&.")
    if os.path.exists(new_fname):
        print(f"WARNING: {new_fname} already exists, overwriting will happen")
    os.rename(filename, new_fname)
    print(f"{filename} -> {new_fname}")

#!/usr/bin/python3

import os
import re

for idx, filename in enumerate(os.listdir(".")):
    new_fname = re.sub(r"\d+ - ", "", filename)
    if os.path.exists(new_fname):
        print(f"WARNING: {new_fname} already exists, overwriting will happen")
    os.rename(filename, new_fname)
    print(f"{filename} -> {new_fname}")

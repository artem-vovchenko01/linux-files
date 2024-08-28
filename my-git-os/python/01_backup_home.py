#!/usr/bin/env python

import os
import re
import datetime
import logging
import distutils.dir_util
from pathlib import Path


def get_hidden_and_public_dirs_from(target: str) -> tuple[list, list]:
    hidden = []
    public = []
    for any in os.listdir(target):
        any = os.path.join(target, any)
        if os.path.isdir(any):
            if os.path.basename(any).startswith('.'):
                hidden.append(any)
            else:
                public.append(any)

    hidden.sort()
    public.sort()
    return hidden, public


def get_sysname() -> str:
    sys_name_data = os.popen('cat /etc/os-release | grep "^NAME="').read()
    sys_name_parsed = re.search(r'"(?P<os_name>.*)"',
                                sys_name_data).group('os_name')
    sys_name = re.sub(r'\s+', '_', sys_name_parsed)
    return sys_name


def backup(target: str, destination: str):
    logging.info("Listing target: ")
    [print(d) for d in os.listdir(target)]
    print()
    target_size = sum(file.stat().st_size for file in Path(target).rglob('*'))
    logging.info(f"Size of target: {target_size // (10 ** 6)} MB")
    nested_destination = os.path.join(destination, os.path.basename(target))
    ask = input(f"Copy {target} to {nested_destination}? [YyNn]: ")
    if not re.match('^[Yy]$', ask):
        logging.info("Skipping copying")
        return
    logging.info(f"Copying {target} into {nested_destination} ...")
    distutils.dir_util.copy_tree(target, nested_destination)
    logging.info("Copying finished. Listing destination: ")
    [print(item) for item in os.listdir(nested_destination)]


logging.basicConfig(level=logging.INFO, format="%(levelname)s> %(message)s")

home = os.path.expanduser('~')
hidden, public = get_hidden_and_public_dirs_from(home)
logging.info("Hidden directories found: ")
[print(pth) for pth in hidden]

print()
logging.info("Not hidden directories found: ")
for pth in public:
    print(pth, end='')
    if os.path.islink(pth):
        print(" (symlink)")
    else:
        print()
print()

public = list(filter(lambda pth: not os.path.islink(pth), public))

time = datetime.datetime.ctime(datetime.datetime.now())
time_str = re.sub(r'[:\s]+', '_', time)
bacup_dir_name = f"{get_sysname()}_{time_str}.bac.d"

destination = os.path.join('/mnt/data/Recycle Point/OS_Backups',
                           bacup_dir_name)
os.mkdir(destination)
logging.info(f"Created direcotry {destination}")

for target in public:
    backup(target, destination)

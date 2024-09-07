#!/usr/bin/python3

import os
import sys
import subprocess
import re

playlist = sys.argv[1]

cmd_print_songs = f"yt-dlp --flat-playlist --print \"%(playlist_index)s:%(title)s\" {playlist}"
cmd_download_songs_by_idxs = "yt-dlp --playlist-items {items} -f bestaudio -o '%(title)s.%(ext)s' --embed-metadata --extract-audio --audio-quality 0 --audio-format mp3 {url}"

def run(cmd):
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    return result.stdout

def print_info(remote_songs: list[str], 
               present_before: list[int], 
               present_after: list[int], 
               absent_before: list[int], 
               absent_after: list[int], 
               n_local_files_before: int, 
               n_local_files_after: int, 
               n_local_files_mp3_before: int,
               n_local_files_mp3_after: int):

    n_remote_songs = len(remote_songs)

    print("=============================")
    print("STATS")
    print("=============================")
    print(f"local files: {n_local_files_before} -> {n_local_files_after}")
    print(f"local files (mp3): {n_local_files_mp3_before} -> {n_local_files_mp3_after}")
    print(f"remote songs: {n_remote_songs}")
    print(f"remote songs - present: {len(present_before)} -> {len(present_after)}")
    print(f"remote songs - absent: {len(absent_before)} -> {len(absent_after)}")
    print("=============================")

def get_proper_filename(filename: str):
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
    return new_fname

def check_song_presence(songs: list[str]):
    present = []
    absent = []
    for song in songs:
        idx = song.split(":")[0]
        name = "".join(song.split(":")[1:])
        proper_fname = get_proper_filename(name + ".mp3")
        if os.path.exists(proper_fname):
            present.append(idx)
        else:
            print(f"{song} IS ABSENT")
            absent.append(idx)
    return present, absent

def download_songs_by_idxs(idxs: list[int]):
    items = ",".join(map(str, idxs))
    print(f"Downloading songs: {idxs}")
    print(run(cmd_download_songs_by_idxs.format(items=items, url=playlist)))

remote_songs = run(cmd_print_songs).splitlines()

n_local_files_before = int(run("ls | wc -l"))
n_local_files_mp3_before = int(run("ls *.mp3 | wc -l"))

print("=============================")
print("Checking presence of songs BEFORE")
print("=============================")
present_before, absent_before = check_song_presence(remote_songs)
print("=============================")

if len(absent_before) == 0:
    print("No absent songs found!")
else:
    print("Downloading absent songs ...")
    print("=============================")
    download_songs_by_idxs(absent_before)

print("Fixing filenames")
print(run("fix-music-filenames.py"))
print("=============================")

n_local_files_after = int(run("ls | wc -l"))
n_local_files_mp3_after = int(run("ls *.mp3 | wc -l"))

print("Checking presence of songs AFTER")
print("=============================")
present_after, absent_after = check_song_presence(remote_songs)

print_info(remote_songs=remote_songs, 
           present_before=present_before, 
           present_after=present_after, 
           absent_before=absent_before, 
           absent_after=absent_after,
           n_local_files_before=n_local_files_before,
           n_local_files_after=n_local_files_after,
           n_local_files_mp3_before=n_local_files_mp3_before,
           n_local_files_mp3_after=n_local_files_mp3_after
           )

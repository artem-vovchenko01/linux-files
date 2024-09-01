#!/usr/bin/env bash

yt-dlp -f "bestaudio" -o "%(title)s.%(ext)s" --embed-metadata --extract-audio --audio-quality 0 --audio-format mp3 "$1"

# here my own script is used
fix-filename.py

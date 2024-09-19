#!/usr/bin/env bash
kill $(pgrep -f start-wob.sh | grep -v $$)
rm -f $XDG_RUNTIME_DIR/wob.sock
mkfifo $XDG_RUNTIME_DIR/wob.sock
tail -f $XDG_RUNTIME_DIR/wob.sock | wob

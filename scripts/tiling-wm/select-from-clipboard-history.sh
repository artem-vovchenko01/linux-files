set -exo pipefail

SELECTION="$(cliphist list | wofi --dmenu)"
echo "$SELECTION" | cliphist decode | wl-copy

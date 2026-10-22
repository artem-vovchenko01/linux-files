#!/usr/bin/env bash
# Toggle whether closing the lid suspends the laptop.
# Awake mode runs the user unit lid-no-suspend.service, which holds a logind
# handle-lid-switch inhibitor. The EPAM relay needs awake mode to serve boxes.
# Usage: toggle-lid-sleep.sh [status]
set -euo pipefail
UNIT=lid-no-suspend.service

status() {
  if systemctl --user -q is-active "$UNIT"; then
    echo "lid closed: laptop stays awake ($UNIT active)"
  else
    echo "lid closed: laptop suspends ($UNIT inactive)"
  fi
}

case "${1:-}" in
  status) ;;
  "")
    if systemctl --user -q is-active "$UNIT"; then
      systemctl --user disable --now "$UNIT"
    else
      systemctl --user enable --now "$UNIT"
    fi ;;
  *) echo "usage: $(basename "$0") [status]" >&2; exit 2 ;;
esac
status

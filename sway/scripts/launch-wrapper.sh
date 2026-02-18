#!/usr/bin/env bash
set -euo pipefail

LOG=${XDG_CACHE_HOME:-$HOME/.cache}/launch-wrapper.log
mkdir -p "$(dirname "$LOG")"

echo "$(date --iso-8601=seconds) [launch-wrapper] started by user=${USER:-unknown}" >>"$LOG"
echo "ENV: XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-<missing>}" >>"$LOG"
echo "ENV: DBUS_SESSION_BUS_ADDRESS=${DBUS_SESSION_BUS_ADDRESS:-<missing>}" >>"$LOG"
echo "ENV: PATH=${PATH:-<missing>}" >>"$LOG"

# Run the real launcher detached so Sway won't wait on it
setsid /home/elbulbol/websites/launch.sh >>"$LOG" 2>&1 &
echo "$(date --iso-8601=seconds) [launch-wrapper] invoked launch.sh (pid $!)" >>"$LOG"

exit 0

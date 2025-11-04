# License: MIT
#!/usr/bin/env zsh

set -euo pipefail

logfile="${HOME}/.tmp/www.log"
mkdir -p "${HOME}/.tmp"

# Wait for a valid Sway socket instead of exiting (prevents start-limit-hit)
get_sock() {
  local s=""
  s="$(sway --get-socketpath 2>/dev/null || true)"
  if [[ -z "$s" ]]; then
    local cand
    cand=(${(f)"$(ls /run/user/$UID/sway-ipc.*.sock 2>/dev/null || true)"})
    if [[ ${#cand[@]} -gt 0 ]]; then
      s="${cand[1]}"
    fi
  fi
  echo "$s"
}

while true; do
  SOCK="$(get_sock)"
  if [[ -z "$SOCK" || ! -S "$SOCK" ]]; then
    print -r -- "$(date) :: waiting for Sway socket..." >> "$logfile"
    sleep 2
    continue
  fi

  print -r -- "$(date) :: connected to Sway socket $SOCK; subscribing…" >> "$logfile"
  # Keep this running; if the pipe closes, loop and reconnect
  swaymsg -s "$SOCK" -t subscribe '["window","workspace"]' \
  | while read -r _; do
      /opt/cron.jobs/steam_window_killer_sway.sh
    done

  print -r -- "$(date) :: subscribe stream ended; retrying…" >> "$logfile"
  sleep 1
done

# License: MIT
#!/usr/bin/env zsh

# Kill Steam when minimized/hidden/closed (tray-only) on Sway.
# MODE:
#   "safe"       -> kill only if windows exist but none are visible
#   "aggressive" -> kill if NO windows exist OR none are visible
# Logs to ~/.tmp/www.log

set -euo pipefail

MODE="aggressive"   # <- set to "safe" if you want the older behavior
logfile="${HOME}/.tmp/www.log"
mkdir -p "${HOME}/.tmp"

for cmd in /usr/bin/swaymsg /usr/bin/jq /usr/bin/pgrep /usr/bin/pkill; do
  if [[ ! -x "$cmd" ]]; then
    print -r -- "$(date) :: missing $cmd - no action" >> "$logfile"
    exit 0
  fi
done

# If Steam isn't running, nothing to do
if ! /usr/bin/pgrep -x steam >/dev/null 2>&1; then
  print -r -- "$(date) :: steam not running - no action" >> "$logfile"
  exit 0
fi

# Get Sway tree; if not in Sway session, bail safely
if ! tree="$(/usr/bin/swaymsg -t get_tree 2>/dev/null)"; then
  print -r -- "$(date) :: swaymsg get_tree failed - not in sway? - no action" >> "$logfile"
  exit 0
fi

# What counts as "Steam-related"
jq_selector='
  [
    .. | objects |
    select(
      (.app_id? // "" | ascii_downcase) == "steam"
      or (.window_properties?.class? // "" | test("steam|steamwebhelper|proton|wine|dxvk"; "i"))
      or (.window_properties?.instance? // "" | test("steam|steamwebhelper"; "i"))
    )
  ]
'

steam_related_count=$(/usr/bin/jq "${jq_selector} | length" <<<"$tree")
steam_visible_count=$(/usr/bin/jq "${jq_selector} | map(select(.visible==true)) | length" <<<"$tree")

# Decision
should_kill=0
if [[ "$MODE" == "safe" ]]; then
  # Old behavior: only kill when windows exist but none are visible
  if [[ "$steam_related_count" -gt 0 && "$steam_visible_count" -eq 0 ]]; then
    should_kill=1
  fi
else
  # Aggressive: kill when NO windows exist OR none are visible
  if [[ "$steam_related_count" -eq 0 || "$steam_visible_count" -eq 0 ]]; then
    should_kill=1
  fi
fi

if [[ "$should_kill" -eq 1 ]]; then
  print -r -- "$(date) :: killing steam (mode=${MODE}, related=${steam_related_count}, visible=${steam_visible_count})" >> "$logfile"
  /usr/bin/pkill -x steam || true
else
  print -r -- "$(date) :: no kill (mode=${MODE}, related=${steam_related_count}, visible=${steam_visible_count})" >> "$logfile"
fi

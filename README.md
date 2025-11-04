# Steam Minimize Killer for SwayWM

**License:** MIT  
**Repo:** https://github.com/nxfti/steam_minimize_killer_sway  
**Need help?** Email: **nxftiiii@gmail.com**

---

## Description

This project automatically kills Steam when its window is minimized / hidden / closed on **SwayWM**.  
It remains safe for fullscreen Proton/Wine games — if a game window is visible, Steam will **not** be terminated.

---

## Why?

This addresses the annoying lack of a Linux Steam feature to “close on minimize”.

### Features
- Doesn’t kill Steam if a fullscreen game is active (vs killing when Steam “isn’t visible”).
- Sway-native, event-driven — **no cron polling**.
- Fast reaction (instant window change subscribe).
- Logging for debug/decisions to `~/.tmp/www.log`.
- Modes (safe vs aggressive):
  - `safe` → kill only if windows exist but none are visible  
  - `aggressive` → kill if **no** windows exist **or** none are visible
- Uses Sway IPC directly.
- Adapted for event-driven behavior on **Debian 13**.

---

## Tested

- Sway 1.10.1  
- Debian 13  
- Zsh (default shell)

---

## Install

### Dependencies (Debian + Sway assumed)
```bash
sudo apt update
sudo apt install jq procps
```

### Install Script
- Place steam_window_killer_sway.sh and steam_window_killer_sway.zsh in /opt/cron.jobs/steam_minimize_killer/:

```bash
sudo mkdir -p /opt/cron.jobs/steam_minimize_killer
sudo mv steam_window_killer_sway.sh steam_window_killer_sway.zsh /opt/cron.jobs/steam_minimize_killer/
sudo chown -R "$USER":"$USER" /opt/cron.jobs
sudo chmod +x /opt/cron.jobs/*.sh /opt/cron.jobs/*.zsh
```

### Create directory for logging
```bash
mkdir -p ~/.tmp
touch ~/.tmp/www.log
```
### Systemd user service
```bash
mkdir -p ~/.config/systemd/user/
mv steam-killer.service ~/.config/systemd/user/
```
### Enable and Run
```bash
systemctl --user daemon-reload
systemctl --user enable --now steam-killer.service
```
### Verify
```bash
systemctl --user status steam-killer.service
journalctl --user -u steam-killer.service -f
```

#### Troubleshooting
- Something broken? Look in the logs:
```bash
tail -n 20 ~/.tmp/www.log
```
- See Sway restarts / errors:
```bash
journalctl -b -g sway --no-pager | tail -n 100
```
- See unit logs and exit reasons:
```bash
journalctl --user -u steam-killer.service -n 100 --no-pager
```
#### Extra Note
- If fullscreen games keep killing Steam, you likely have a non-standard window class. Debug with:
```bash
swaymsg -t get_tree | jq -r '..|.window_properties?.class? // empty' | sort -u
```

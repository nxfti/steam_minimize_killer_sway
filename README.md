# License: MIT 
# github.com/nxfti/steam_minimize_killer_sway
# Need help, Email me: nxftiiii@gmail.com

# Description: 
# 	This project automatically kills Steam when its window is minimized / hidden / closed on SwayWM. 
# 	It remains safe for fullscreen Proton/Wine games — if a game window is visible, Steam will not be terminated.

# Why?: 
#	This address the annoying lack of Linux Steam feature to close on minimize. 
#	Features
#		Doesn't kill Steam if fullscreen game is up versus killing if Steam "isn't visible"
#		Sway-native event driven — no cron polling
#		Fast reaction (instant window change subscribe)
#		Some Logging for debug/decisions to ~/.tmp/www.log
#		Modes: (safe vs aggressive)
# 			MODE:
#   			"safe"       -> kill only if windows exist but none are visible
#   			"aggressive" -> kill if NO windows exist OR none are visible
#		Uses sway IPC directly

# Adapted for Event driven using SwayWM/Sway using Debian 13.

# Tested: Sway version 1.10.1 & Debian 13 & Zsh(default shell)

#############
#  Install  #
#############

# Dependencies( Assumption you have Debian & Sway )
sudo apt update
sudo apt install jq procps

# Install Script

# Place steam_window_killer_sway.sh + steam_killer_eventloop.zsh in /opt/cron.jobs/*
sudo mkdir -p /opt/cron.jobs/steam_minimize_killer
sudo mv steam_window_killer_sway.sh steam_window_killer_sway.zsh /opt/cron.jobs/steam_minimize_killer/
sudo chown -R "$USER":"$USER" /opt/cron.jobs
sudo chmod +x /opt/cron.jobs/*.sh /opt/cron.jobs/*.zsh

# Create directory for logging  
mkdir -p ~/.tmp  
touch ~/.tmp/www.log

# systemd service cronjob
# Just in case but should exist already
sudo mkdir -p ~/.config/systemd/user/
sudo mv steam-killer.service ~/.config/systemd/user/

# Systemd cronjob - Enable and run
systemctl --user daemon-reload
systemctl --user enable --now steam-killer.service


# Sanity Check/Verify
systemctl --user status steam-killer.service
journalctl --user -u steam-killer.service -f

# Something broken, look in the logs:
tail -n 20 ~/.tmp/www.log
# See Sway restarts / errors
journalctl -b -g sway --no-pager | tail -n 100
# See unit logs and exit reasons
journalctl --user -u steam-killer.service -n 100 --no-pager


# Extra Note: If full screen games keep killing steam, you have some non-standard window class.
# Use below to debug it:
#	swaymsg -t get_tree | jq -r '..|.window_properties?.class? // empty' | sort -u


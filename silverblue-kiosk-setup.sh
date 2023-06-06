#!/bin/bash

# ---------------------------------------------------------------------------
# This script performs an update of the system and installs the necessary
# packages for running a kiosk system with Openbox and Chromium.
# It is meant to be run right after a fresh install of Fedora Silverblue.
#
# After installing the packages, it configures autologin in GDM and configures openbox to autostart chromium-browser in kiosk mode.
# ---------------------------------------------------------------------------

# update the system
rpm-ostree upgrade

# install openbox and chromium
rpm-ostree install openbox chromium

# enable autologin in gnome display manager
echo "AutomaticLoginEnable=true
AutomaticLogin=test
DefaultSession=openbox" > /etc/gdm/custom.conf

mkdir -p /home/kiosk/.config/openbox
echo "chromium-browser --kiosk --no-first-run '\''https://khm.de'\'' &
" > /home/kiosk/.config/openbox/autostart'

# reboot the system
systemctl reboot

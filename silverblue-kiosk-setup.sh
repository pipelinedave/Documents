#!/bin/bash

# ---------------------------------------------------------------------------
# This script performs an update of the system and installs the necessary
# packages for running a kiosk system with Openbox and Chromium.
# It is meant to be run right after a fresh install of Fedora Silverblue.
#
# After installing the packages, it configures autologin in GDM and configures openbox to autostart chromium-browser in kiosk mode.
# ---------------------------------------------------------------------------

echo "Starting kiosk setup..."

# update the system
echo "Updating the system..."
if rpm-ostree upgrade; then
    echo "System updated successfully!"
else
    echo "Failed to update the system!"
    exit 1
fi

# install openbox and chromium
echo "Installing Openbox and Chromium..."
if rpm-ostree install openbox chromium; then
    echo "Openbox and Chromium installed successfully!"
else
    echo "Failed to install Openbox and Chromium!"
    exit 1
fi

# enable autologin in gnome display manager
echo "Configuring autologin in GDM..."
echo "[daemon]
AutomaticLoginEnable=true
AutomaticLogin=test
DefaultSession=openbox" > /etc/gdm/custom.conf

if [ $? -eq 0 ]; then
    echo "Autologin configured successfully!"
else
    echo "Failed to configure autologin!"
    exit 1
fi

echo "Configuring Openbox to autostart Chromium in kiosk mode..."
mkdir -p /home/test/.config/openbox
echo "chromium-browser --kiosk --no-first-run --password-store=basic '\''https://khm.de'\'' &
" > /home/test/.config/openbox/autostart

if [ $? -eq 0 ]; then
    echo "Openbox autostart configured successfully!"
else
    echo "Failed to configure Openbox autostart!"
    exit 1
fi

# set permissions for autostart script
echo "Setting permissions for autostart script..."
if chown -R test:test /home/test/.config; then
    echo "Permissions set successfully!"
else
    echo "Failed to set permissions!"
    exit 1
fi

# reboot the system
echo "Rebooting the system..."
if systemctl reboot; then
    echo "System reboot initiated!"
else
    echo "Failed to initiate system reboot!"
    exit 1
fi

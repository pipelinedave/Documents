#!/bin/sh

# ---------------------------------------------------------------------------
# This script performs an update of the system and installs the necessary
# packages for running a kiosk system with Openbox and Chromium.
# It is meant to be run right after a fresh install of Fedora Silverblue.
#
# After installing the packages, it configures autologin in GDM and configures openbox to autostart chromium-browser in kiosk mode.
# ---------------------------------------------------------------------------

# Function to wait for rpm-ostree to become available
wait_for_rpm_ostree () {
    echo "Waiting for rpm-ostree to be available..."
    while rpm-ostree status | grep -q 'Transaction'; do
        sleep 5
    done
    sleep 5
}


echo "Starting kiosk setup..."

# update the system
echo "Updating the system..."
if rpm-ostree upgrade; then
    echo "System updated successfully!"
else
    echo "Failed to update the system!"
    exit 1
fi

# make sure rpm-ostree is in idle state by now
wait_for_rpm_ostree

# install openbox and chromium
echo "Installing Openbox"
if rpm-ostree install openbox; then
    echo "Openbox installed successfully!"
else
    echo "Failed to install Openbox!"
    exit 1
fi

# make sure rpm-ostree is in idle state by now
wait_for_rpm_ostree

echo "Installing Chromium"
if rpm-ostree install chromium; then
    echo "Chromium installed successfully!"
else
    echo "Failed to install Chromium!"
    exit 1
fi

# make sure rpm-ostree is in idle state by now
wait_for_rpm_ostree

# enable autologin in gnome display manager
echo "Configuring autologin in GDM..."
if sed -i '/\[daemon\]/a AutomaticLoginEnable=true\nAutomaticLogin=test\nDefaultSession=openbox' /etc/gdm/custom.conf; then
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

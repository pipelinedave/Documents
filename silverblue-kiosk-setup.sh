#!/bin/bash

# ---------------------------------------------------------------------------
# This script sets up a kiosk system on Fedora Silverblue with Openbox and
# Chromium. It installs two scripts to /usr/local/bin, executes the first one,
# which updates the system, installs necessary packages, and sets up a one-time
# systemd service to run the second script after a system reboot. The system is
# then rebooted. After the reboot, the second script sets up Openbox and
# Chromium and disables the systemd service that ran it, cleaning up after
# itself.
#
# Usage: Execute this script with root privileges.
# ---------------------------------------------------------------------------

# Define where to install the scripts. /usr/local/bin is commonly on the PATH.
install_path="/usr/local/bin"

# Install the first script
echo '#!/bin/bash
# ---------------------------------------------------------------------------
# This script performs an update of the system and installs the necessary
# packages for running a kiosk system with Openbox and Chromium.
#
# After installing the packages, it sets up a one-time systemd service to
# run a second script upon system restart, and then initiates a system reboot.
# ---------------------------------------------------------------------------

# update the system
rpm-ostree upgrade

# install openbox and chromium
rpm-ostree install openbox chromium

# create a systemd service to run the next script on boot
echo "[Unit]
Description=Run script after reboot

[Service]
ExecStart=/usr/local/bin/silverblue-kiosk-postreboot.sh
Type=oneshot
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
" > /etc/systemd/system/after-reboot.service

# enable the service
systemctl enable after-reboot.service

# restart the system
systemctl reboot' > $install_path/silverblue-kiosk-prereboot.sh

chmod +x $install_path/silverblue-kiosk-prereboot.sh

# Install the second script
echo '#!/bin/bash
# ---------------------------------------------------------------------------
# This script is intended to run after a system reboot initiated by the first
# script. It sets up Openbox to start automatically on boot, and configures
# Chromium to start in kiosk mode when Openbox starts.
#
# After setting up Openbox and Chromium, it disables itself from running again
# on the next boot, effectively cleaning up after itself.
# ---------------------------------------------------------------------------

# disable the after-reboot service (clean up)
systemctl disable after-reboot.service


# enable autologin in gnome display manager
echo "AutomaticLoginEnable=true
AutomaticLogin=test
DefaultSession=openbox" > /etc/gdm/custom.conf


mkdir -p /home/kiosk/.config/openbox
echo "chromium-browser --kiosk --no-first-run '\''https://khm.de'\'' &
" > /home/kiosk/.config/openbox/autostart' > $install_path/silverblue-kiosk-postreboot.sh

chmod +x $install_path/silverblue-kiosk-postreboot.sh

# Execute the first script
$install_path/silverblue-kiosk-prereboot.sh

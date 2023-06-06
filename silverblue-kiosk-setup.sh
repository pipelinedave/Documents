#!/bin/sh

# ---------------------------------------------------------------------------
# This script performs an update of the system and installs the necessary
# package for running a kiosk system with GNOME's single-application mode and Chromium.
# It is meant to be run right after a fresh install of Fedora Silverblue.
#
# After installing the package, it configures autologin in GDM and configures GNOME's single-application mode to autostart Chromium in kiosk mode.
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

echo "Installing Chromium"
if rpm-ostree install chromium; then
    echo "Chromium installed successfully!"
else
    echo "Failed to install Chromium!"
    exit 1
fi

# make sure rpm-ostree is in idle state by now
wait_for_rpm_ostree

# create kiosk user
echo "Creating kiosk user..."
if useradd -m kiosk; then
    echo "Kiosk user created successfully!"
else
    echo "Failed to create kiosk user!"
    exit 1
fi

# set the default session for user kiosk to session kiosk
echo "Setting default session for kiosk user..."
if echo "[User]\nXSession=kiosk" > /var/lib/AccountsService/users/kiosk; then
    echo "Default session for kiosk user set successfully!"
else
    echo "Failed to set default session for kiosk user!"
    exit 1
fi

# create a launchable desktop file for our kiosk session
echo "Creating desktop file for kiosk session..."
if echo "[Desktop Entry]\nName=Kiosk\nComment=Kiosk session\nExec=/usr/bin/gnome-session --session=kiosk\nTryExec=/usr/bin/gnome-session\nIcon=" > /usr/share/xsessions/kiosk.desktop; then
    echo "Desktop file for kiosk session created successfully!"
else
    echo "Failed to create desktop file for kiosk session!"
    exit 1
fi

# define the kiosk session /usr/share/gnome-sessions/kiosk.session
echo "Defining kiosk session..."
if echo "[GNOME Session]
Name=kiosk
RequiredComponents=kiosk-shell;org.gnome.Shell;org.gnome.SettingsDaemon.A11ySettings;org.gnome.SettingsDaemon.Color;org.gnome.SettingsDaemon.Datetime;org.gnome.SettingsDaemon.Housekeeping;org.gnome.SettingsDaemon.Keyboard;org.gnome.SettingsDaemon.MediaKeys;org.gnome.SettingsDaemon.Power;org.gnome.SettingsDaemon.PrintNotifications;org.gnome.SettingsDaemon.Rfkill;org.gnome.SettingsDaemon.ScreensaverProxy;org.gnome.SettingsDaemon.Sharing;org.gnome.SettingsDaemon.Smartcard;org.gnome.SettingsDaemon.Sound;org.gnome.SettingsDaemon.UsbProtection;org.gnome.SettingsDaemon.Wacom;org.gnome.SettingsDaemon.XSettings;" > /usr/share/gnome-sessions/kiosk.session; then
    echo "Kiosk session defined successfully!"
else
    echo "Failed to define kiosk session!"
    exit 1
fi

# create a kiosk-shell.desktop file for our kiosk session
echo "Creating kiosk-shell.desktop file for kiosk session..."
if echo "[Desktop Entry]\nName=Kiosk Shell\nComment=Kiosk Shell\nExec=/usr/bin/gnome-shell --mode=kiosk\nTryExec=/usr/bin/gnome-shell --mode=kiosk\nIcon=" > /usr/share/applications/kiosk-shell.desktop; then
    echo "Kiosk-shell.desktop file for kiosk session created successfully!"
else
    echo "Failed to create kiosk-shell.desktop file for kiosk session!"
    exit 1
fi

# create a kiosk-shell mode for gnome-shell
echo "Creating kiosk-shell mode for gnome-shell..."
if echo "{
    "parentMode": "user",
    "panel": { "left": ["activities", "appMenu"],
               "center": [],
               "right": ["aggregateMenu"]
    }
}" > /usr/share/gnome-shell/modes/kiosk.json; then
    echo "Kiosk-shell mode for gnome-shell created successfully!"
else
    echo "Failed to create kiosk-shell mode for gnome-shell!"
    exit 1
fi

# enable autologin in gnome display manager
echo "Configuring autologin in GDM..."
if sed -i '/\[daemon\]/a AutomaticLoginEnable=true\nAutomaticLogin=test' /etc/gdm/custom.conf; then
    echo "Autologin configured successfully!"
else
    echo "Failed to configure autologin!"
    exit 1
fi

# # reboot the system
# echo "Rebooting the system..."
# if systemctl reboot; then
#     echo "System reboot initiated!"
# else
#     echo "Failed to initiate system reboot!"
#     exit 1
# fi

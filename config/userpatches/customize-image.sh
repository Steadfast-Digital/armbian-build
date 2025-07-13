#!/bin/bash
set -euo pipefail
# This script is executed within the chroot of the new OS image

echo "==> [Bastion] Starting Final Image Customization..."

# The build runs from the 'build' dir, so our scripts are one level up
INSTALL_SCRIPTS_SOURCE="../userpatches/install.d"
INSTALL_SCRIPTS_DEST="/root/install-scripts"

# --- 1. Copy our entire payload into the image ---
echo "  -> Copying installation payload..."
cp -r "${INSTALL_SCRIPTS_SOURCE}" "${INSTALL_SCRIPTS_DEST}"
chmod +x "${INSTALL_SCRIPTS_DEST}"/*

# --- 2. Execute all installation scripts in order ---
echo "  -> Executing payload scripts..."
# The number prefixes on the scripts control the execution order
run-parts --exit-on-error --verbose "${INSTALL_SCRIPTS_DEST}"

# --- 3. Configure Kodi for a seamless appliance experience ---
echo "  -> Configuring Kodi for auto-start..."
# This override ensures Kodi runs as the correct user with display access
mkdir -p /etc/systemd/system/kodi.service.d
cat <<'EOT' > /etc/systemd/system/kodi.service.d/override.conf
[Service]
User=bastion
Group=bastion
# Ensure Kodi can access the display and render correctly
Environment=DISPLAY=:0
ExecStart=
ExecStart=/usr/bin/kodi --standalone
Restart=on-failure
RestartSec=5
EOT

# Enable the service for boot
systemctl enable kodi.service

# --- 4. Final Cleanup ---
echo "  -> Cleaning up payload files..."
rm -rf "${INSTALL_SCRIPTS_DEST}"

echo "==> [Bastion] Final Image Customization Complete."

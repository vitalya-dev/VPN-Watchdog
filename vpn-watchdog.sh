#!/bin/bash

# ==========================================
# Configuration
# ==========================================
TARGET="10.29.0.1"
SERVICE="openvpn3-session@antizapret.service"
SYSTEMCTL="/usr/bin/systemctl"
LOCKFILE="/tmp/vpn-watchdog.lock"

# ==========================================
# Protection: Single Instance Check (Locking)
# ==========================================
# Open a file descriptor (200) to the lockfile
exec 200>"$LOCKFILE"

# Try to acquire an exclusive lock on the file.
# '-n' means fail immediately if locked (don't wait).
if ! flock -n 200; then
    # Optional: Log that we skipped execution (usually not needed to keep logs clean)
    logger -t vpn-watchdog "Script is already running. Skipping."
    exit 1
fi

# ==========================================
# Main Logic
# ==========================================

# 1. Check if service is active. If not, do nothing (assume manual stop).
if ! $SYSTEMCTL is-active --quiet "$SERVICE"; then
    exit 0
fi

# 2. Ping Local DNS. If fail, restart service.
if ! ping -c 3 -W 5 "$TARGET" > /dev/null 2>&1; then
    logger -t vpn-watchdog "Ping to $TARGET failed. Restarting VPN..."

    $SYSTEMCTL restart "$SERVICE"

    sleep 10
    logger -t vpn-watchdog "VPN restarted."
else
    # Connection is good.
    # (Uncomment the line below if you want verbose logs every minute)
    # logger -t vpn-watchdog "Ping to $TARGET successful. Connection OK."
    :
fi

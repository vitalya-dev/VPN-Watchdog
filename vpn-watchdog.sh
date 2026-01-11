#!/bin/bash

# ==========================================
# Configuration
# ==========================================
# The exact name of your connection in NetworkManager
VPN_NAME="antizapret-client-(vtikvn.servebeer.com)(1)"

# The internal IP to ping to verify connectivity
TARGET="10.29.0.1"

# Commands
NMCLI="/usr/bin/nmcli"
LOCKFILE="/tmp/vpn-watchdog.lock"

# ==========================================
# Protection: Single Instance Check (Locking)
# ==========================================
# Open a file descriptor (200) to the lockfile
exec 200>"$LOCKFILE"

# Try to acquire an exclusive lock on the file.
# '-n' means fail immediately if locked (don't wait).
if ! flock -n 200; then
    # Script is already running. Exit silently.
    exit 1
fi

# ==========================================
# Main Logic
# ==========================================

# 1. Check if the VPN connection is currently active.
# We interpret "Active" as currently connected in NetworkManager.
# If it is NOT active, we assume the user stopped it manually and we exit.
if ! "$NMCLI" connection show --active "$VPN_NAME" > /dev/null 2>&1; then
    # VPN is not active. Doing nothing to avoid unwanted auto-connects.
    exit 0
fi

# 2. Ping Local DNS/Target. If fail, restart connection.
if ! ping -c 3 -W 5 "$TARGET" > /dev/null 2>&1; then
    logger -t vpn-watchdog "Ping to $TARGET failed. Restarting VPN connection '$VPN_NAME'..."

    # Force the connection down first to ensure a clean state
    "$NMCLI" connection down "$VPN_NAME"

    # Wait a moment for the interface to clear
    sleep 5

    # Bring the connection back up
    if "$NMCLI" connection up "$VPN_NAME"; then
        logger -t vpn-watchdog "VPN '$VPN_NAME' restarted successfully."
    else
        logger -t vpn-watchdog "Failed to restart VPN '$VPN_NAME'."
    fi
else
    # Connection is good.
    # Uncomment the line below for verbose logging
    # logger -t vpn-watchdog "Ping to $TARGET successful. Connection OK."
    :
fi

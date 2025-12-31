#!/bin/bash

# Configuration
TARGET="10.29.0.1"
SERVICE="openvpn3-session@antizapret.service"

# Use absolute path for systemctl (Crucial for Cron)
SYSTEMCTL="/usr/bin/systemctl"

# 1. Check if service is active. If not, do nothing (assume manual stop).
if ! $SYSTEMCTL is-active --quiet "$SERVICE"; then
    exit 0
fi

# 2. Ping Local DNS. If fail, restart service. If success, log status.
if ! ping -c 3 -W 5 "$TARGET" > /dev/null 2>&1; then
    # Log to syslog so you can see it in journalctl
    logger -t vpn-watchdog "Ping to $TARGET failed. Restarting VPN..."
    
    $SYSTEMCTL restart "$SERVICE"
    
    sleep 10
    logger -t vpn-watchdog "VPN restarted."
else
    # Do nothing if successful
    :
fi

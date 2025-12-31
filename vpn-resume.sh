#!/bin/sh
if [ "${1}" == "post" ]; then
    # Force a check immediately upon waking up
    logger -t vpn-watchdog "Force a check immediately upon waking up."
    /home/vitalya/Projects/VPS-Traffic-Report/vpn-watchdog.sh
fi

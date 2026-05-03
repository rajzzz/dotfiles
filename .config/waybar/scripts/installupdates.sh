#!/usr/bin/env bash

set -u -o pipefail

if ! command -v yay >/dev/null 2>&1; then
    echo "Missing dependency: yay"
    exit 1
fi

if command -v checkupdates >/dev/null 2>&1; then
    echo "Pacman updates:"
    checkupdates || true
else
    echo "checkupdates not found."
fi

echo "AUR updates:"
yay -Qua || true
echo

read -r -n1 -p 'Update the system? [Y/n] ' UPD
echo

exit_code=0
if [[ "$UPD" == "Y" || "$UPD" == "y" || -z "$UPD" ]]; then
    if ! yay --noconfirm -Syu; then
        exit_code=1
    fi
else
    echo "Update cancelled."
fi

if command -v pkill >/dev/null 2>&1; then
    pkill -RTMIN+8 waybar >/dev/null 2>&1 || true
fi

exit "$exit_code"

#!/bin/bash
# One-time system setup for the home lab. Run as root (pkexec/sudo).
set -euo pipefail
USER_NAME=${1:?user}

echo "==> Installing GIMP"
pacman -S --needed --noconfirm gimp >/dev/null

echo "==> Letting $USER_NAME use Docker without a password"
usermod -aG docker "$USER_NAME"

echo "==> Done"

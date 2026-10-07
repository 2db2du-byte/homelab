#!/bin/bash
# Wipe the home lab drive and set it up encrypted (LUKS2). It unlocks automatically on this
# laptop with a key file kept on the (already encrypted) internal drive, and a printed
# recovery key opens it anywhere else. Run as root.
set -euo pipefail

SERIAL="CHANGE_ME"        # the 1TB HGST home lab drive - refuse to touch anything else
OWNER="$USER"
MNT="/mnt/homelab"
KEY="/etc/cryptsetup-keys.d/homelab.key"

DEV=$(lsblk -dno NAME,SERIAL | awk -v s="$SERIAL" '$2 == s {print "/dev/" $1}')
[ -n "$DEV" ] || { echo "Drive with serial $SERIAL not found - stopping."; exit 1; }
[ "$(lsblk -dno SIZE -b "$DEV")" -eq 1000204886016 ] || { echo "$DEV isn't the expected size - stopping."; exit 1; }
echo "==> Encrypting $DEV ($(lsblk -dno MODEL "$DEV"), serial $SERIAL)"

# Release the drive
umount "$MNT" 2>/dev/null || true
[ -e /dev/mapper/homelab ] && cryptsetup close homelab
for part in $(lsblk -lno NAME "$DEV" | tail -n +2); do
  umount "/dev/$part" 2>/dev/null || true
  wipefs -a "/dev/$part" >/dev/null || true
done
sed -i '\#[[:space:]]/mnt/homelab[[:space:]]#d' /etc/fstab
sed -i '/^homelab[[:space:]]/d' /etc/crypttab 2>/dev/null || true

# Fresh partition
wipefs -a "$DEV" >/dev/null
parted -s "$DEV" mklabel gpt mkpart homelab 1MiB 100%
udevadm settle
PART="${DEV}1"
umount "$PART" 2>/dev/null || true
wipefs -a "$PART" >/dev/null

# Keys: a random key file for this laptop + a recovery key for humans
install -d -m 700 /etc/cryptsetup-keys.d
head -c 64 /dev/urandom > "$KEY"
chmod 400 "$KEY"
# Read a fixed amount of randomness first: cutting a pipe from /dev/urandom short trips pipefail.
RAW=$(head -c 2048 /dev/urandom | LC_ALL=C tr -dc 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789')
RECOVERY=$(printf '%s' "${RAW:0:24}" | sed 's/.\{4\}/&-/g; s/-$//')
[ ${#RECOVERY} -eq 29 ] || { echo "couldn't generate a recovery key - stopping"; exit 1; }

printf '%s' "$RECOVERY" | cryptsetup luksFormat --type luks2 --batch-mode --label homelab-crypt "$PART" -
printf '%s' "$RECOVERY" | cryptsetup luksAddKey --key-file=- "$PART" "$KEY"
cryptsetup open --key-file "$KEY" "$PART" homelab
mkfs.ext4 -q -L homelab -m 1 /dev/mapper/homelab

# Unlock + mount automatically when present; boot normally when it isn't (nofail)
LUKS_UUID=$(cryptsetup luksUUID "$PART")
echo "homelab  UUID=$LUKS_UUID  $KEY  luks,nofail,x-systemd.device-timeout=10s" >> /etc/crypttab
echo "/dev/mapper/homelab  $MNT  ext4  defaults,noatime,nofail,x-systemd.device-timeout=10s  0 2" >> /etc/fstab
systemctl daemon-reload
mkdir -p "$MNT"
mount "$MNT"
chown "$OWNER:$OWNER" "$MNT"

echo "==> Done"
df -h "$MNT" | tail -1
echo
echo "RECOVERY KEY: $RECOVERY"

#!/bin/sh
set -euo pipefail

# ==============================
# CONFIG — CHANGE IF NEEDED
# ==============================
TARGET="/dev/sdb"            # USB2 device
ISO_MOUNT="/media/usb"       # ISO mountpoint from USB1
BOOT="${TARGET}1"
VAR="${TARGET}2"
HOME="${TARGET}3"

BOOT_SIZE_MIB=1024
VAR_SIZE_MIB=10240
# ==============================

echo "=============================================="
echo "  Alpine Diskless USB2 Preparation Script"
echo "  TARGET DISK: $TARGET"
echo "=============================================="
echo
read -p "!!! ALL DATA ON $TARGET WILL BE LOST !!! Type YES to continue: " CONFIRM
[ "$CONFIRM" = "YES" ] || { echo "AbORTED."; exit 1; }

# ------------------------------
# 0. Initial setup (eth/wlan, dns, apk repos)
# ------------------------------
echo ">>> Initial network and repository setup"
setup-interfaces
rc-service networking restart
setup-dns
setup-apkrepos

# ------------------------------
# 1. Required tools
# ------------------------------
echo ">>> Installing required tools"
apk add --no-cache parted syslinux dosfstools e2fsprogs util-linux alpine-conf

# ------------------------------
# 2. Wipe disk
# ------------------------------
echo ">>> Wiping old signatures and partition table"
wipefs -a "$TARGET" || true
dd if=/dev/zero of="$TARGET" bs=1M count=8 2>/dev/null || true

# ------------------------------
# 3. Partition USB2
# ------------------------------
echo ">>> Creating partitions"
parted -s "$TARGET" mklabel msdos

# /boot
parted -s "$TARGET" mkpart primary fat32 1MiB "${BOOT_SIZE_MIB}MiB"
parted -s "$TARGET" set 1 boot on

# /var
parted -s "$TARGET" mkpart primary ext4 "${BOOT_SIZE_MIB}MiB" \
  "$((BOOT_SIZE_MIB + VAR_SIZE_MIB))MiB"

# /home
parted -s "$TARGET" mkpart primary ext4 \
  "$((BOOT_SIZE_MIB + VAR_SIZE_MIB))MiB" 100%

partprobe "$TARGET"
sleep 2

# ------------------------------
# 4. Format filesystems
# ------------------------------
echo ">>> Formatting filesystems"
mkfs.vfat -F32 "$BOOT"
mkfs.ext4 -F "$VAR"
mkfs.ext4 -F "$HOME"

# ------------------------------
# 5. Create /boot using setup-bootable
# ------------------------------
echo ">>> Creating boot partition with setup-bootable"
[ -d "$ISO_MOUNT" ] || { echo "ISO not mounted at $ISO_MOUNT"; exit 1; }

setup-bootable "$ISO_MOUNT" "$BOOT"

# ------------------------------
# 6. Edit syslinux.cfg on /boot to set correct disk
# ------------------------------
echo ">>> Editing syslinux.cfg on /boot to set correct disk"
mkdir -p /media/boot
mount "$BOOT" /media/boot
SYS_CFG="/media/boot/boot/syslinux/syslinux.cfg"
if [ -f "$SYS_CFG" ]; then
  sed -i -E \
  -e '/^APPEND /{
        /modules=/{
          /modules=[^ ]*ext4/! s/(modules=[^ ]*)/\1,ext4/
        }
        /apkovl=/! s|$| apkovl=sda2|
      }' "$SYS_CFG"
  # sed -i -E \
  # -e '/^APPEND /{
  #       /modules=/{
  #         /modules=[^ ]*ext4/! s/(modules=[^ ]*)/\1,ext4/
  #       }
  #       /apkovl=disk\/by-uuid\//! s|$| apkovl=disk/by-uuid/'"$UUID_VAR"'|
  #     }' "$SYS_CFG"
  echo "Edited $SYS_CFG to set root=$TARGET"
else
  echo "WARNING: $SYS_CFG not found, skipping edit."
fi
umount /media/boot
rmdir /media/boot

# ------------------------------
# 6. Copy /var data to USB2
# ------------------------------
echo ">>> Copying /var data to USB2"
# This ONLY wires VARFS + LBU semantics (does NOT touch /boot)
mkdir -p /media/var
mount "$VAR" /media/var
cp -a /var/* /media/var/
touch /media/var/.boot_repository
umount /media/var
rmdir /media/var

# ------------------------------
# 7. Copy finish script to /boot
# ------------------------------
echo ">>> Copying finish script to /boot"
mkdir -p /media/boot
mount "$BOOT" /media/boot
cp /media/usb/finish_usb2_diskless2.sh /media/boot/
umount /media/boot
rmdir /media/boot

# ------------------------------
# 8. Finished
# ------------------------------
echo "=============================================="
echo " USB2 PREPARATION COMPLETE"
echo "----------------------------------------------"
echo " Next steps:"
echo "  1. Poweroff now"
echo "  2. Remove USB1"
echo "  3. Boot from USB2 only"
echo "  4. Execute: finish_usb2_diskless.sh from /media/usb"
echo "=============================================="

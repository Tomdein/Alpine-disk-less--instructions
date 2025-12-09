#!/bin/sh
set -euo pipefail

# ==============================
# CONFIG — CHANGE IF NEEDED
# ==============================
TARGET="/dev/sda"            # USB2 device
VAR="${TARGET}2"
HOME="${TARGET}3"
# ==============================

echo "=============================================="
echo "  Alpine Diskless USB2 Finishing Script"
echo "  TARGET DISK: $TARGET"
echo "=============================================="
echo
read -p "Type YES to continue: " CONFIRM
[ "$CONFIRM" = "YES" ] || { echo "AbORTED."; exit 1; }

# # ------------------------------
# # 0. Initial setup (eth/wlan, dns, apk repos)
# # ------------------------------
# echo ">>> Initial network and repository setup"
# setup-interfaces
# rc-service networking restart
# setup-dns
# setup-apkrepos

# ------------------------------
# 1. Update fstab on USB2 to mount /var and /home
# ------------------------------
echo ">>> Updating /etc/fstab on USB2"

# Get UUIDs of VAR and HOME partitions
for i in $(blkid "$VAR"); do
  case "$i" in UUID=*)
    UUID_VAR=${i#UUID=} # Remove UUID= prefix
    UUID_VAR=${UUID_VAR//\"/} # Remove '"' chars
    echo "Found VAR UUID: $UUID_VAR";;
  esac
done

for i in $(blkid "$HOME"); do
  case "$i" in UUID=*)
    UUID_HOME=${i#UUID=} # Remove UUID= prefix
    UUID_HOME=${UUID_HOME//\"/} # Remove '"' chars
    echo "Found HOME UUID: $UUID_HOME";;
  esac
done

# Delete existing /var and /home entries
sed -i -e '/[[:space:]]\/var[[:space:]]/d' /etc/fstab
sed -i -e '/[[:space:]]\/home[[:space:]]/d' /etc/fstab

printf "UUID=%s\t/var\t\text4\tdefaults 1 2\n" "$UUID_VAR" >> /etc/fstab
printf "UUID=%s\t/home\t\text4\tdefaults 1 2\n" "$UUID_HOME" >> /etc/fstab

mount -a
mount -o remount -a

service syslog --quiet condrestart

# ------------------------------
# 2. Run setup-alpine
# ------------------------------

# # setup-alpine runs setup-disk, which moves /var to /.var on entry... Use -q == quick mode to skip disk setup.
# setup-alpine -q

setup-keymap
setup-hostname
setup-interfaces
rc-service networking restart
setup-dns

# run all skipped setup steps manually
echo
print_heading2 " Root Password"
print_heading2 "---------------"
while ! $MOCK passwd ; do
  echo "Please retry."
done

setup-timezone
setup-proxy
setup-sshd
setup-ntp

# ------------------------------
# 3. Setup apk cache
# ------------------------------
echo ">>> Setting up apk cache on /var/cache/apk"
mkdir -p /var/cache/apk
ln -s /var/cache/apk /etc/apk/cache

# ------------------------------
# 4. Setup LBU
# ------------------------------
echo ">>> Setting up LBU to store configs on /media/usb or /media/sda1"
setup-lbu

# ------------------------------
# 5. Finished
# ------------------------------
echo "=============================================="
echo " Alpine linux in diskless mode on single disk is ready!"
echo "=============================================="

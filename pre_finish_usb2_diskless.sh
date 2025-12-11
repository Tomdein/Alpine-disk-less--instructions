#!/bin/sh
# set -euo pipefail

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

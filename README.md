# Alpine-disk-(less)-instructions
Instructions on how to install diskless Alpine Linux with persistent data on the same disk
---
Are you on day 3 of trying to install the Alpine Linux onto the USB so it runs diskless (loads the kernel and FS (filesystem) into RAM) while having the persistent data on the **same** USB?

Do you also want the /home be persistent on the **same** USB?

Did you found out after 3 days, that the `setup-*` scripts usually format the USB along with all the partitions you painstakingly created for the 50th time? 

Are you tired of going through the `setup-alpine` for the 100th time (BTW... You can `ctrl+c` after the apk repo setup) 

Then this guide is for you!

---

# Desired result
Single drive (SSD/USB...) with:
- (Mostly) Imutable OS partition
- Persistent /var partition
- Persistent /home partition
---
# TLDR
1. Create bootable USB1 with [Alpine Linux ISO](https://alpinelinux.org/downloads/)
2. Copy the scripts from this repo onto the USB1 drive.
3. Connect USB1 with the ISO and boot it (so it is /dev/sds).
4. Connect the target USB2 for install (so it is /dev/sdb).
5. Run `prepare_diskless.sh` script.
6. Disconnect USB1 with ISO
7. Reboot
8. Run the `finish_diskless.sh` form `/media/usb` or `/media/sdaX`
9. **Run `lbu commit` or equivalent (`lbu ci`)!**
10. Profit
---
# How does this work
It's basically a combination of `setup-*` scripts, disk formatting and copying.

## First
you set up the Internet and apk repository (first few steps in`setup-alpine`) so you can format the USB2 after installing dosfstools and util-linux

## Second
you format the drive with the desired partitions. I did them like so:
- sdb1 - bootable vfat (vfat, Mark as bootable) for OS and initram FS
- sdb2 - ext4 partition for /var
- sdb3 - Ext4 partition for /home

Here you could change the size or add another partition for example adding separate partition for `lbu` or `apk` cache

## Third
you run `setup-bootable` to setup OS and FS on the USB2 (/dev/sdb1) and copy the second part of the script on the /dev/sdb1

# Fourth

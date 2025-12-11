# Alpine-disk-(less)-instructions
Instructions on how to install diskless Alpine Linux with persistent data on the same disk
---
Are you on day 3 of trying to install the Alpine Linux onto the USB so it runs diskless (loads the kernel and FS (filesystem) into RAM) while having the persistent data on the **same** USB?

Do you also want the /home be persistent on the **same** USB?

Did you found out after 3 days, that the `setup-*` scripts usually format the USB along with all the partitions you painstakingly created for the 50th time? 

Are you tired of going through the `setup-alpine` for the 100th time (BTW... You can `ctrl+c` after the apk repo setup) 

This guide is for you!
---
# Desired result
Single drive (SSD/USB...) with:
- (Mostly) Imutable OS partition
- Persistent /var partition
- Persistent /home partition
---
# TLDR
- Create bootable USB1 with [Alpine Linux ISO](https://alpinelinux.org/downloads/)
- Copy the scripts from this repo onto the USB1 drive.
- Connect USB1 with the ISO and boot it (so it is /dev/sds).
- Connect the target USB2 for install (so it is /dev/sdb).
- Run `prepare_diskless.sh` script.
- Disconnect USB1 with ISO
- Reboot
- Run the `finish_diskless.sh` form `/media/usb` or `/media/sdaX`
- **Run `lbu commit` or equivalent (`lbu ci`)!**
- Profit

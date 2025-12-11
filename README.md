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
you run `setup-bootable` to setup OS and FS on the USB2 (/dev/sdb1) 

copy the second part of the script on the /dev/sdb1

edit syslinux conf (bootloader conf) so it loads lbu overlays from the second partition

## Fourth
you remove USB1 and reboot. Then you run the `finish_diskless.sh` which is basically a extracted `setup-alpine` without the last disks part (that always formats the disk) and a lbu and apk cache setup.

# Install and boot from the same USB
It should be possible if you backup the necessary folders to RAM (ramfs) before formatting the 'USB2' (now only USB1)

So if you combine this guide and [this](https://www.reddit.com/r/AlpineLinux/s/0oJiaCLPjN) (up to 13):
```
if you built your alpine from an iso you have to unmount the usb from the live system and then recreate it from the live system using a copy of itself. 
In a nutshell

1. Boot from your USB
2. do a quick setup-alpine (you really just need network and apkrepos working at this point)
3. apk add wipefs
4. figure out your usb device path (like /dev/sda)
5. cp your mounted alpine base from usb to a backup dir in the ramdrive. ( mkdir /media/backup && cp -a /media/sdX/* /media/backup/ )
6. cp your modloop dir to a backup location (mkdir /modloop.bak && cp -a /.modloop/* /modloop.bak/ )
7. stop modloop (rc-service modloop stop)
8. unmount your usb drive from the live system (umount /media/sdX)
9. copy your backups into their old locations so that everything looks just like it did when the system booted (cp /modloop blah blah blah) 
10. wipe your USB (wipefs --all /dev/sdX) <- **if something goes wrong from here out, you'll have to remake your alpine install media from scratch. THIS IS YOUR WARNING**
11. use fdisk to create a bootable vfat partition on your now empty usb . Don't forget to set the partition type to win95 fat. Also don't forget to set the partition as bootable.
12. make a vfat filesystem in the new partition (mkfs.vfat /dev/sdX1)
13. use alpine setup-bootable to do the rest (setup-bootable /media/sdX /dev/sdX1)
14. reboot the system off this usb again. It will behave exactly like it did before
15. run your setup-alpine as normal except at the end, when it asks which disk to install to, specify none. Then it will ask you something about somewhere to store your changes, you should specify usb. 
16. run lbu ci . 
17. read the documentation on using lbu with an alpine diskless system.
```

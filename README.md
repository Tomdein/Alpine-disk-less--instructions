# Alpine-disk-(less)-instructions
Instructions on how to install diskless Alpine Linux with persistent data on the same disk
---

Are you on day 3 of trying to install the Alpine Linux onto the USB so it runs diskless (loads the kernel and FS (filesystem) into RAM) while having the persistent data on the **same** USB?

Do you also want the /home be persistent on the **same** USB?

Did you found out after 3 days, that the `setup-*` scripts usually format the USB along with all the partitions you painstakingly created for the 50th time?

Are you tired of going through the `setup-alpine` for the 100th time (BTW... You can `ctrl+c` after the apk repo setup)

Then this guide is for you!


# Desired result
Single drive (SSD/USB...) with:
- (Mostly) Imutable OS partition
- Persistent /var partition
- Persistent /home partition


# TLDR
1. Create bootable USB1 with [Alpine Linux ISO](https://alpinelinux.org/downloads/)
2. Copy the scripts from this repo onto the USB1 drive
3. Connect USB1 with the ISO and boot it (so it is /dev/sda)
4. Connect the target USB2 for install (so it is /dev/sdb)
5. Run `prepare_usb2_diskless.sh` script
6. Disconnect USB1 with ISO
7. Reboot
8. Run the `finish_usb2_diskless.sh` form `/media/usb` or `/media/sdaX`
9. **Run `lbu commit` (or equivalent `lbu ci`)!**
10. Profit

# How does this work
It's basically a combination of `setup-*` scripts, disk formatting and copying.

### First:
you set up the Internet and apk repository (first few steps in`setup-alpine`) so you can format the USB2 after installing dosfstools and util-linux

### Second:
you format the drive with the desired partitions. I did them like so:
- sdb1 - bootable vfat (vfat, Mark as bootable) for OS and initram FS
- sdb2 - ext4 partition for /var
- sdb3 - Ext4 partition for /home

Here you could change the size or add another partition for example adding separate partition for `lbu` or `apk` cache

### Third:
you run `setup-bootable` to setup OS and FS on the USB2 (/dev/sdb1)

copy the second part of the script on the /dev/sdb1

edit syslinux conf (bootloader conf) so it loads lbu overlays from the second partition

### Fourth:
you remove USB1 and reboot. Then you run the `finish_usb2_diskless.sh` which is basically a mounting the partitions using `/etc/fstab`, extracted `setup-alpine` without the last disks part (that always formats the disk) and a [Alpine local backup](https://wiki.alpinelinux.org/wiki/Alpine_local_backup) (lbu) and [Local APK cache](https://wiki.alpinelinux.org/wiki/Local_APK_cache) setup.

Take a look at [`pre_finish_usb2_diskless.sh`](pre_finish_usb2_diskless.sh), [`post_finish_usb2_diskless.sh`](post_finish_usb2_diskless.sh) and step 7 of [`prepare_usb2_diskless.sh`](prepare_usb2_diskless.sh) that uses `sed` on `setup-alpine` and combines them into `finish_usb2_diskless.sh`.

# Explanation for everybody who finds the [Alpine Linux wiki](https://wiki.alpinelinux.org/wiki/Installation) confusing

Basically you this is the compilation of the following parts of the docs:
- [Alternative courses of action](https://wiki.alpinelinux.org/wiki/Installation#Data_Disk_Mode:~:text=courses%20of%20action.-,Alternative%20courses%20of%20action,-Examples%20of%20preparation)
- [Customizable boot device](https://wiki.alpinelinux.org/wiki/Create_a_Bootable_Device#Using_setup-bootable)
- [Using an internal disk for persistent storage](https://wiki.alpinelinux.org/wiki/Diskless_Mode#Using_an_internal_disk_for_persistent_storage)
- [Alpine local backup](https://wiki.alpinelinux.org/wiki/Alpine_local_backup)
- [Local APK cache](https://wiki.alpinelinux.org/wiki/Local_APK_cache)
- [What is the difference between sys, data, and diskless when running setup-alpine or setup-disk?](https://wiki.alpinelinux.org/wiki/Alpine_Linux:FAQ#Why_don't_I_have_man_pages_or_where_is_the_'man'_command?:~:text=What%20is%20the%20difference%20between%20sys%2C%20data%2C%20and%20diskless%20when%20running%20setup%2Dalpine%20or%20setup%2Ddisk%3F)
- [Alpine configuration management scripts](https://wiki.alpinelinux.org/wiki/Alpine_configuration_management_scripts)

### Types of Alpine linux installations:
- system: normal linux install as you know it - debian/ubuntu/raspbian/arch/...
- data: the FS (lets say the whole OS) is loaded to RAM and executed from there with the exception of `/var` that is mounted on **different** drive
- diskless: the FS AND `/var` is loaded to RAM and any changes made are saved using apkovl ([APK overlay](https://wiki.alpinelinux.org/wiki/Alpine_local_backup))

In the data & diskless modes, you can setup [Local APK cache](https://wiki.alpinelinux.org/wiki/Local_APK_cache) so you do not have to download the APKs on every boot as nothing is saved after reboot (only `\var` on data mode)

### My Alpine linux installation:
- Have the OS in RAM like [data/diskless](#types-of-alpine-linux-installations), but save `/var` & `/home` onto 2 separate partitions. You could easily use single partition or create more partitions and mount them

Therefore you need to do:
- Partition the target USB. The OS partition needs to be [bootable](https://wiki.alpinelinux.org/wiki/Create_a_Bootable_Device#:~:text=Create%20a%20partition%20sdXY%20with%20the%20desired%20size%2C%20set%20the%20type%20to%20win95%20fat%2C%20and%20set%20the%20bootable%20flag%20on%20it%2C%20or%20use%20the%20following%20command%20to%20use%20entire%20disk%3A). For this you need to have internet so run `setup-alpine` and `ctrl+c` after you reach [APK repo setup](https://wiki.alpinelinux.org/wiki/Installation#:~:text=Mirror%20(From%20where%20to%20download%20packages.%20Choose%20the%20organization%20you%20trust%20giving%20your%20usage%20patterns%20to.))
- Use `setup-bootable` to create the system with OS
- Copy `/var/` onto partition `/dev/sdb2/` (will be `/dev/sdb2` after you remove the install USB and leave only target USB that is now `sdb2`)
- Edit `/media/boot/boot/syslinux/syslinux.cfg` so `modules` has `,ext4,...` and add `apkovl=sda2` line under the `modules` [like so](#syslinuxcfg). This enables the search of [APK overlay](https://wiki.alpinelinux.org/wiki/Alpine_local_backup) on `ext4` partition `/dev/sda2` (Just as before - the drive is now `sdb`, but will be `sda`)

Now you can poweroff and disconnect install USB -> boot the target USB
- On after booting the target USB you need to mount the partitions - just look at [`pre_finish_usb2_diskless.sh`](pre_finish_usb2_diskless.sh)
- Run `setup-alpine` WITHOUT reaching disk setup at the end - automatically calls `setup-disk` that formats the drive - so you have to carve the `setup-alpine` out. I do it using `sed` in [`prepare_usb2_diskless.sh`](prepare_usb2_diskless.sh)
- Edit `/etc/lbu/lbu.conf` so that the [Alpine local backup](https://wiki.alpinelinux.org/wiki/Alpine_local_backup) is saved at the right location - on the `/var` partition - add `LBU_BACKUPDIR=/var` [like so](#lbuconf)
- [Enable local APK cache](https://wiki.alpinelinux.org/wiki/Local_APK_cache#:~:text=Cache%20can%20also%20be%20manually%20enabled%20by%20creating%20a%20cache%20dir%20and%20then%20symlink%20it%20to%20/etc/apk/cache%3A) - just run:
```
mkdir -p /var/cache/apk
ln -s /var/cache/apk /etc/apk/cache
apk cache sync
```

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

# Example files
### syslinux.cfg
`/boot/syslinux/syslinux.cfg`.

After mounting the USB to `/media/boot`: `/media/boot/boot/syslinux/syslinux.cfg` add
- `ext4` to `modules` list
- `apkovl=sda2`
```
TIMEOUT 10
PROMPT 1
DEFAULT lts

LABEL lts
MENU LABEL Linux lts
KERNEL /boot/vmlinuz-lts
INITRD /boot/initramfs-lts
FDTDIR /boot/dtbs-lts
APPEND modules=loop,squashfs,sd-mod,usb-storage,ext4 quiet  apkovl=sda2
```

### fstab
Edit `/etc/fstab`
```
/dev/cdrom	/media/cdrom	iso9660	noauto,ro 0 0
/dev/usbdisk	/media/usb	vfat	noauto,ro 0 0
UUID=4e8dd10d-a2cd-481a-849b-7c57c0999417	/var		ext4	defaults 1 2
UUID=080485b6-ab6f-4d32-89d0-acedb3f28d8a	/home		ext4	defaults 1 2
```
then `mount -a` to load the new confing

### lbu.conf
In `/etc/lbu/lbu.conf` add
- LBU_BACKUPDIR=/var
```
# what cipher to use with -e option
DEFAULT_CIPHER=aes-256-cbc

# Uncomment the row below to encrypt config by default
# ENCRYPTION=$DEFAULT_CIPHER

# Uncomment below to avoid <media> option to 'lbu commit'
# Can also be set to 'floppy'
# LBU_MEDIA=usb

# Set the LBU_BACKUPDIR variable in case you prefer to save the apkovls
# in a normal directory instead of mounting an external media.
# LBU_BACKUPDIR=/root/config-backups

# Uncomment below to let lbu make up to 3 backups
# BACKUP_LIMIT=3
LBU_BACKUPDIR=/var
```
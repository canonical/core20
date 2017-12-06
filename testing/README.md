This directory contains support scripts boot-testing the base-18 snap.
The test is very crude as you have to do it interactively.

Known issues:
 - there's no root shell yet
 - the initrd used for booting is the one from base-16 (aka current core)

Required tools:
 - fdisk
 - kpartx
 - mkfs.ext4
 - mount and umount
 - qemu-img and qemu-system-x86-64
 - snap
 - sudo
 - wipefs

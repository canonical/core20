This directory contains support scripts boot-testing the base-18 snap.
The test is very crude as you have to do it interactively.

After booting move to VT7 by clicking on the qemu window and pressing alt+right
(or left) until you reach the root prompt. If you are running a Wayland session
QEMU may misbehave and print a message mentioning not having some input
keymaps. If that happens you need to log into an X11 session instead.

Known issues:
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

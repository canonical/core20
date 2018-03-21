# XXX: this needs to be in sync with what's in spread.yaml
QEMU_CMD = qemu-system-x86_64 \
	-enable-kvm \
	-smp 2 \
	-m 1500 \
	-netdev user,id=mynet0,hostfwd=tcp::8022-:22,hostfwd=tcp::8090-:80 \
	-device virtio-net-pci,netdev=mynet0 \
	-drive file=core18/image.raw,format=raw \
	-vga qxl \
	-snapshot \
	-kernel kernel \
	-initrd initrd \
	-append "root=LABEL=writable snap_core=core18_very-unstable_amd64.snap snap_kernel=pc-kernel.snap ro net.ifnames=0 init=/lib/systemd/systemd console=tty1 systemd.debug-shell=1"

# Update (or build if missing) and boot the image
.PHONY: update-and-boot
.ONESHELL: update-and-boot
update-and-boot:
	$(MAKE) just-update
	$(MAKE) just-boot

# Update (or build if missing) the image.
.PHONY: just-update
.ONESHELL: just-update
just-update: kernel initrd ../../core18_very-unstable_amd64.snap
	if [ ! -e core18/image.raw ]; then
		# Create some files and directories so that they are all owned by us.
		mkdir -p core18/p1
		mkdir -p core18/p2
		mkdir -p core18/p3
		touch core18/image.raw
		touch core18/image.script
		sudo ./create-image core18
	fi
	# Update (this puts the kernel and new core18 snap inside)
	sudo ./mount-image core18
	sudo cp ../../core18_very-unstable_amd64.snap core18/p3/system-data/var/lib/snapd/snaps/
	sudo cp --dereference pc-kernel.snap core18/p3/system-data/var/lib/snapd/snaps/
	sudo ./umount-image core18

# Just boot the image
.PHONY: just-boot
.ONESHELL: just-boot
just-boot: kernel initrd core18/image.raw
	$(QEMU_CMD)

# Start the image in the background. This is relevant for spread.
.ONESHELL: background-start
.PHONY: background-start
background-start:
	$(QEMU_CMD) -nographic </dev/null >/dev/null 2>&1 & # NOTE: The redirects are relevant for spread.
	echo $$! >qemu.pid
	sleep 10 # ballpark figure, enough to boot.

# Stop the image that (may be) running in the background. This is relevant for spread.
.ONESHELL: background-stop
.PHONY: background-stop
background-stop:
	if [ -e qemu.pid ]; then
		kill "$$(cat qemu.pid)"
		rm -f qemu.pid
	fi

.PHONY: clean
clean:
	rm -f core_*.assert
	rm -f core_*.snap
	rm -f initrd 
	rm -f kernel
	rm -f pc-kernel_*.assert
	rm -f pc-kernel_*.snap
	rm -rf core18
	rm -rf kernel-snap
	rm -rf core-snap
	rm -f core.snap
	rm -f pc-kernel.snap

# Vanilla pc-kernel kernel image
kernel: kernel-snap/kernel.img
	ln -sf "$^" "$@"

# Vanilla base-16 initrd
initrd: core-snap/boot/initrd.img-core
	ln -sf "$^" "$@"

# Vanilla base-16 core snap so that we have an initrd
core.snap:
	snap download core
	ln -sf "$$(find -name "core_*.snap" | sort | tail -1)" "$@"

# Vanilla pc-kernel snap for a kernel to boot.
pc-kernel.snap:
	snap download pc-kernel
	ln -sf "$$(find -name "pc-kernel_*.snap" | sort | tail -1)" "$@"

# Extract the initrd from the (base-16) core snap
core-snap/boot/initrd.img-core: core.snap
	rm -rf core-snap
	unsquashfs -dest core-snap -no-progress "$^" '/boot/initrd.img*' >/dev/null
	touch "$@"

# Extract the kernel image from the pc-kernel snap
kernel-snap/kernel.img: pc-kernel.snap
	rm -rf kernel-snap
	unsquashfs -dest kernel-snap -no-progress "$^" '/kernel.img' >/dev/null
	sudo chmod 0644 "$^"
	touch "$@"

.PHONY: update-and-boot
.ONESHELL: update-and-boot
update-and-boot: kernel initrd ../base-18_very-unstable_amd64.snap
	if [ ! -e base-18/image.raw ]; then
		# Create some files and directories so that they are all owned by us.
		mkdir -p base-18/p1
		mkdir -p base-18/p2
		mkdir -p base-18/p3
		touch base-18/image.raw
		touch base-18/image.script
		sudo ./create-image base-18
	fi
	# Update (this puts the kernel and new base-18 snap inside)
	sudo ./mount-image base-18
	sudo cp ../base-18_very-unstable_amd64.snap base-18/p3/system-data/var/lib/snapd/snaps/
	sudo cp --dereference pc-kernel.snap base-18/p3/system-data/var/lib/snapd/snaps/
	sudo ./umount-image base-18
	# Run the image using qemu
	qemu-system-x86_64 \
		-enable-kvm \
		-smp 2 \
		-m 1500 \
		-netdev user,id=mynet0,hostfwd=tcp::8022-:22,hostfwd=tcp::8090-:80 \
		-device virtio-net-pci,netdev=mynet0 \
		-drive file=base-18/image.raw,format=raw \
		-vga qxl \
		-snapshot \
		-kernel kernel \
		-initrd initrd \
		-append "root=LABEL=writable snap_core=base-18_very-unstable_amd64.snap snap_kernel=pc-kernel.snap ro net.ifnames=0 init=/lib/systemd/systemd console=tty1"

.PHONY: just-boot
.ONESHELL: just-boot
just-boot: kernel initrd base-18/image.raw 
	qemu-system-x86_64 \
		-enable-kvm \
		-smp 2 \
		-m 1500 \
		-netdev user,id=mynet0,hostfwd=tcp::8022-:22,hostfwd=tcp::8090-:80 \
		-device virtio-net-pci,netdev=mynet0 \
		-drive file=base-18/image.raw,format=raw \
		-vga qxl \
		-snapshot \
		-kernel kernel \
		-initrd initrd \
		-append "root=LABEL=writable snap_core=base-18_very-unstable_amd64.snap snap_kernel=pc-kernel.snap ro net.ifnames=0 init=/lib/systemd/systemd console=tty1"

.PHONY: clean
clean:
	rm -f core_*.assert
	rm -f core_*.snap
	rm -f initrd 
	rm -f kernel
	rm -f pc-kernel_*.assert
	rm -f pc-kernel_*.snap
	rm -rf base-18
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
	touch "$@"

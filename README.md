# Core20 snap for snapd

This is a base snap for snapd that is based on Ubuntu 20.04

## Prerequisites

We recommend an ubuntu installed distribution to develop and test for this repository, with atleast the following
installed and available
- Packages: git, snap, qemu-kvm
- Snaps: snapcraft, ubuntu-image, golang

(For a SBC like RPi) you will need UART TTL serial debug cable (Because you will not have SSH in initrd)

# Building locally

To build this snap locally you need snapcraft. The project must be built as real root.

```
$ sudo snapcraft
```

# Testing with spread

## Prerequisites for testing

You need to have the following software installed before you can test with spread
 - Go (https://golang.org/doc/install or ```sudo snap install go```)
 - Spread (install from source as per below)

## Installing spread

You can install spread by simply using ```snap install spread```, however this does not allow for the lxd-backend to be used.
To use the lxd backend you need to install spread from source, as the LXD profile support has not been upstreamed yet.
This document will be updated with the upstream version when this happens. To install spread from source you need to do the following.

```
git clone https://github.com/Meulengracht/spread
cd spread
cd cmd/spread
go build .
go install .
```

## QEmu backend

1. Install the dependencies required for the qemu emulation
```
sudo apt update && sudo apt install -y qemu-kvm autopkgtest
```
2. Create a suitable ubuntu test image (focal) in the following directory where spread locates images. Note that the location is different when using spread installed through snap.
```
mkdir -p ~/.spread/qemu # This location is different if you installed spread from snap
cd ~/.spread/qemu
autopkgtest-buildvm-ubuntu-cloud -r focal
```
3. Rename the newly built image as the name will not match what spread is expecting
```
mv autopkgtest-focal-amd64.img ubuntu-20.04-64.img
```
4. Now you are ready to run spread tests with the qemu backend
```
cd ~/core20 # or wherever you checked out this repository
spread qemu-nested
```

## LXD backend
The LXD backend is the preffered way of testing locally as it uses virtualization and thus runs a lot quicker than
the qemu backend. This is because the container can use all the resources of the host, and we can support
qemu-kvm acceleration in the container for the nested instance.

This backend requires that your host machine supports KVM.

1. Setup any prerequisites and build the LXD image needed for testing. The following commands will install lxd
and yq (needed for yaml manipulation), download the newest image and import it into LXD.
```
sudo snap install lxd --channel=latest/stable
sudo snap install yq --channel=latest/stable
curl -o lxd-core20-img.tar.gz https://storage.googleapis.com/snapd-spread-core/lxd/lxd-spread-core20-img.tar.gz
lxc image import lxd-core20-img.tar.gz --alias ucspread
lxc image show ucspread > temp.profile
yq e '.properties.aliases = "ucspread,amd64"' -i ./temp.profile
yq e '.properties.remote = "images"' -i ./temp.profile
cat ./temp.profile | lxc image edit ucspread
rm ./temp.profile ./lxd-core20-img.tar.gz
```
2. Import the LXD core20 test profile. Make sure your working directory is the root of this repository.
```
lxc profile create core20
cat tests/spread/core20.lxdprofile | lxc profile edit core20
```
3. Set environment variable to enable KVM acceleration for the nested qemu instance
```
export SPREAD_ENABLE_KVM=true
```
4. Now you can run the spread tests using the LXD backend
```
spread lxd-nested
```

# Writing code

The usual way to add functionality is to write a shell script hook
with the `.chroot` extenstion under the `hooks/` directory. These hooks
are run inside the base image filesystem.

Each hook should have a matching `.test` file in the `hook-tests`
directory. Those tests files are run relative to the base image
filesystem and should validates that the coresponding `.chroot` file
worked as expected.

The `.test` scripts will be run after building with snapcraft or when
doing a manual "make test" in the source tree.

# Bootchart

It is possible to enable bootcharts by adding `ubuntu_core.bootchart`
to the kernel command line. The sample collector will run until the
system is seeded (it will stop when the `snapd.seeded.service`
stops). The bootchart will be saved in the `ubuntu-data` partition,
under `/var/log/debug/boot<N>/`, `<N>` being the boot number since
bootcharts were enabled. If a chart has been collected by the
initramfs, it will be also saved in that folder.

**TODO** In the future, we would want `systemd-bootchart` to be started
only from the initramfs and have just one bootchart per boot. However,
this is currently not possible as `systemd-bootchart` needs some changes
so it can survive the switch root between initramfs and data
partition. With those changes, we could also have `systemd-bootchart` as
init process so we get an even more accurate picture.

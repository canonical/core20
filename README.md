# Core18 snap for snapd

This is a base snap for snapd that is based on Ubuntu 18.04

# Building locally

To build this snap locally you need snapcraft. The project must be built as real root.

```
$ sudo snapcraft
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


# Testing locally

Once built you can boot it for testing inside qemu and spread. You will need
additional tool (see tests/lib/README.md for details). In order to prepare an
image for either exploratory manual tests or for spread tests run this command:

```
$ make update-image
```

With this available you can either run: `spread -debug -v` or `make -C
tests/lib just-boot`, depending on what you want to do. The interactive (just
boot) test should allow you to move to VT7 where a root shell awaits.

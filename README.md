# Base 18 snap for snapd

This is a base snap for snapd that is based on Ubuntu 18.04

# Building locally

To build this snap locally you need snapcraft. The project must be built as real root.

```
$ sudo snapcraft
```

Once built you can boot it for testing inside qemu. You will need additional
tool (see testing/README.md for details). To boot test your fresh snap:

```
$ make -C tests/lib
```

You can start to use spread as well. If you have a built image (done by the
command above) you can just run `spread` to run the tests locally.

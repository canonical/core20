#!/bin/sh

set -e

echo "Test that the symlinks for etc/{timezone,localtime,hostname} exist and are correct"
set -x
for f in timezone localtime hostname; do
    test -e $SNAPCRAFT_PRIME/etc/$f;
done

grep "Etc/UTC" $SNAPCRAFT_PRIME/etc/timezone || (cat $SNAPCRAFT_PRIME/etc/timezone ; exit 1)
[ $(readlink -f $SNAPCRAFT_PRIME/etc/localtime) = "/usr/share/zoneinfo/Etc/UTC" ] || (ls -al $SNAPCRAFT_PRIME/etc/localtime ; exit 1)

set +x

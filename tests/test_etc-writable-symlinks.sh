#!/bin/sh

set -e

echo "Test that the symlinks for etc/{timezone,localtime,hostname} exist and are correct"
set -x
for f in timezone localtime hostname; do
    test -e etc/$f;
done

grep "Etc/UTC" etc/timezone || (cat etc/timezone ; exit 1)
[ $(readlink -f etc/localtime) = "/usr/share/zoneinfo/Etc/UTC" ] || (ls -al etc/localtime ; exit 1)

set +x

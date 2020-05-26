#!/bin/sh

set -e

echo "Test that the symlinks for etc/{timezone,localtime,hostname} exist"
set -x
for f in timezone localtime hostname; do
    test -e prime/etc/$f;
done
set +x

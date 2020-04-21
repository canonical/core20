#!/bin/sh -e

TEST_IMPORT=1
# shellcheck disable=SC1091
. static/usr/lib/core/handle-writable-paths

rootmnt="$(mktemp -d)"
trap 'rm -rf "$rootmnt"' EXIT

# test: no _writable_defaults does not break
mkdir -p "$rootmnt/writeable/system-data/"
handle_writable_defaults "$rootmnt"

# test: empty _writable_defaults does not break
mkdir -p "$rootmnt/writable/system-data/_writable_defaults"
handle_writable_defaults "$rootmnt"
test -e "$rootmnt/writable/system-data/_writable_defaults/.done"
# cleanup
rm -f "$rootmnt/writable/system-data/_writable_defaults/.done"

# test: file/dir in _writable_defaults
mkdir -p "$rootmnt/writable/system-data/_writable_defaults/some-dir"
touch "$rootmnt/writable/system-data/_writable_defaults/some-dir/some-file"
touch "$rootmnt/writable/system-data/_writable_defaults/other-file"

handle_writable_defaults "$rootmnt"
# ensure we have the .done file
test -e "$rootmnt/writable/system-data/_writable_defaults/.done"
test -d "$rootmnt/writable/system-data/some-dir"
test -e "$rootmnt/writable/system-data/some-dir/some-file"
test -e "$rootmnt/writable/system-data/other-file"
# cleanup
rm -f "$rootmnt/writable/system-data/_writable_defaults/.done"

#!/bin/bash

print_usage () {
  echo "Usage: busybox-installer.sh (target directory)"
  echo
  echo "The target directory should be a rootfs of the Linux installation where the busybox should be installed."
  echo
  echo "Put the busybox binary on the same folder as this script."
  echo
  echo "Additional files that should be copied to target directory can be put in the 'additional' folder,"
  echo "in which this installer will then copy to target and set the owner/group of these files to root."
  echo "This installer will apply the permission as specified in the file as well."
  exit
}

generic_error_msg () {
  echo "Installer failed. Please clean up partially installed files manually."
}

exit_without_msg () {
  trap EXIT
  exit
}

if [[ $# -ne 1 ]]; then
  print_usage
fi

TARGET_DIR=bin/
BUSYBOX_BIN="$1/$TARGET_DIR/busybox"
BUSYBOX_ABS_BIN=/$TARGET_DIR/busybox

# trap any errors and report to user
set -e
trap generic_error_msg EXIT

# change directory to this script's directory
cd `dirname $BASH_SOURCE`

if ! test -e busybox; then
  echo "The busybox binary is not found in this script's folder."
  exit_without_msg
fi

echo Copying the busybox binary to $TARGET_DIR
cp busybox "$BUSYBOX_BIN"
chown 0:0 "$BUSYBOX_BIN"
chmod 755 "$BUSYBOX_BIN"

echo Creating symlinks ...
# ignore errors when creating these symlinks. files might already exists.
set +e
SYMLIST=`"$BUSYBOX_BIN" --list-full`
for FN in $SYMLIST
do
  SYMPATH="$1/$FN"
  echo "  $SYMPATH"
  ln -s $BUSYBOX_ABS_BIN "$SYMPATH"
  chown 0:0 "$SYMPATH"
  chmod 755 "$SYMPATH"
done

if test -d additional; then
  echo "Found the 'additional' directory. Copying these as well."
  echo Copying to temporary directory ...
  set -e
  TMPDIR=`mktemp -d`
  cp -r additional $TMPDIR/
  echo Setting owner ...
  chown -R 0:0 $TMPDIR/additional
  echo Copying to target ...
  cp -ra --preserve=all $TMPDIR/additional/* "$1/"
  echo Removing temporary directory ...
  rm -r $TMPDIR
fi

echo Done!
exit_without_msg

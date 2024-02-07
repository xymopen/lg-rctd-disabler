#!/sbin/sh
# Do NOT assume where your module will be located.
# ALWAYS use $MODPATH if you need to know where this script
# and module is placed.
# This will make sure your module will still work
# if Magisk change its mount point in the future
MODPATH=${0%/*}

# This script will be executed when Magisk removes your module

MAGISKROOT="/data/adb/magisk"
MAGISKBOOT="$MAGISKROOT/magiskboot"

CPIO_PROG="\
add $(stat -c '%a' "$MODPATH/rctd.bak") sbin/rctd $MODPATH/rctd.bak sbin/rctd\
"

BOOTIMAGE="/dev/block/by-name/boot"

. "$MAGISKROOT/util_functions.sh"

ui_print "- Unpacking boot image"
cat "$BOOTIMAGE" > "boot.img"
if ! "$MAGISKBOOT" unpack "boot.img"; then
    rm -f "boot.img"
    abort "! Unable to unpack boot image"
fi

ui_print "- Adding rctd to ramdisk"
if ! "$MAGISKBOOT" cpio "ramdisk.cpio" "$CPIO_PROG"; then
    rm -f "kernel" "kernel_dtb" "ramdisk.cpio" "boot.img"
    abort "! Unable to add rctd"
fi

ui_print "- Repacking boot image"
if ! "$MAGISKBOOT" repack "boot.img" "new-boot.img"; then
    rm -f "kernel" "kernel_dtb" "ramdisk.cpio" "boot.img"
    abort "! Unable to repack boot image"
fi

ui_print "- Flashing new boot image"
cat "new-boot.img" > "$BOOTIMAGE"

rm -f "kernel" "kernel_dtb" "ramdisk.cpio" "boot.img" "new-boot.img"

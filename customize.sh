#!/sbin/sh

# This script will be _sourced_ (not executed!) by the module installer
# script after all files are extracted and default permissions and
# secontext are applied.

##########################################################################################
# Config Flags
##########################################################################################

# Set to 1 if you would like to fully control
# and customize the installation process, skip
# all default installation steps
SKIPUNZIP=1

##########################################################################################
# Replace list
##########################################################################################

# List all directories you want to directly replace in the system
# Check the documentations for more info why you would need this

# Construct your list in the following format
# This is an example
REPLACE_EXAMPLE="
/system/app/Youtube
/system/priv-app/SystemUI
/system/priv-app/Settings
/system/framework
"

# Construct your own list here
#REPLACE=""

##########################################################################################
#
# The installation framework will export some variables and functions.
# You should use these variables and functions for installation.
#
# ! DO NOT use any Magisk internal paths as those are NOT public API.
# ! DO NOT use other functions in util_functions.sh as they are NOT public API.
# ! Non public APIs are not guranteed to maintain compatibility between releases.
#
# Available variables:
#
# MAGISK_VER (string): the version string of current installed Magisk
# MAGISK_VER_CODE (int): the version code of current installed Magisk
# BOOTMODE (bool): true if the module is currently installing in Magisk Manager
# MODPATH (path): the path where your module files should be installed
# TMPDIR (path): a place where you can temporarily store files
# ZIPFILE (path): your module's installation zip
# ARCH (string): the architecture of the device. Value is either arm, arm64, x86, or x64
# IS64BIT (bool): true if $ARCH is either arm64 or x64
# API (int): the API level (Android version) of the device
#
# Availible functions:
#
# ui_print <msg>
#     Print <msg> to console
#     Avoid using 'echo' as it will not display in custom recovery's console
#
# abort <msg>
#     Print error message <msg> to console and terminate installation
#     Avoid using 'exit' as it will skip the termination cleanup steps
#
# set_perm <target> <owner> <group> <permission> [context]
#     If [context] is empty, it will default to "u:object_r:system_file:s0"
#     This function is a shorthand for the following commands
#       chown owner.group target
#       chmod permission target
#       chcon context target
#
# set_perm_recursive <directory> <owner> <group> <dirpermission> <filepermission> [context]
#     If [context] is empty, it will default to "u:object_r:system_file:s0"
#     This function is a shorthand for the following psuedo code:
#       set_perm <directory> owner group dirpermission context
#       for file in <directory>:
#         set_perm file owner group filepermission context
#       for dir in <directory>:
#         set_perm_recursive dir owner group dirpermission context
#
##########################################################################################
##########################################################################################
# If you need boot scripts, DO NOT use general boot scripts (post-fs-data.d/service.d)
# ONLY use module scripts as it respects the module status (remove/disable) and is
# guaranteed to maintain the same behavior in future Magisk releases.
##########################################################################################

# You can add more code to assist your custom script

MAGISKROOT="/data/adb/magisk"
MAGISKBOOT="$MAGISKROOT/magiskboot"

SED_PROG="\
s/# LG RCT(Rooting Check Tool)//; \
s/service rctd \/sbin\/rctd//; \
s/    class late_start//; \
s/    user root//; \
s/    group root//; \
s/    seclabel u:r:rctd:s0//; \
"

CPIO_PROG="\
rm sbin/rctd\
"

BOOTIMAGE="/dev/block/by-name/boot"

ui_print "- Extracting module files"
unzip -o "$ZIPFILE" module.prop uninstall.sh -d "$MODPATH" >&2

ui_print "- Checking /system/etc/init/init.lge.system.services.rc"
if ! [ -f "/system/etc/init/init.lge.system.services.rc" ]; then
  abort "Couldn't find /system/etc/init/init.lge.system.services.rc"
fi

ui_print "- Checking /sbin/rctd"
if ! [ -x "/sbin/rctd" ]; then
  abort "Couldn't find /sbin/rctd"
fi

mkdir -p "$MODPATH/system/etc/init/"

ui_print "- Removing rctd service"
sed -e "$SED_PROG" "/system/etc/init/init.lge.system.services.rc" > "$MODPATH/system/etc/init/init.lge.system.services.rc"
set_perm "$MODPATH/system/etc/init/init.lge.system.services.rc" $(stat -c '%U %G %a' "/system/etc/init/init.lge.system.services.rc") "$(ls -Z "/system/etc/init/init.lge.system.services.rc" | cut -f1 -d ' ')"

ui_print "- Backing up rctd"
cp -a "/sbin/rctd" "$MODPATH/rctd.bak"

ui_print "- Unpacking boot image"
cat "$BOOTIMAGE" > "boot.img"
if ! "$MAGISKBOOT" unpack "boot.img"; then
    rm -f "boot.img"
    abort "! Unable to unpack boot image"
fi

ui_print "- Removing rctd from ramdisk"
if ! "$MAGISKBOOT" cpio "ramdisk.cpio" "$CPIO_PROG"; then
    rm -f "kernel" "kernel_dtb" "ramdisk.cpio" "boot.img"
    abort "! Unable to remove rctd"
fi

ui_print "- Repacking boot image"
if ! "$MAGISKBOOT" repack "boot.img" "new-boot.img"; then
    rm -f "kernel" "kernel_dtb" "ramdisk.cpio" "boot.img"
    abort "! Unable to repack boot image"
fi

ui_print "- Flashing new boot image"
cat "new-boot.img" > "$BOOTIMAGE"

rm -f "kernel" "kernel_dtb" "ramdisk.cpio" "boot.img" "new-boot.img"

ui_print "- Removing rctd persist files"
rm -rf "/mnt/vendor/persist-lg/rct"
rm -rf "/mnt/product/persist-lg/rct"

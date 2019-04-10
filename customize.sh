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

SED_PROG="\
s/# LG RCT(Rooting Check Tool)//; \
s/service rctd \/system_ext\/bin\/rctd//; \
s/    class late_start//; \
s/    user root//; \
s/    group root//; \
s/    seclabel u:r:rctd:s0//; \
"

mkdir -p "$MODPATH/system/system_ext/etc/init/" "$MODPATH/system/system_ext/bin/"

sed -e "$SED_PROG" "/system_ext/etc/init/init.lge.system_ext.services.rc" > "$MODPATH/system/system_ext/etc/init/init.lge.system_ext.services.rc"
set_perm "$MODPATH/system/system_ext/etc/init/init.lge.system_ext.services.rc" root root 644 "u:object_r:system_file:s0"

touch "$MODPATH/system/system_ext/bin/rctd"
set_perm "$MODPATH/system/system_ext/bin/rctd" root shell 755 "u:object_r:rctd_exec:s0"

rm -rf "/mnt/product/persist-lg/rct"

#! /system/bin/sh

config="$1"

function set_new_prop()
{
   echo "start"
   getprop ro.build.display.wtid
   #ifdef ODM_WT_EDIT
   #Rui.Li@AD.ENGINEERMODE, 2020/04/26, Add for wt vendor version
   setprop ro.vendor.build.display.wtid `getprop ro.build.display.wtid`
   #endif ODM_WT_EDIT

   getprop ro.vendor.build.display.wtid
   echo "end"
}

case "$config" in
    "set_new_prop")
        set_new_prop
    ;;
esac

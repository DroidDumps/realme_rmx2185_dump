#!/sbin/sh

find /data/app/ -name '*.odex' -exec rm "{}" \;
find /data/app/ -name '*.vdex' -exec rm "{}" \;

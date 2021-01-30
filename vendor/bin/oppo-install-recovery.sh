#!/system/bin/sh
if ! applypatch --check EMMC:/dev/block/platform/bootdevice/by-name/recovery:102760448:72d1415a64c1a5925c873acd87b8e5b716f6d706; then
  applypatch  \
          --patch /vendor/recovery-from-boot.p \
          --source EMMC:/dev/block/platform/bootdevice/by-name/spmfw:60384:dfc31a9162fc484622b9d19601079eb027c65909 \
          --target EMMC:/dev/block/platform/bootdevice/by-name/recovery:102760448:72d1415a64c1a5925c873acd87b8e5b716f6d706 && \
      log -t recovery "Installing new oppo recovery image: succeeded" && \
      setprop ro.recovery.updated true || \
      log -t recovery "Installing new oppo recovery image: failed" && \
      setprop ro.recovery.updated false
else
  log -t recovery "Recovery image already installed"
  setprop ro.recovery.updated true
fi

#!/sbin/sh

busybox mkdir -p /data/oppo/coloros/startup
busybox mv /data/system/startup_manager.xml /data/oppo/coloros/startup/
busybox mv /data/system/associate_startup_whitelist.txt /data/oppo/coloros/startup/
busybox mv /data/system/associate_startup_default_list.xml /data/oppo/coloros/startup/
busybox mv /data/system/sys_startupmanager_monitor_list.xml /data/oppo/coloros/startup/
busybox mv /data/system/sys_rom_black_list.xml /data/oppo/coloros/startup/
busybox mv /data/system/fixedRecord.txt /data/oppo/coloros/startup/
busybox mv /data/oppo/boot/autoSyncWhiteList.txt /data/oppo/coloros/startup/
busybox mv /data/oppo/bootallow.txt /data/oppo/coloros/startup/
busybox mv /data/oppo/bootoption.txt /data/oppo/coloros/startup/
busybox mv /data/oppo/bootwhitelist.txt /data/oppo/coloros/startup/
busybox mv /data/oppo/broadcast_action_white.txt /data/oppo/coloros/startup/
busybox mv /data/oppo/broadcastlist.xml /data/oppo/coloros/startup/
busybox mv /data/oppo/browserWhiteList.txt /data/oppo/coloros/startup/
busybox mv /data/oppo/bootfixed.txt /data/oppo/coloros/startup/
busybox chown 1000:1000 /data/oppo/coloros/startup
busybox chmod 700 /data/oppo/coloros/startup
busybox chmod 600 /data/oppo/coloros/startup/*

busybox mkdir -p /data/oppo/coloros/bpm
busybox mv /data/data_bpm/* /data/oppo/coloros/bpm/
busybox rmdir /data/data_bpm
busybox chown 1000:1000 /data/oppo/coloros/bpm
busybox chmod 775 /data/oppo/coloros/bpm
busybox chmod 750 /data/oppo/coloros/bpm/*

busybox mkdir -p /data/oppo/coloros/gamespace
busybox mv /data/system/oppo_gmsp.txt /data/oppo/coloros/gamespace/oppo_gmsp.txt
busybox mv /data/system/oppo_gmsp_util.txt /data/oppo/coloros/gamespace/oppo_gmsp_util.txt
busybox mv /data/system/sys_gamespace_config.xml /data/oppo/coloros/gamespace/sys_gamespace_config.xml
busybox mv /data/system/sys_display_opt_config.xml /data/oppo/coloros/gamespace/sys_display_opt_config.xml
busybox chown 1000:1000 /data/oppo/coloros/gamespace
busybox chmod 700 /data/oppo/coloros/gamespace
busybox chmod 766 /data/oppo/coloros/gamespace/*

busybox mkdir -p /data/oppo/coloros/multiapp
busybox mv /data/multiapp/* /data/oppo/coloros/multiapp/
busybox rmdir /data/multiapp
busybox chown 1000:1000 /data/oppo/coloros/multiapp
busybox chown 1000:1000 /data/oppo/coloros/multiapp/*
busybox chmod 700 /data/oppo/coloros/multiapp
busybox chmod 600 /data/oppo/coloros/multiapp/*

busybox mkdir -p /data/oppo/coloros/permission
busybox mv /data/oppo/permission/* /data/oppo/coloros/permission/
busybox rmdir /data/oppo/permission
busybox chown 1000:1000 /data/oppo/coloros/permission
busybox chmod 777 /data/oppo/coloros/permission
busybox chmod 777 /data/oppo/coloros/permission/*

busybox mkdir -p /data/oppo/coloros/securepay
busybox mv /data/oppo/securepay/* /data/oppo/coloros/securepay/
busybox rmdir /data/oppo/securepay
busybox chown 1000:1000 /data/oppo/coloros/securepay
busybox chmod 700 /data/oppo/coloros/securepay
busybox chmod 600 /data/oppo/coloros/securepay/*

busybox mkdir -p /data/oppo/coloros/config
busybox mv /data/system/notLaunchedPkgs.xml /data/oppo/coloros/config/
busybox mv /data/system/config/systemConfigList.xml /data/oppo/coloros/config/
busybox chown 1000:1000 /data/oppo/coloros/config
busybox chmod 700 /data/oppo/coloros/config
busybox chmod 774 /data/oppo/coloros/config/notLaunchedPkgs.xml
busybox chmod 600 /data/oppo/coloros/config/systemConfigList.xml

busybox mkdir -p /data/oppo/coloros/safecenter/
busybox mv /data/oppo/safecenter/* /data/oppo/coloros/safecenter/
busybox rmdir /data/oppo/safecenter
busybox chown 1000:1000 /data/oppo/coloros/safecenter/
busybox chmod 700 /data/oppo/coloros/safecenter
busybox chmod 600 /data/oppo/coloros/safecenter/*

busybox mkdir -p /data/oppo/common/appNameChange
busybox mv /data/string/* /data/oppo/common/appNameChange/
busybox rmdir /data/string
busybox chown 1000:1000 /data/oppo/common/appNameChange
busybox chmod 777 /data/oppo/common/appNameChange
busybox chmod 777 /data/oppo/common/appNameChange/*

busybox mkdir -p /data/oppo/coloros/oppoguardelf
busybox mv /data/system/oppoguardelf/* /data/oppo/coloros/oppoguardelf/
busybox rmdir /data/system/oppoguardelf
busybox mv /data/system/doze_wl_user_set_local.xml /data/oppo/coloros/oppoguardelf/
busybox chown 1000:1000 /data/oppo/coloros/oppoguardelf
busybox chmod 700 /data/oppo/coloros/oppoguardelf
busybox chmod 600 /data/oppo/coloros/oppoguardelf/*

busybox mkdir -p /data/oppo/coloros/recenttask
busybox mv /data/system/recenttask/* /data/oppo/coloros/recenttask/
busybox rmdir /data/system/recenttask
busybox chown 1000:1000 /data/oppo/coloros/recenttask
busybox chmod 700 /data/oppo/coloros/recenttask
busybox chmod 600 /data/oppo/coloros/recenttask/*

#!/system/bin/sh

config="$1"
destpathbk="$2"

CURTIME=`date +%F-%H-%M-%S`

ROOT_AUTOTRIGGER_PATH=/sdcard/oppo_log
ROOT_TRIGGER_PATH=/sdcard/oppo_log/trigger

function lowram_device_setup()
{
    MemTotalStr=`cat /proc/meminfo | grep MemTotal`
    MemTotal=${MemTotalStr:16:8}

    if [ $MemTotal -lt 6291456 ]; then
        setprop dalvik.vm.heapminfree 512k
        setprop dalvik.vm.heapmaxfree 8m
        setprop dalvik.vm.heapstartsize 8m
    fi

    if [ $MemTotal -lt 4194304 ]; then
        setprop ro.vendor.qti.sys.fw.bservice_enable true
        setprop ro.vendor.qti.sys.fw.bservice_limit 5
        setprop ro.vendor.qti.sys.fw.bservice_age 5000
        setprop ro.config.oppo.low_ram true
    fi

    if [ $MemTotal -lt 3145728 ]; then
        setprop dalvik.vm.heapstartsize 4m
        setprop ro.config.max_starting_bg 3
        setprop ro.sys.fw.bg_apps_limit 16
    else
        setprop ro.sys.fw.bg_apps_limit 32
    fi
}

#Haoran.Zhang@PSW.AD.BuildConfig.StandaloneUserdata.1143522, 2017/09/13, Add for set prop sys.build.display.full_id

function set_new_prop()
{
   if [ $1 ] ; then
     hash_str="_$1";
   else
     hash_str=""
   fi
   setprop "sys.build.display.id" `getprop ro.build.display.id`"$hash_str"
   is_mtk=`getprop ro.mediatek.version.release`
   if [ $is_mtk ] ; then
   #mtk only
     setprop vendor.oppo.mediatek.version.release `getprop ro.mediatek.version.release`"$hash_str"
   else
     setprop sys.build.display.full_id `getprop ro.build.display.full_id`"$hash_str"
   fi
}

function userdatarefresh(){
   #if [ "$(df /data | grep tmpfs)" ] ; then
   if [ ! `getprop vold.decrypt`  ] ; then
     if [ ! "$(df /data | grep tmpfs)" ] ; then
        if [ -e "/dev/block/bootdevice/by-name/userdata" ] ; then
           mount /dev/block/bootdevice/by-name/userdata /data
        else
           if [ -e "/sys/class/BOOT/BOOT/boot/boot_mode" ] && [ $(cat /sys/class/BOOT/BOOT/boot/boot_mode) == "1" ] ; then
              sleep 2
              if [ -e "/dev/block/platform/bootdevice/by-name/userdata" ] ; then
                 mount /dev/block/platform/bootdevice/by-name/userdata /data
              fi
           fi
        fi
     else
       return 0
     fi
   fi
   mkdir /data/engineermode
   info_file="/data/engineermode/data_version"
   #info_file is not empty
   if [ -s $info_file ] ;then
       data_ver=`cat $info_file | head -1 | xargs echo -n`
       set_new_prop $data_ver
   else
          if [ ! -f $info_file ] ;then
            if [ ! -f /data/engineermode/.sd.txt ]; then
              cp  /system/media/.sd.txt  /data/engineermode/.sd.txt
            fi
            cp /system/engineermode/*  /data/engineermode/
            #create an empty file
            rm $info_file
            touch $info_file
            chmod 0644 /data/engineermode/.sd.txt
            chmod 0644 /data/engineermode/persist*
          fi
       set_new_prop "00000000"
   fi
   #tmp patch for sendtest version
   if [ `getprop ro.build.fix_data_hash` ]; then
      set_new_prop ""
   fi
   #end
    #ifdef COLOROS_EDIT
    #Yaohong.Guo@Plf.Frameworks, 2018/11/19 : Add for OTA data upgrade
    chown system:system /data/engineermode/*
    if [ -f "/data/engineermode/.sd.txt" ]; then
        chown system:system /data/engineermode/.sd.txt
    fi
    if [ -d "/data/etc/appchannel" ]; then
        chown system:system /data/etc/appchannel/*
    fi
    #endif /* COLOROS_EDIT */
   chmod 0750 /data/engineermode
   chmod 0740 /data/engineermode/default_workspace_device*.xml
   chown system:launcher /data/engineermode
   chown system:launcher /data/engineermode/default_workspace_device*.xml
}
#end

#Linjie.Xu@PSW.AD.Power.PowerMonitor.1104067, 2018/01/17, Add for OppoPowerMonitor get dmesg at O
function kernelcacheforopm(){
  opmlogpath=`getprop sys.opm.logpath`
  dmesg > ${opmlogpath}dmesg.txt
  chown system:system ${opmlogpath}dmesg.txt
}
#Linjie.Xu@PSW.AD.Power.PowerMonitor.1104067, 2018/01/17, Add for OppoPowerMonitor get Sysinfo at O
function psforopm(){
  opmlogpath=`getprop sys.opm.logpath`
  ps -A -T > ${opmlogpath}psO.txt
  chown system:system ${opmlogpath}psO.txt
}
function cpufreqforopm(){
  opmlogpath=`getprop sys.opm.logpath`
  cat /sys/devices/system/cpu/*/cpufreq/scaling_cur_freq > ${opmlogpath}cpufreq.txt
  chown system:system ${opmlogpath}cpufreq.txt
}
function smapsforhealth(){
  opmlogpath=`getprop sys.opm.logpath`
  pid=`getprop sys.opm.pid`
  cat /proc/${pid}/smaps > ${opmlogpath}smaps.txt
}
function dmaprocsforhealth(){
  opmlogpath=`getprop sys.opm.logpath`
  cat /sys/kernel/debug/ion/heaps/* > ${opmlogpath}dmaprocs.txt
  cat /sys/kernel/debug/ion/client_history >> ${opmlogpath}dmaprocs.txt
  cat /sys/kernel/debug/ion/ion_mm_heap >> ${opmlogpath}dmaprocs.txt
  cat /sys/kernel/debug/ion/string_hash >> ${opmlogpath}dmaprocs.txt
  dumpsys meminfo `ps -A | grep graphics.composer | tr -s ' ' | cut -d ' ' -f 2` >> ${opmlogpath}dmaprocs.txt
  chown system:system ${opmlogpath}dmaprocs.txt
}
function slabinfoforhealth(){
  opmlogpath=`getprop sys.opm.logpath`
  cat /proc/slabinfo > ${opmlogpath}slabinfo.txt
  chown system:system ${opmlogpath}slabinfo.txt
}
function svelteforhealth(){
  sveltetracer=`getprop sys.opm.svelte_tracer`
  svelteops=`getprop sys.opm.svelte_ops`
  svelteargs=`getprop sys.opm.svelte_args`
  opmlogpath=`getprop sys.opm.logpath`
  /system/bin/svelte tracer -t ${sveltetracer} -o ${svelteops} -a ${svelteargs}
  sleep 12
  chown system:system ${opmlogpath}*svelte.txt
}
function meminfoforhealth(){
  opmlogpath=`getprop sys.opm.logpath`
  cat /proc/meminfo > ${opmlogpath}meminfo.txt
  chown system:system ${opmlogpath}meminfo.txt
}
function systraceforopm(){
    opmlogpath=`getprop sys.opm.logpath`
    CATEGORIES=`atrace --list_categories | $XKIT awk '{printf "%s ", $1}'`
    systrace_duration=`getprop sys.opm.systrace.duration`
    if [ "$systrace_duration" != "" ]
    then
        LOGTIME=`date +%F-%H-%M-%S`
        SYSTRACE_DIR=${opmlogpath}/systrace_${LOGTIME}
        mkdir -p ${SYSTRACE_DIR}
        ((sytrace_buffer=$systrace_duration*1536))
        atrace -z -b ${sytrace_buffer} -t ${systrace_duration} ${CATEGORIES} > ${SYSTRACE_DIR}/atrace_raw
        chown -R system:system ${SYSTRACE_DIR}
    fi
}
#ifdef VENDOR_EDIT
#Yanzhen.Feng 2015/12/09, Add for SurfaceFlinger Layer dump
function layerdump(){
    dumpsys window > /data/log/dumpsys_window.txt
    mkdir -p ${ROOT_AUTOTRIGGER_PATH}
    LOGTIME=`date +%F-%H-%M-%S`
    ROOT_SDCARD_LAYERDUMP_PATH=${ROOT_AUTOTRIGGER_PATH}/LayerDump_${LOGTIME}
    cp -R /data/log ${ROOT_SDCARD_LAYERDUMP_PATH}
    rm -rf /data/log
}
#endif /* VENDOR_EDIT */
#ifdef VENDOR_EDIT
#Yanzhen.Feng Add for systrace on phone
function cont_systrace(){
    mkdir -p ${ROOT_AUTOTRIGGER_PATH}/systrace
    CATEGORIES=`atrace --list_categories | $XKIT awk '!/irqoff/>/preemptoff/>/pdx/>/bionic/{printf "%s ", $1}'`
    #songyinzhong async mode
    systrace_duration=`getprop debug.oppo.systrace.duration`
    #async mode buffer do not need too large
    ((sytrace_buffer=$systrace_duration*896))
    systrace_async_mode=`getprop debug.oppo.systrace.async`
    #async stop
    systrace_status=`getprop debug.oppo.cont_systrace`
    if [ "$systrace_status" == "false" ] && [ "$systrace_async_mode" == "true" ]; then
        LOGTIME=`date +%F-%H-%M-%S`
        SYSTRACE_DIR=${ROOT_AUTOTRIGGER_PATH}/systrace/systrace_${LOGTIME}
        mkdir -p ${SYSTRACE_DIR}
        echo begin save ${LOGTIME}
        setprop debug.oppo.systrace.asyncsaving true
        atrace --async_stop -z -c -o ${SYSTRACE_DIR}/atrace_raw
        /system/bin/ps -AT -o USER,TID,PID,PPID,VSIZE,RSS,WCHAN,ADDR,CMD > ${SYSTRACE_DIR}/ps.txt
        /system/bin/printf "%s\n" /proc/[0-9]*/task/[0-9]* > ${SYSTRACE_DIR}/task.txt
        echo 'async stop done ' ${SYSTRACE_DIR}
        LOGTIME2=`date +%F-%H-%M-%S`
        echo save done ${LOGTIME2}
        setprop debug.oppo.systrace.asyncsaving false
        return
    fi
    #async dump for screenshot
    systrace_dump=`getprop debug.oppo.systrace.dump`
    systrace_saving=`getprop debug.oppo.systrace.asyncsaving`
    if [ "$systrace_status" == "true" ] && [ "$systrace_async_mode" == "true" ] && [ "$systrace_dump" == "true" ]; then
        if [ "$systrace_saving" == "true" ]; then
            echo already saving systrace ,ignore
            return
        fi
        LOGTIME=`date +%F-%H-%M-%S`
        SYSTRACE_DIR=${ROOT_AUTOTRIGGER_PATH}/systrace/systrace_${LOGTIME}
        mkdir -p ${SYSTRACE_DIR}
        echo begin save ${LOGTIME}
        setprop debug.oppo.systrace.asyncsaving true
        atrace --async_dump -z -c -o ${SYSTRACE_DIR}/atrace_raw
        /system/bin/ps -AT -o USER,TID,PID,PPID,VSIZE,RSS,WCHAN,ADDR,CMD > ${SYSTRACE_DIR}/ps.txt
        /system/bin/printf "%s\n" /proc/[0-9]*/task/[0-9]* > ${SYSTRACE_DIR}/task.txt
        echo 'async stop done ' ${SYSTRACE_DIR}
        LOGTIME2=`date +%F-%H-%M-%S`
        echo dump done ${LOGTIME2}
        setprop debug.oppo.systrace.asyncsaving false
        setprop debug.oppo.systrace.dump false
        return
    fi
    #async start
    if [ "$systrace_status" == "true" ] && [ "$systrace_async_mode" == "true" ]; then
        #property max len is 91, and prop should with space in tags1 and tags2
        categories_set1=`getprop debug.oppo.systrace.tags1`
        categories_set2=`getprop debug.oppo.systrace.tags2`
        if [ "$categories_set1" != "" ] || [ "$categories_set2" != "" ]; then
            CATEGORIES="$categories_set1""$categories_set2"
        fi
        echo ${CATEGORIES}
        atrace --async_start -c -b ${sytrace_buffer} ${CATEGORIES}
        echo 'async start done '
        return
    fi
    echo ${CATEGORIES} > ${ROOT_AUTOTRIGGER_PATH}/systrace/categories.txt
    while true
    do
        systrace_duration=`getprop debug.oppo.systrace.duration`
        if [ "$systrace_duration" != "" ]
        then
            LOGTIME=`date +%F-%H-%M-%S`
            SYSTRACE_DIR=${ROOT_AUTOTRIGGER_PATH}/systrace/systrace_${LOGTIME}
            mkdir -p ${SYSTRACE_DIR}
            ((sytrace_buffer=$systrace_duration*1536))
            atrace -z -b ${sytrace_buffer} -t ${systrace_duration} ${CATEGORIES} > ${SYSTRACE_DIR}/atrace_raw
            /system/bin/ps -AT -o USER,TID,PID,PPID,VSIZE,RSS,WCHAN,ADDR,CMD > ${SYSTRACE_DIR}/ps.txt
            /system/bin/printf "%s\n" /proc/[0-9]*/task/[0-9]* > ${SYSTRACE_DIR}/task.txt

            systrace_status=`getprop debug.oppo.cont_systrace`
            if [ "$systrace_status" != "true" ]; then
                break
            fi
        fi
    done
}
#endif /* VENDOR_EDIT */
function junklogcat() {

    is_europe=`getprop ro.oppo.regionmark`
    if [ x"${is_europe}" != x"EUEX" ]; then
        JUNKLOGPATH=/sdcard/oppo_log/junk_logs
    else
        JUNKLOGPATH=/data/oppo/log/DCS/junk_logs_tmp
    fi
    mkdir -p ${JUNKLOGPATH}

    system/bin/logcat -f ${JUNKLOGPATH}/junklogcat.txt -v threadtime *:V
}
function junkdmesg() {
    is_europe=`getprop ro.oppo.regionmark`
    if [ x"${is_europe}" != x"EUEX" ]; then
        JUNKLOGPATH=/sdcard/oppo_log/junk_logs
    else
        JUNKLOGPATH=/data/oppo/log/DCS/junk_logs_tmp
    fi
    mkdir -p ${JUNKLOGPATH}
    system/bin/dmesg > ${JUNKLOGPATH}/junkdmesg.txt
}
function junksystrace_start() {
    is_europe=`getprop ro.oppo.regionmark`
    if [ x"${is_europe}" != x"EUEX" ]; then
        JUNKLOGPATH=/sdcard/oppo_log/junk_logs
    else
        JUNKLOGPATH=/data/oppo/log/DCS/junk_logs_tmp
    fi
    mkdir -p ${JUNKLOGPATH}

    #setup
    setprop debug.atrace.tags.enableflags 0x86E
    # stop;start
    adb shell "echo 16384 > /sys/kernel/debug/tracing/buffer_size_kb"

    echo nop > /sys/kernel/debug/tracing/current_tracer
    echo 'sched_switch sched_wakeup sched_wakeup_new sched_migrate_task binder workqueue irq cpu_frequency mtk_events' > /sys/kernel/debug/tracing/set_event
#just in case tracing_enabled is disabled by user or other debugging tool
    echo 1 > /sys/kernel/debug/tracing/tracing_enabled >nul 2>&1
    echo 0 > /sys/kernel/debug/tracing/tracing_on
#erase previous recorded trace
    echo > /sys/kernel/debug/tracing/trace
    echo press any key to start capturing...
    echo 1 > /sys/kernel/debug/tracing/tracing_on
    echo "Start recordng ftrace data"
    echo s_start > sdcard/s_start2.txt
}
function junksystrace_stop() {
    is_europe=`getprop ro.oppo.regionmark`
    if [ x"${is_europe}" != x"EUEX" ]; then
        JUNKLOGPATH=/sdcard/oppo_log/junk_logs
    else
        JUNKLOGPATH=/data/oppo/log/DCS/junk_logs_tmp
    fi
    mkdir -p ${JUNKLOGPATH}
    echo s_stop > sdcard/s_stop.txt
    echo 0 > /sys/kernel/debug/tracing/tracing_on
    echo "Recording stopped..."
    cp /sys/kernel/debug/tracing/trace ${JUNKLOGPATH}/junksystrace
    echo 1 > /sys/kernel/debug/tracing/tracing_on

}

function junk_log_monitor(){
    is_europe=`getprop ro.oppo.regionmark`
    if [ x"${is_europe}" != x"EUEX" ]; then
        DIR=/sdcard/oppo_log/junk_logs/DCS
    else
        DIR=/data/oppo/log/DCS/de/junk_logs
    fi
    MAX_NUM=10
    IDX=0
    if [ -d "$DIR" ]; then
        ALL_FILE=`ls -t $DIR`
        for i in $ALL_FILE;
        do
            echo "now we have file $i"
            let IDX=$IDX+1;
            echo ========file num is $IDX===========
            if [ "$IDX" -gt $MAX_NUM ] ; then
               echo rm file $i\!;
            rm -rf $DIR/$i
            fi
        done
    fi
}

#ifdef VENDOR_EDIT
#Fei.Mo2017/09/01 ,Add for power monitor top info
function thermalTop(){
   top -m 3 -n 1 > /data/system/dropbox/thermalmonitor/top
   chown system:system /data/system/dropbox/thermalmonitor/top
}
#endif /*VENDOR_EDIT*/

#ifdef VENDOR_EDIT
#Yugang.Bao@PSW.AD.OppoDebug.Feedback.1500936, 2018/07/31, Add for panic delete pstore/dmesg-ramoops-0 file
function cpoppousage() {
   mkdir -p /data/oppo/log/oppousagedump
   chown -R system:system /data/oppo/log/oppousagedump
   cp -R /mnt/vendor/opporeserve/media/log/usage/cache /data/oppo/log/oppousagedump
   cp -R /mnt/vendor/opporeserve/media/log/usage/persist /data/oppo/log/oppousagedump
   chmod -R 777 /data/oppo/log/oppousagedump
   setprop persist.sys.cpoppousage 0
}

#ifdef VENDOR_EDIT
#Deliang.Peng 2017/7/7,add for native watchdog
function nativedump() {
    LOGTIME=`date +%F-%H-%M-%S`
    SWTPID=`getprop debug.swt.pid`
    JUNKLOGSFBACKPATH=/sdcard/oppo_log/native/${LOGTIME}
    NATIVEBACKTRACEPATH=${JUNKLOGSFBACKPATH}/user_backtrace
    mkdir -p ${NATIVEBACKTRACEPATH}
    cat proc/stat > ${JUNKLOGSFBACKPATH}/proc_stat.txt &
    cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_cur_freq > ${JUNKLOGSFBACKPATH}/cpu_freq_0_.txt &
    cat /sys/devices/system/cpu/cpu1/cpufreq/cpuinfo_cur_freq > ${JUNKLOGSFBACKPATH}/cpu_freq_1.txt &
    cat /sys/devices/system/cpu/cpu2/cpufreq/cpuinfo_cur_freq > ${JUNKLOGSFBACKPATH}/cpu_freq_2.txt &
    cat /sys/devices/system/cpu/cpu3/cpufreq/cpuinfo_cur_freq > ${JUNKLOGSFBACKPATH}/cpu_freq_3.txt &
    cat /sys/devices/system/cpu/cpu4/cpufreq/cpuinfo_cur_freq > ${JUNKLOGSFBACKPATH}/cpu_freq_4.txt &
    cat /sys/devices/system/cpu/cpu5/cpufreq/cpuinfo_cur_freq > ${JUNKLOGSFBACKPATH}/cpu_freq_5.txt &
    cat /sys/devices/system/cpu/cpu6/cpufreq/cpuinfo_cur_freq > ${JUNKLOGSFBACKPATH}/cpu_freq_6.txt &
    cat /sys/devices/system/cpu/cpu7/cpufreq/cpuinfo_cur_freq > ${JUNKLOGSFBACKPATH}/cpu_freq_7.txt &
    cat /sys/devices/system/cpu/cpu0/online > ${JUNKLOGSFBACKPATH}/cpu_online_0_.txt &
    cat /sys/devices/system/cpu/cpu1/online > ${JUNKLOGSFBACKPATH}/cpu_online_1_.txt &
    cat /sys/devices/system/cpu/cpu2/online > ${JUNKLOGSFBACKPATH}/cpu_online_2_.txt &
    cat /sys/devices/system/cpu/cpu3/online > ${JUNKLOGSFBACKPATH}/cpu_online_3_.txt &
    cat /sys/devices/system/cpu/cpu4/online > ${JUNKLOGSFBACKPATH}/cpu_online_4_.txt &
    cat /sys/devices/system/cpu/cpu5/online > ${JUNKLOGSFBACKPATH}/cpu_online_5_.txt &
    cat /sys/devices/system/cpu/cpu6/online > ${JUNKLOGSFBACKPATH}/cpu_online_6_.txt &
    cat /sys/devices/system/cpu/cpu7/online > ${JUNKLOGSFBACKPATH}/cpu_online_7_.txt &
    cat /proc/gpufreq/gpufreq_var_dump > ${JUNKLOGSFBACKPATH}/gpuclk.txt &
    top -n 1 -m 5 > ${JUNKLOGSFBACKPATH}/top.txt  &
    cp -R /data/native/* ${NATIVEBACKTRACEPATH}
    rm -rf /data/native
    ps -t > ${JUNKLOGSFBACKPATH}/pst.txt
}
#endif /*VENDOR_EDIT*/

function gettpinfo() {
    tplogflag=`getprop persist.sys.oppodebug.tpcatcher`
    # tplogflag=511
    # echo "$tplogflag"
    if [ "$tplogflag" == "" ]
    then
        echo "tplogflag == error"
    else
        kernellogpath=sdcard/mtklog/tp_debug_info/
        subcur=`date +%F-%H-%M-%S`
        subpath=$kernellogpath/$subcur.txt
        mkdir -p $kernellogpath
        echo $tplogflag
        # tplogflag=`echo $tplogflag | $XKIT awk '{print lshift($0, 1)}'`
        tpstate=0
        tpstate=`echo $tplogflag | $XKIT awk '{print and($1, 1)}'`
        echo "switch tpstate = $tpstate"
        if [ $tpstate == "0" ]
        then
            echo "switch tpstate off"
        else
            echo "switch tpstate on"
        # mFlagMainRegister = 1 << 1
        subflag=`echo | $XKIT awk '{print lshift(1, 1)}'`
        echo "1 << 1 subflag = $subflag"
        tpstate=`echo $tplogflag $subflag, | $XKIT awk '{print and($1, $2)}'`
        if [ $tpstate == "0" ]
        then
            echo "switch tpstate off mFlagMainRegister = 1 << 1 $tpstate"
        else
            echo "switch tpstate on mFlagMainRegister = 1 << 1 $tpstate"
            echo /proc/touchpanel/debug_info/main_register  >> $subpath
            cat /proc/touchpanel/debug_info/main_register  >> $subpath
        fi
        # mFlagSelfDelta = 1 << 2;
        subflag=`echo | $XKIT awk '{print lshift(1, 2)}'`
        echo " 1<<2 subflag = $subflag"
        tpstate=`echo $tplogflag $subflag, | $XKIT awk '{print and($1, $2)}'`
        if [ $tpstate == "0" ]
        then
            echo "switch tpstate off mFlagMainRegister = 1 << 2 $tpstate"
        else
            echo "switch tpstate on mFlagMainRegister = 1 << 2 $tpstate"
            echo /proc/touchpanel/debug_info/self_delta  >> $subpath
            cat /proc/touchpanel/debug_info/self_delta  >> $subpath
        fi
        # mFlagDetal = 1 << 3;
        subflag=`echo | $XKIT awk '{print lshift(1, 3)}'`
        echo "1 << 3 subflag = $subflag"
        tpstate=`echo $tplogflag $subflag, | $XKIT awk '{print and($1, $2)}'`
        if [ $tpstate == "0" ]
        then
            echo "switch tpstate off mFlagMainRegister = 1 << 3 $tpstate"
        else
            echo "switch tpstate on mFlagMainRegister = 1 << 3 $tpstate"
            echo /proc/touchpanel/debug_info/delta  >> $subpath
            cat /proc/touchpanel/debug_info/delta  >> $subpath
        fi
        # mFlatSelfRaw = 1 << 4;
        subflag=`echo | $XKIT awk '{print lshift(1, 4)}'`
        echo "1 << 4 subflag = $subflag"
        tpstate=`echo $tplogflag $subflag, | $XKIT awk '{print and($1, $2)}'`
        if [ $tpstate == "0" ]
        then
            echo "switch tpstate off mFlagMainRegister = 1 << 4 $tpstate"
        else
            echo "switch tpstate on mFlagMainRegister = 1 << 4 $tpstate"
            echo /proc/touchpanel/debug_info/self_raw  >> $subpath
            cat /proc/touchpanel/debug_info/self_raw  >> $subpath
        fi
        # mFlagBaseLine = 1 << 5;
        subflag=`echo | $XKIT awk '{print lshift(1, 5)}'`
        echo "1 << 5 subflag = $subflag"
        tpstate=`echo $tplogflag $subflag, | $XKIT awk '{print and($1, $2)}'`
        if [ $tpstate == "0" ]
        then
            echo "switch tpstate off mFlagMainRegister = 1 << 5 $tpstate"
        else
            echo "switch tpstate on mFlagMainRegister = 1 << 5 $tpstate"
            echo /proc/touchpanel/debug_info/baseline  >> $subpath
            cat /proc/touchpanel/debug_info/baseline  >> $subpath
        fi
        # mFlagDataLimit = 1 << 6;
        subflag=`echo | $XKIT awk '{print lshift(1, 6)}'`
        echo "1 << 6 subflag = $subflag"
        tpstate=`echo $tplogflag $subflag, | $XKIT awk '{print and($1, $2)}'`
        if [ $tpstate == "0" ]
        then
            echo "switch tpstate off mFlagMainRegister = 1 << 6 $tpstate"
        else
            echo "switch tpstate on mFlagMainRegister = 1 << 6 $tpstate"
            echo /proc/touchpanel/debug_info/data_limit  >> $subpath
            cat /proc/touchpanel/debug_info/data_limit  >> $subpath
        fi
        # mFlagReserve = 1 << 7;
        subflag=`echo | $XKIT awk '{print lshift(1, 7)}'`
        echo "1 << 7 subflag = $subflag"
        tpstate=`echo $tplogflag $subflag, | $XKIT awk '{print and($1, $2)}'`
        if [ $tpstate == "0" ]
        then
            echo "switch tpstate off mFlagMainRegister = 1 << 7 $tpstate"
        else
            echo "switch tpstate on mFlagMainRegister = 1 << 7 $tpstate"
            echo /proc/touchpanel/debug_info/reserve  >> $subpath
            cat /proc/touchpanel/debug_info/reserve  >> $subpath
        fi
        # mFlagTpinfo = 1 << 8;
        subflag=`echo | $XKIT awk '{print lshift(1, 8)}'`
        echo "1 << 8 subflag = $subflag"
        tpstate=`echo $tplogflag $subflag, | $XKIT awk '{print and($1, $2)}'`
        if [ $tpstate == "0" ]
        then
            echo "switch tpstate off mFlagMainRegister = 1 << 8 $tpstate"
        else
            echo "switch tpstate on mFlagMainRegister = 1 << 8 $tpstate"
        fi

        echo $tplogflag " end else"
	fi
    fi
#ifdef VENDOR_EDIT
#Miao.Yu@PSW.AD.WMS, 2019/11/25, Add for dump info when screenshot
    panicstate=`getprop persist.sys.assert.panic`
    dumpenable=`getprop debug.screencapdump.enable`
    if [ "$panicstate" == "true" ] && [ "$dumpenable" == "true" ]
    then
        screencapdump
    fi
#endif /* VENDOR_EDIT */
}
function write_logswitch_on(){
    /system/bin/settings  put System log_switch_type 1
}

function write_logswitch_off(){
    /system/bin/settings  put System log_switch_type 0
}
function screen_record(){
    backupFile="/sdcard/oppo_log/screen_record/screen_record_old.mp4"
    curFile="/sdcard/oppo_log/screen_record/screen_record.mp4"
    if [ -f "$curFile" ]; then
        echo "backup"
         mv $curFile $backupFile
    fi

    ROOT_SDCARD_RECORD_LOG_PATH=${ROOT_AUTOTRIGGER_PATH}/screen_record
    mkdir -p  ${ROOT_SDCARD_RECORD_LOG_PATH}
    /system/bin/screenrecord  --time-limit 1800 --size 320x640 --bit-rate 500000 --verbose ${ROOT_SDCARD_RECORD_LOG_PATH}/screen_record.mp4
}

function inittpdebug(){
    panicstate=`getprop persist.sys.assert.panic`
    tplogflag=`getprop persist.sys.oppodebug.tpcatcher`
    if [ "$panicstate" == "true" ]
    then
        tplogflag=`echo $tplogflag , | $XKIT awk '{print or($1, 1)}'`
    else
        tplogflag=`echo $tplogflag , | $XKIT awk '{print and($1, 510)}'`
    fi
    setprop persist.sys.oppodebug.tpcatcher $tplogflag
}
function settplevel(){
    tplevel=`getprop persist.sys.oppodebug.tplevel`
    if [ "$tplevel" == "0" ]
    then
        echo 0 > /proc/touchpanel/debug_level
    elif [ "$tplevel" == "1" ]
    then
        echo 1 > /proc/touchpanel/debug_level
    elif [ "$tplevel" == "2" ]
    then
        echo 2 > /proc/touchpanel/debug_level
    fi
}


#Fangfang.Hui@TECH.AD.Stability, 2019/08/13, Add for the quality feedback dcs config
function backupMinidump() {
    tag=`getprop sys.backup.minidump.tag`
    if [ x"$tag" = x"" ]; then
        echo "backup.minidump.tag is null, do nothing"
        return
    fi
    minidumppath="/data/oppo/log/DCS/de/AEE_DB"
    miniDumpFile=$minidumppath/$(ls -t ${minidumppath} | head -1)
    if [ x"$miniDumpFile" = x"" ]; then
        echo "minidump.file is null, do nothing"
        return
    fi
    result=$(echo $miniDumpFile | grep "${tag}")
    if [ x"$result" = x"" ]; then
        echo "tag mismatch, do not backup"
        return
    else
        try_copy_minidump_to_opporeserve $miniDumpFile
        setprop sys.backup.minidump.tag ""
    fi
}

function try_copy_minidump_to_opporeserve() {
    OPPORESERVE_MINIDUMP_BACKUP_PATH="/mnt/vendor/opporeserve/media/log/minidump"
    OPPORESERVE2_MOUNT_POINT="/mnt/vendor/opporeserve"

    if [ ! -d ${OPPORESERVE_MINIDUMP_BACKUP_PATH} ]; then
        mkdir ${OPPORESERVE_MINIDUMP_BACKUP_PATH}
    fi
    chmod -R 0770 ${OPPORESERVE_MINIDUMP_BACKUP_PATH}
    chown -R system ${OPPORESERVE_MINIDUMP_BACKUP_PATH}
    chgrp -R system ${OPPORESERVE_MINIDUMP_BACKUP_PATH}
    NewLogPath=$1
    if [ ! -f $NewLogPath ] ;then
        echo "Can not access ${NewLogPath}, the file may not exists "
        return
    fi
    TmpLogSize=`du -s -k ${NewLogPath} | $XKIT awk '{print $1}'`
    curBakCount=`ls ${OPPORESERVE_MINIDUMP_BACKUP_PATH} | wc -l`
    echo "curBakCount = $curBakCount"
    while [ ${curBakCount} -gt 5 ]   #can only save 5 backup minidump logs at most
    do
        rm -rf ${OPPORESERVE_MINIDUMP_BACKUP_PATH}/$(ls -t ${OPPORESERVE_MINIDUMP_BACKUP_PATH} | tail -1)
        curBakCount=`ls ${OPPORESERVE_MINIDUMP_BACKUP_PATH} | wc -l`
        echo "delete one file curBakCount = $curBakCount"
    done
    FreeSize=$(df -k | grep "${OPPORESERVE2_MOUNT_POINT}" | sed 's/[ ][ ]*/,/g' | cut -d "," -f4)
    TotalSize=$(df -k | grep "${OPPORESERVE2_MOUNT_POINT}" | sed 's/[ ][ ]*/,/g' | cut -d "," -f2)
    ReserveSize=`expr $TotalSize / 5`
    NeedSize=`expr $TmpLogSize + $ReserveSize`
    echo "NeedSize = $NeedSize, ReserveSize = $ReserveSize, FreeSize = $FreeSize" 
    while [ ${FreeSize} -le ${NeedSize} ]
    do
        curBakCount=`ls ${OPPORESERVE_MINIDUMP_BACKUP_PATH} | wc -l`
        if [ $curBakCount -gt 1 ]; then #leave at most on log file
            rm -rf ${OPPORESERVE_MINIDUMP_BACKUP_PATH}/$(ls -t ${OPPORESERVE_MINIDUMP_BACKUP_PATH} | tail -1)
            echo "${OPPORESERVE2_MOUNT_POINT} left space ${FreeSize} not enough for minidump, delete one de minidump"
            FreeSize=$(df -k | grep "${OPPORESERVE2_MOUNT_POINT}" | sed 's/[ ][ ]*/,/g' | cut -d "," -f4)
            continue
        fi
        echo "${OPPORESERVE2_MOUNT_POINT} left space ${FreeSize} not enough for minidump, nothing to delete"
        return 0
    done
    #space is enough, now copy
    cp $NewLogPath $OPPORESERVE_MINIDUMP_BACKUP_PATH
    chmod -R 0770 ${OPPORESERVE_MINIDUMP_BACKUP_PATH}
    chown -R system ${OPPORESERVE_MINIDUMP_BACKUP_PATH}
    chgrp -R system ${OPPORESERVE_MINIDUMP_BACKUP_PATH}
}

#Jianping.Zheng 2017/06/20, Add for collect futexwait block log
function collect_futexwait_log() {
    collect_path=/data/system/dropbox/extra_log
    if [ ! -d ${collect_path} ]
    then
        mkdir -p ${collect_path}
        chmod 700 ${collect_path}
        chown system:system ${collect_path}
    fi

    #time
    echo `date` > ${collect_path}/futexwait.time.txt

    #ps -t info
    ps -A -T > $collect_path/ps.txt

    #D status to dmesg
    echo w > /proc/sysrq-trigger

    #systemserver trace
    system_server_pid=`ps -A |grep system_server | $XKIT awk '{print $2}'`
    kill -3 ${system_server_pid}
    sleep 10
    cp /data/anr/traces.txt $collect_path/

    #systemserver native backtrace
    debuggerd -b ${system_server_pid} > $collect_path/systemserver.backtrace.txt
}

#Jianping.Zheng 2017/05/08, Add for systemserver futex_wait block check
function checkfutexwait_wrap() {
    if [ -f /system/bin/checkfutexwait ]; then
        setprop ctl.start checkfutexwait_bin
    else
        while [ true ];do
            is_futexwait_started=`getprop init.svc.checkfutexwait`
            if [ x"${is_futexwait_started}" != x"running" ]; then
                setprop ctl.start checkfutexwait
            fi
            sleep 180
        done
    fi
}

function do_check_systemserver_futexwait_block() {
    exception_max=`getprop persist.sys.futexblock.max`
    if [ x"${exception_max}" = x"" ]; then
        exception_max=60
    fi

    system_server_pid=`ps -A |grep system_server | $XKIT awk '{print $2}'`
    if [ x"${system_server_pid}" != x"" ]; then
        exception_count=0
        while [ $exception_count -lt $exception_max ] ;do
            systemserver_stack_status=`ps -A | grep system_server | $XKIT awk '{print $6}'`
            if [ x"${systemserver_stack_status}" != x"futex_wait_queue_me" ]; then
                break
            fi

            inputreader_stack_status=`ps -A -T | grep InputReader  | $XKIT awk '{print $7}'`
            if [ x"${inputreader_stack_status}" == x"futex_wait_queue_me" ]; then
                exception_count=`expr $exception_count + 1`
                if [ x"${exception_count}" = x"${exception_max}" ]; then
                    echo "Systemserver,FutexwaitBlocked-"`date` > "/proc/sys/kernel/hung_task_oppo_kill"
                    setprop sys.oppo.futexwaitblocked "`date`"
                    collect_futexwait_log
                    kill -9 $system_server_pid
                    sleep 60
                    break
                fi
                sleep 1
            else
                break
            fi
        done
    fi
}
#end, add for systemserver futex_wait block check

#ifdef VENDOR_EDIT
#QiLong.Ao@PSW.AD.OppoDebug.LogKit.1067207, 2019/04/03, Add for clean pcm dump file.
function cleanpcmdump() {
    rm -rf /data/vendor/audiohal/audio_dump/*
    rm -rf /data/vendor/audiohal/aurisys_dump/*
    rm -rf /sdcard/mtklog/audio_dump/*
}
#endif /* VENDOR_EDIT */

#Jianping.Zheng 2017/06/12, Add for record d status thread stack
function record_d_threads_stack() {
    record_path=$1
    echo "\ndate->" `date` >> ${record_path}
    ignore_threads="kworker/u16:1|mdss_dsi_event|mmc-cmdqd/0|msm-core:sampli|kworker/10:0|mdss_fb0\
|mts_thread|fuse_log|ddp_irq_log_kth|disp_check|decouple_trigge|ccci_fsm1|ccci_poll1|hang_detect\
|gauge_coulomb_t|battery_thread|power_misc_thre|gauge_timer_thr|ipi_cpu_dvfs_rt|smart_det|charger_thread"
    d_status_tids=`ps -t | grep " D " | grep -iEv "$ignore_threads" | $XKIT awk '{print $2}'`;
    if [ x"${d_status_tids}" != x"" ]
    then
        sleep 5
        d_status_tids_again=`ps -t | grep " D " | grep -iEv "$ignore_threads" | $XKIT awk '{print $2}'`;
        for tid in ${d_status_tids}
        do
            for tid_2 in ${d_status_tids_again}
            do
                if [ x"${tid}" == x"${tid_2}" ]
                then
                    thread_stat=`cat /proc/${tid}/stat | grep " D "`
                    if [ x"${thread_stat}" != x"" ]
                    then
                        echo "tid:"${tid} "comm:"`cat /proc/${tid}/comm` "cmdline:"`cat /proc/${tid}/cmdline`  >> ${record_path}
                        echo "stack:" >> ${record_path}
                        cat /proc/${tid}/stack >> ${record_path}
                    fi
                    break
                fi
            done
        done
    fi
}
#Canjie.Zheng 2017/06/30, add for clan junk log.
function cleanjunk() {
    rm -rf data/oppo_log/junk_logs/ftrace/*
    rm -rf data/oppo_log/junk_logs/kernel/*
}

#Jianping.Zheng, 2017/04/04, Add for record performance
function perf_record() {
    check_interval=`getprop persist.sys.oppo.perfinteval`
    if [ x"${check_interval}" = x"" ]; then
        check_interval=60
    fi
    perf_record_path=/data/oppo_log/perf_record_logs
    while [ true ];do
        if [ ! -d ${perf_record_path} ];then
            mkdir -p ${perf_record_path}
        fi

        echo "\ndate->" `date` >> ${perf_record_path}/cpu.txt
        cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq >> ${perf_record_path}/cpu.txt

        echo "\ndate->" `date` >> ${perf_record_path}/mem.txt
        cat /proc/meminfo >> ${perf_record_path}/mem.txt

        echo "\ndate->" `date` >> ${perf_record_path}/buddyinfo.txt
        cat /proc/buddyinfo >> ${perf_record_path}/buddyinfo.txt

        echo "\ndate->" `date` >> ${perf_record_path}/top.txt
        top -t -m 8 -n 1 >> ${perf_record_path}/top.txt

        record_d_threads_stack "${perf_record_path}/d_status.txt"

        sleep "$check_interval"
    done
}


function powerlog() {
    pmlog=data/system/powermonitor_backup/
    if [ -d "$pmlog" ]; then
        mkdir -p sdcard/mtklog/powermonitor_backup
        cp -r data/system/powermonitor_backup/* sdcard/mtklog/powermonitor_backup/
    fi
}

#Canjie.Zhang@PSW.AD.OppoDebug.LogKit.1080426, 2017/11/09, Add for logkit2.0 clean log command
function cleanlog() {
    rm -rf sdcard/mtklog/
    rm -rf sdcard/debuglogger/
    rm -rf sdcard/oppo_log/
    rm -rf storage/sdcard1/mtklog/
    rm -rf /data/vendor/audiohal/audio_dump/*
    rm -rf /data/vendor/audiohal/aurisys_dump/*
}

function screen_record_backup(){
    backupFile="/sdcard/oppo_log/screen_record/screen_record_old.mp4"
    if [ -f "$backupFile" ]; then
         rm $backupFile
    fi

    curFile="/sdcard/oppo_log/screen_record/screen_record.mp4"
    if [ -f "$curFile" ]; then
         mv $curFile $backupFile
    fi
}

function pwkdumpon(){
    echo 1 >  /proc/aee_kpd_enable
}

function pwkdumpoff(){
    echo 0 >  /proc/aee_kpd_enable
}

#ifdef VENDOR_EDIT
#Chunbo.Gao@PSW.AD.OppoDebug.LogKit.BugID, 2019/4/10, Add for full dump & mini dump
function mrdumpon(){
#zhouhengguo@BSP.Kernel.Stablity, 2019/10/22, remove ext4 param for fulldump
#    mrdump_tool output-set internal-storage:ext4
    mrdump_tool output-set internal-storage
}

function mrdumpoff(){
    mrdump_tool output-set none
}
#endif /* VENDOR_EDIT */

function copy_screenshot() {
    is_release=`getprop ro.build.release_type`
    if [ x"${is_release}" != x"true" ]; then
        newpath="sdcard/mtklog"
        MAX_NUM=5
        #ifdef VENDOR_EDIT
        #Zhiming.chen@PSW.AD.OppoLog.BugID 2724830, 2019/12/17,The log tool captures child user screenshots
        ALL_USER=`ls -t storage/emulated/`
        for m in $ALL_USER;
        do
            IDX=0
            screen_shot="/storage/emulated/$m/DCIM/Screenshots/"
            if [ -d "$screen_shot" ]; then
                mkdir -p ${newpath}/Screenshots/$m
                touch ${newpath}/Screenshots/$m/.nomedia
                ALL_FILE=`ls -t $screen_shot`
                for i in $ALL_FILE;
                do
                    echo "now we have file $i"
                    let IDX=$IDX+1;
                    echo ========file num is $IDX===========
                    if [ "$IDX" -lt $MAX_NUM ] ; then
                       echo  $i\!;
                       cp $screen_shot/$i ${newpath}/Screenshots/$m/
                    fi
                done
            fi
        done
        #endif /* VENDOR_EDIT */
    fi
}

#Wenshuai.Chen@RM.AD.OppoDebug.LogKit.NA, 2020/06/02, Add for bugreport log
function dump_bugreport() {
    mkdir -p  $ROOT_TRIGGER_PATH/bugreport
    echo "bugreport start..."
    bugreport > $ROOT_TRIGGER_PATH/bugreport/bugreport_${CURTIME}.txt
}

function copy_mtklog() {
    stoptime=`getprop sys.oppo.log.stoptime`;
    destpath="/sdcard/oppo_log/log@stop@${stoptime}"
    mkdir -p ${destpath}
    is_release=`getprop ro.build.release_type`
    if [ x"${is_release}" != x"true" ]; then
        newpath="sdcard/mtklog"
        MAX_NUM=5

        #ifdef VENDOR_EDIT
        #Zhiming.chen@PSW.AD.OppoLog.BugID 2724830, 2019/12/17,The log tool captures child user screenshots
        ALL_USER=`ls -t storage/emulated/`
        for m in $ALL_USER;
        do
            IDX=0
            screen_shot="/storage/emulated/$m/DCIM/Screenshots/"
            if [ -d "$screen_shot" ]; then
                mkdir -p ${newpath}/Screenshots/$m
                touch ${newpath}/Screenshots/$m/.nomedia
                ALL_FILE=`ls -t $screen_shot`
                for i in $ALL_FILE;
                do
                    echo "now we have file $i"
                    let IDX=$IDX+1;
                    echo ========file num is $IDX===========
                    if [ "$IDX" -lt $MAX_NUM ] ; then
                       echo  $i\!;
                       cp $screen_shot/$i ${newpath}/Screenshots/$m/
                    fi
                done
            fi
        done
        #endif /* VENDOR_EDIT */
    fi

    #Yujie.long@PSW.AD.OppoLog, 2020/02/26, add for cp recovery logs
    mkdir -p ${destpath}/recovery_log
    cp -rf /cache/recovery/* ${destpath}/recovery_log

    #mv fingerprint logs
    mkdir -p sdcard/mtklog/fingerprint
    mkdir -p sdcard/mtklog/fingerprint/silead
    mkdir -p sdcard/mtklog/fingerprint/gf_data
    mv /data/vendor/silead/* sdcard/mtklog/fingerprint/silead
    mv /data/vendor/fingerprint/gf_data/* sdcard/mtklog/fingerprint/gf_data
    #mv faceunlock logs
    mkdir -p sdcard/mtklog/faceunlock
    mv /data/vendor_de/0/faceunlock/* sdcard/mtklog/faceunlock/

    mv /sdcard/oppo_log/recovery_log/ /sdcard/mtklog/
    mv /sdcard/oppo_log/storage/ /sdcard/mtklog/
    mv /sdcard/oppo_log/trigger/* /sdcard/mtklog/
    mkdir -p /sdcard/mtklog/colorOS_TraceLog/
    cp /storage/emulated/0/ColorOS/TraceLog/trace_*.csv /sdcard/mtklog/colorOS_TraceLog/
    mv /sdcard/debuglogger/* /sdcard/mtklog/
    mtklog="/sdcard/mtklog"
    echo "destpath = ${destpath}"
    if [ -d  ${mtklog} ];
    then
        all_logs=`ls ${mtklog}`
        for i in ${all_logs};do
        echo ${i}
        #mv all folder or files in sdcard/oppo_log,except these files and folders
        if [ -d ${mtklog}/${i} ] || [ -f ${mtklog}/${i} ] && [ ${i} != "btlog" ]
        then
        echo " mv ${mtklog}/${i} ${destpath}"
        mv ${mtklog}/${i} ${destpath}
        fi
        done
    fi

    if [ -d ${mtklog}/btlog ]
    then
    #if has btlog ,create path
        mkdir -p ${destpath}/btlog
        btlogs=`ls ${mtklog}/btlog`
        for i in ${btlogs};do
        echo ${i}
        if [ ${i} != "btsnoop_hci.log" ]
        then
            echo "${mtklog}/btlog/${i}"
            mv ${mtklog}/btlog/${i}  ${destpath}/btlog
        fi
        done
    #copy btsnoop_hci.log
        cp sdcard/mtklog/btlog/btsnoop_hci.log ${destpath}/btlog
    fi
    #mv screen_record
    screen_record_path="sdcard/oppo_log/screen_record"
    if [ -d ${screen_record_path} ]
    then
        echo "has screen_record"
        mv ${screen_record_path} ${destpath}
    fi
    #mv data/oppo_log/
    mkdir -p ${destpath}/data_oppolog
    medianewpath=${destpath}/data_oppolog
    oppo_log="/data/oppo_log"
    if [ -d  ${oppo_log} ];
    then
        all_logs=`ls ${oppo_log} |grep -v junk_logs`
        for i in ${all_logs};do
        echo ${i}
        if [ -d ${oppo_log}/${i} ] || [ -f ${oppo_log}/${i} ] && [ ${i} != "sf" ]
        then
        echo " mv ===>"${i}
        mv ${oppo_log}/${i} ${medianewpath}/
        fi
        done
    fi

    #create anr_binder_info for it was moved
    mkdir -p /data/oppo_log/anr_binder_info
    chmod 777 /data/oppo_log/anr_binder_info

    if [ -d "/data/oppo_log/junk_logs" ]
    then
        mkdir -p ${medianewpath}/junk_logs/kernel
        mkdir -p ${medianewpath}/junk_logs/ftrace
        cp /data/oppo_log/junk_logs/kernel/* ${medianewpath}/junk_logs/kernel
        cp /data/oppo_log/junk_logs/ftrace/* ${medianewpath}/junk_logs/ftrace
        kernel_state=1

        while [ $kernel_state -lt 6 ]
        do
            ((kernel_state++))
            echo $kernel_state
            rm -rf data/oppo_log/junk_logs/kernel/*
            rm -rf data/oppo_log/junk_logs/ftrace/*
            break
        done
    fi

    #cp data/vendor/tombstones
    echo "copy data/vendor/tombstones"
    mkdir -p ${destpath}/vendor_tombstones
    cp /data/vendor/tombstones/* ${destpath}/vendor_tombstones

    mkdir -p ${destpath}/xlog
    mkdir -p ${destpath}/sub_xlog
    cp  /sdcard/tencent/MicroMsg/xlog/* ${destpath}/xlog/
    cp  /storage/emulated/999/tencent/MicroMsg/xlog/* ${destpath}/sub_xlog

    #get  proc/delllog
    cat /proc/dellog > ${destpath}/proc_dellog.txt

    #cp browser log and power log
    mkdir -p ${destpath}/Browser
    mkdir -p ${destpath}/psw_powermonitor_backup
    cp -rf sdcard/Coloros/Browser/.log/xlog/* ${destpath}/Browser/
    cp -rf data/oppo/psw/powermonitor_backup/ ${destpath}/psw_powermonitor_backup/

    mkdir -p ${destpath}/SI_stop
    ps -A -T > ${destpath}/SI_stop/ps.txt
    top -n 1 > ${destpath}/SI_stop/top.txt
    cat /proc/meminfo > ${destpath}/SI_stop/proc_meminfo.txt
    #dumpsys meminfo
    dumpsys -t 15 meminfo > ${destpath}/SI_stop/dumpsys_meminfo.txt &

    #dumpsys package
    dumpsys package  > ${destpath}/SI_stop/dumpsys_package.txt

    dumpsys power > ${destpath}/SI_stop/dumpsys_power.txt
    dumpsys alarm > ${destpath}/SI_stop/dumpsys_alarm.txt
    dumpsys batterystats > ${destpath}/SI_stop/dumpsys_batterystats.txt
    dumpsys batterystats -c > ${destpath}/SI_stop/battersystats_for_bh.txt

    #Chunbo.Gao@PSW.AD.OppoDebug.LogKit.NA, 2019/6/21, Add for thermalrec log
    dumpsys batterystats --thermalrec
    thermalrec_dir="/data/system/thermal/dcs"
    thermalstats_file="/data/system/thermalstats.bin"
    mkdir -p ${destpath}/SI_stop/power/thermalrec/
    if [ -f ${thermalstats_file} ];then
        cp -rf /data/system/thermalstats.bin ${destpath}/SI_stop/power/thermalrec/
    fi
    if [ -d ${thermalrec_dir} ]; then
        echo "copy Thermalrec..."
        cp -rf /data/system/thermal/dcs/* ${destpath}/SI_stop/power/thermalrec/
    fi
    #Chunbo.Gao@PSW.AD.OppoDebug.LogKit.NA, 2019/7/24, Add for powermonitor log
    powermonitor_dir="/data/oppo/psw/powermonitor"
    if [ -d ${powermonitor_dir} ]; then
        echo "copy Powermonitor..."
        mkdir -p ${destpath}/SI_stop/power/powermonitor/
        cp -rf /data/oppo/psw/powermonitor/* ${destpath}/SI_stop/power/powermonitor/
    fi
    #Chunbo.Gao@PSW.AD.OppoDebug.LogKit.NA, 2019/6/21, Add for tencent.ig
    tencent_pubgmhd_dir="/sdcard/Android/data/com.tencent.tmgp.pubgmhd/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Logs"
    if [ -d ${tencent_pubgmhd_dir} ]; then
        mkdir -p ${destpath}/os/Tencentlogs/pubgmhd
        echo "copy tencent.pubgmhd..."
        cp -rf ${tencent_pubgmhd_dir} ${destpath}/os/Tencentlogs/pubgmhd
    fi

    #assistantscreen
    assistantscreenlog=/sdcard/Download/AppmonitorSDKLogs/com.coloros.assistantscreen
    if [ -d "$assistantscreenlog" ]; then
        mkdir -p ${destpath}/os/Assistantscreen
        cp -rf ${assistantscreenlog}/* ${destpath}/os/Assistantscreen/
    fi

    #ovoicemanager
    ovoicemanagerlog=/sdcard/Android/data/com.oppo.ovoicemanager/files
    if [ -d "$ovoicemanagerlog" ]; then
        mkdir -p ${destpath}/os/ovoicemanager
        cp -rf ${ovoicemanagerlog}/* ${destpath}/os/ovoicemanager/
    fi

    OVMS_Aispeechlog=/sdcard/OVMS_Aispeech
    if [ -d "$OVMS_Aispeechlog" ]; then
        mkdir -p ${destpath}/os/OVMS_Aispeech
        cp -rf ${OVMS_Aispeechlog}/* ${destpath}/os/OVMS_Aispeech/
    fi

    OVMS_Recordinglog=/sdcard/OVMS_Recording
    if [ -d "$OVMS_Recordinglog" ]; then
        mkdir -p ${destpath}/os/OVMS_Recording
        cp -rf ${OVMS_Recordinglog}/* ${destpath}/os/OVMS_Recording/
    fi

    getprop > ${destpath}/SI_stop/prop.txt
    df > ${destpath}/SI_stop/df.txt
    mount > ${destpath}/SI_stop/mount.txt
    cat /proc/meminfo > ${destpath}/SI_stop/proc_meminfo.txt
    cat /data/system/packages.xml  > ${destpath}/SI_stop/packages.txt
    cat /data/system/appops.xml  > ${destpath}/SI_stop/appops.xml
    cat /proc/zoneinfo > ${destpath}/SI_stop/zoneinfo.txt
    cat /proc/slabinfo > ${destpath}/SI_stop/slabinfo.txt
    cat /proc/interrupts > ${destpath}/SI_stop/interrupts.txt
    cat /sys/kernel/debug/wakeup_sources > ${destpath}/SI_stop/wakeup_sources.log
    cp -rf /sys/kernel/debug/ion ${destpath}/SI_stop/

    #cp /data/system/users/0
    mkdir -p ${destpath}/user_0
    touch ${destpath}/user_0/.nomedia
    cp -rf data/system/users/0/* ${destpath}/user_0

    #cp /data/oppo_log/sf
    cp -rf data/oppo_log/sf ${destpath}/

    #mv /sdcard/oppo_log/am
    mv -f /sdcard/oppo_log/am ${destpath}/

    #cp dropbox traces tombstone
    cp -rf /data/system/dropbox ${destpath}/
    cp -rf /data/anr ${destpath}/
    cp -rf /data/tombstones ${destpath}/
    cp -rf /data/oppo/log ${destpath}/
    cp /data/system/critical_event.log ${destpath}/dropbox/

    #mv systrace
    mv sdcard/oppo_log/systrace ${destpath}/

    cp -rf /data/oppo/log/temp_log_config_en.xml ${destpath}/

    #cp /data/vendor/audiohal/audio_dump/ and /data/vendor/audiohal/aurisys_dump/
    mkdir -p ${destpath}/audiohal/audio_dump
    mkdir -p ${destpath}/audiohal/aurisys_dump
    cp -rf /data/vendor/audiohal/audio_dump/* ${destpath}/audiohal/audio_dump
    cp -rf /data/vendor/audiohal/aurisys_dump/* ${destpath}/audiohal/aurisys_dump
    rm -rf /data/vendor/audiohal/audio_dump/*
    rm -rf /data/vendor/audiohal/aurisys_dump/*

    #kevin.li@ROM.Framework, 2019/11/5, add for hans freeze manager
    hans_enable=`getprop persist.sys.enable.hans`
    if [ "$hans_enable" == "true" ]; then
         mkdir -p ${destpath}/hans/
         dumpsys activity hans history > ${destpath}/hans/hans_history.txt
    fi

    #kevin.li@ROM.Framework, 2019/11/5, add for hans freeze manager
    hans_enable=`getprop persist.vendor.enable.hans`
    if [ "$hans_enable" == "true" ]; then
         mkdir -p ${destpath}/hans/
         dumpsys activity hans history > ${destpath}/hans/hans_history.txt
    fi

    #cp /data/aee_exp/ and /data/vendor/aee_exp/
    mkdir -p ${destpath}/data_aee
    mkdir -p ${destpath}/vendor_aee
    cp -rf /data/aee_exp/* ${destpath}/data_aee
    cp -rf /data/vendor/aee_exp/* ${destpath}/vendor_aee
    rm -rf /data/aee_exp/*
    rm -rf /data/vendor/aee_exp/*
    wait
    setprop sys.tranfer.finished 1
}

function chmoddatamodem(){
    chmod 777 -R /data/modem_log/
}

function dump_sysinfo(){
    mkdir -p sdcard/oppo_log/trigger
    dumpsys > sdcard/oppo_log/trigger/dumpsys.txt;
}
function Dumpstate(){
    mkdir -p sdcard/oppo_log/trigger
    dumpstate > sdcard/oppo_log/trigger/dumpstate.txt
}
function Top(){
    mkdir -p sdcard/oppo_log/trigger
    top -n 1 > sdcard/oppo_log/trigger/top.txt;
}
function Ps(){
    mkdir -p sdcard/oppo_log/trigger
    ps > sdcard/oppo_log/trigger/ps.txt;
}

function Server(){
    mkdir -p sdcard/oppo_log/trigger
    service list  > sdcard/oppo_log/trigger/serviceList.txt;
}

function DumpStorage() {
    mkdir -p sdcard/oppo_log/storage
    mount > /sdcard/oppo_log/storage/mount.txt
    dumpsys devicestoragemonitor > /sdcard/oppo_log/storage/mount_device_storage_monitor.txt
    dumpsys mount > /sdcard/oppo_log/storage/mount_service.txt
    dumpsys diskstats > /sdcard/oppo_log/storage/diskstats.txt
    du -H /data > /sdcard/oppo_log/storage/diskUsage.txt
    echo "DumpStorage done"
}

function mvrecoverylog() {
    echo "mvrecoverylog begin"
    mkdir -p /sdcard/oppo_log/recovery_log
    mv /cache/recovery/* /sdcard/oppo_log/recovery_log
    echo "mvrecoverylog end"
}

function customdmesg() {
    echo "customdmesg begin"
    chmod 777 -R data/oppo_log/
    echo "customdmesg end"
}

function checkAeeLogs() {
    echo "checkAeeLogs begin"
    #cp -rf /data/vendor/aee_exp/* /data/oppo/log/DCS/de/AEE_DB/
    #cp -rf /data/aee_exp/* /data/oppo/log/DCS/de/AEE_DB/
    #rm -rf /data/vendor/aee_exp/*
    #rm -rf /data/aee_exp/*
    #restorecon -RF /data/oppo/log/DCS/de/AEE_DB/
    #chmod 777 -R /data/oppo/log/DCS/de/AEE_DB/
    #cp KE exception log to data/aee_exp for system_server can not access vendor files
    setprop sys.move.aeevendor.ready 0
    cp -rf /data/vendor/aee_exp/db.* /data/aee_exp/
    rm -rf /data/vendor/aee_exp/db.*
    restorecon -RF /data/aee_exp/
    chmod 777 -R /data/aee_exp/
    setprop sys.move.aeevendor.ready 1
    echo "checkAeeLogs end"
}

function DumpEnvironment(){
    setprop sys.dumpenvironment.finished 1
}

# Kun.Hu@TECH.BSP.Stability.Phoenix, 2019/4/17, fix the core domain limits to search hang_oppo dirent
function remount_opporeserve2()
{
    HANGOPPO_DIR_REMOUNT_POINT="/data/oppo/log/opporeserve/media/log/hang_oppo"
    if [ ! -d ${HANGOPPO_DIR_REMOUNT_POINT} ]; then
        mkdir -p ${HANGOPPO_DIR_REMOUNT_POINT}
    fi
    chmod -R 0770 /data/oppo/log/opporeserve
    chgrp -R system /data/oppo/log/opporeserve
    chown -R system /data/oppo/log/opporeserve
    mount /mnt/vendor/opporeserve/media/log/hang_oppo ${HANGOPPO_DIR_REMOUNT_POINT}
}

#Liang.Zhang@TECH.Storage.Stability.OPPO_SHUTDOWN_DETECT, 2019/04/28, Add for shutdown detect
function remount_opporeserve2_shutdown()
{
    OPPORESERVE2_REMOUNT_POINT="/data/oppo/log/opporeserve/media/log/shutdown"
    if [ ! -d ${OPPORESERVE2_REMOUNT_POINT} ]; then
        mkdir ${OPPORESERVE2_REMOUNT_POINT}
    fi
    chmod 0770 /data/oppo/log/opporeserve
    chgrp system /data/oppo/log/opporeserve
    chown system /data/oppo/log/opporeserve
    mount /mnt/vendor/opporeserve/media/log/shutdown ${OPPORESERVE2_REMOUNT_POINT}
}

#ifdef VENDOR_EDIT
#Xuefeng.Peng@PSW.AD.Performance.Storage.1721598, 2018/12/26, Add for abnormal sd card shutdown long time
function fsck_shutdown() {
    needshutdown=`getprop persist.sys.fsck_shutdown`
    if [ x"${needshutdown}" == x"true" ]; then
        setprop persist.sys.fsck_shutdown "false"
        ps -A | grep fsck.fat  > /data/media/0/fsck_fat
        #echo "fsck test start" >> /data/media/0/fsck.txt

        #DATE=`date +%F-%H-%M-%S`
        #echo "${DATE}" >> /data/media/0/fsck.txt
        #echo "fsck test end" >> /data/media/0/fsck.txt
    fi
}

#Xuefeng.Peng@PSW.AD.Performance.Storage.1721598, 2018/12/26, Add for customize version to control sdcard
#Kang.Zou@PSW.AD.Performance.Storage.1721598, 2019/10/17, Add for customize version to control sdcard with new methods
function exstorage_support() {
    exStorage_support=`getprop persist.sys.exStorage_support`
    if [ x"${exStorage_support}" == x"1" ]; then
        #echo 1 > /sys/class/mmc_host/mmc0/exStorage_support
        echo 1 > /sys/bus/mmc/drivers_autoprobe
        mmc_devicename=$(ls /sys/bus/mmc/devices | grep "mmc0:")
        if [ -n "$mmc_devicename" ];then
            echo "$mmc_devicename" > /sys/bus/mmc/drivers/mmcblk/bind
        fi
        #echo "fsck test start" >> /data/media/0/fsck.txt

        #DATE=`date +%F-%H-%M-%S`
        #echo "${DATE}" >> /data/media/0/fsck.txt
        #echo "fsck test end" >> /data/media/0/fsck.txt
    fi
    if [ x"${exStorage_support}" == x"0" ]; then
        #echo 0 > /sys/class/mmc_host/mmc0/exStorage_support
        echo 0 > /sys/bus/mmc/drivers_autoprobe
        mmc_devicename=$(ls /sys/bus/mmc/devices | grep "mmc0:")
        if [ -n "$mmc_devicename" ];then
            echo "$mmc_devicename" > /sys/bus/mmc/drivers/mmcblk/unbind
        fi
        #echo "fsck test111 start" >> /data/media/0/fsck.txt

        #DATE=`date +%F-%H-%M-%S`
        #echo "${DATE}" >> /data/media/0/fsck.txt
        #echo "fsck test111 end" >> /data/media/0/fsck.txt
    fi
}
#endif /*VENDOR_EDIT*/

#ifdef VENDOR_EDIT
#Xiaomin.Yang@PSW.CN.BT.Basic.Customize.1586031,2018/12/02, Add for updating wcn firmware by sau_res
function wcnfirmwareupdate(){

    saufwdir="/data/oppo/common/sau_res/res/SAU-AUTO_LOAD_FW-10/"
    pushfwdir="/data/misc/firmware/push/"
    if [ -f ${saufwdir}/ROMv4_be_patch_1_0_hdr.bin ]; then
        cp  ${saufwdir}/ROMv4_be_patch_1_0_hdr.bin  ${pushfwdir}
        chown system:system ${pushfwdir}/ROMv4_be_patch_1_0_hdr.bin
        chmod 666 ${pushfwdir}/ROMv4_be_patch_1_0_hdr.bin
    fi

    if [ -f ${saufwdir}/ROMv4_be_patch_1_1_hdr.bin ]; then
        cp  ${saufwdir}/ROMv4_be_patch_1_1_hdr.bin  ${pushfwdir}
        chown system:system ${pushfwdir}/ROMv4_be_patch_1_1_hdr.bin
        chmod 666 ${pushfwdir}/ROMv4_be_patch_1_1_hdr.bin
    fi

    if [ -f ${saufwdir}/WIFI_RAM_CODE_6759 ]; then
       cp  ${saufwdir}/WIFI_RAM_CODE_6759  ${pushfwdir}
       chown system:system ${pushfwdir}/WIFI_RAM_CODE_6759
       chmod 666 ${pushfwdir}/WIFI_RAM_CODE_6759
    fi

    if [ -f ${saufwdir}/soc2_0_patch_mcu_3_1_hdr.bin ]; then
       cp  ${saufwdir}/soc2_0_patch_mcu_3_1_hdr.bin  ${pushfwdir}
       chown system:system ${pushfwdir}/soc2_0_patch_mcu_3_1_hdr.bin
       chmod 666  ${pushfwdir}/soc2_0_patch_mcu_3_1_hdr.bin
    fi

    if [ -f ${saufwdir}/soc2_0_ram_mcu_3_1_hdr.bin ]; then
       cp  ${saufwdir}/soc2_0_ram_mcu_3_1_hdr.bin  ${pushfwdir}
       chown system:system ${pushfwdir}/soc2_0_ram_mcu_3_1_hdr.bin
       chmod 666  ${pushfwdir}/soc2_0_ram_mcu_3_1_hdr.bin
    fi

    if [ -f ${saufwdir}/soc2_0_ram_bt_3_1_hdr.bin ]; then
       cp  ${saufwdir}/soc2_0_ram_bt_3_1_hdr.bin  ${pushfwdir}
       chown system:system ${pushfwdir}/soc2_0_ram_bt_3_1_hdr.bin
       chmod 666 ${pushfwdir}/soc2_0_ram_bt_3_1_hdr.bin
    fi

    if [ -f ${saufwdir}/soc2_0_ram_wifi_3_1_hdr.bin ]; then
       cp  ${saufwdir}/soc2_0_ram_wifi_3_1_hdr.bin  ${pushfwdir}
       chown system:system ${pushfwdir}/soc2_0_ram_wifi_3_1_hdr.bin
       chmod 666 ${pushfwdir}/soc2_0_ram_wifi_3_1_hdr.bin
    fi

    if [ -f ${saufwdir}/WIFI_RAM_CODE_soc2_0_3_1.bin ]; then
       cp  ${saufwdir}/WIFI_RAM_CODE_soc2_0_3_1.bin  ${pushfwdir}
       chown system:system ${pushfwdir}/WIFI_RAM_CODE_soc2_0_3_1.bin
       chmod 666 ${pushfwdir}/WIFI_RAM_CODE_soc2_0_3_1.bin
    fi

    if [ -f ${saufwdir}/soc2_0_patch_mcu_3a_1_hdr.bin ]; then
       cp  ${saufwdir}/soc2_0_patch_mcu_3a_1_hdr.bin  ${pushfwdir}
       chown system:system ${pushfwdir}/soc2_0_patch_mcu_3a_1_hdr.bin
       chmod 666  ${pushfwdir}/soc2_0_patch_mcu_3a_1_hdr.bin
    fi

    if [ -f ${saufwdir}/soc2_0_ram_mcu_3a_1_hdr.bin ]; then
       cp  ${saufwdir}/soc2_0_ram_mcu_3a_1_hdr.bin  ${pushfwdir}
       chown system:system ${pushfwdir}/soc2_0_ram_mcu_3a_1_hdr.bin
       chmod 666  ${pushfwdir}/soc2_0_ram_mcu_3a_1_hdr.bin
    fi

    if [ -f ${saufwdir}/soc2_0_ram_bt_3a_1_hdr.bin ]; then
       cp  ${saufwdir}/soc2_0_ram_bt_3a_1_hdr.bin  ${pushfwdir}
       chown system:system ${pushfwdir}/soc2_0_ram_bt_3a_1_hdr.bin
       chmod 666 ${pushfwdir}/soc2_0_ram_bt_3a_1_hdr.bin
    fi

    if [ -f ${saufwdir}/soc2_0_ram_wifi_3a_1_hdr.bin ]; then
       cp  ${saufwdir}/soc2_0_ram_wifi_3a_1_hdr.bin  ${pushfwdir}
       chown system:system ${pushfwdir}/soc2_0_ram_wifi_3a_1_hdr.bin
       chmod 666 ${pushfwdir}/soc2_0_ram_wifi_3a_1_hdr.bin
    fi

    if [ -f ${saufwdir}/WIFI_RAM_CODE_soc2_0_3a_1.bin ]; then
       cp  ${saufwdir}/WIFI_RAM_CODE_soc2_0_3a_1.bin  ${pushfwdir}
       chown system:system ${pushfwdir}/WIFI_RAM_CODE_soc2_0_3a_1.bin
       chmod 666 ${pushfwdir}/WIFI_RAM_CODE_soc2_0_3a_1.bin
    fi

    if [ -f ${saufwdir}/push.log ]; then
       cp  ${saufwdir}/push.log  ${pushfwdir}
    fi

}

function wcnfirmwareupdatedump(){

    logfwdir="/data/misc/firmware/"
    wifidir="/data/misc/wifi/"
    if [ -f ${logfwdir}/wcn_fw_update_result.conf ]; then
       cp  ${logfwdir}/wcn_fw_update_result.conf  ${wifidir}
       chown wifi:wifi ${wifidir}/wcn_fw_update_result.conf
       chmod 777  ${wifidir}/wcn_fw_update_result.conf
    fi
}

#endif /* VENDOR_EDIT */

#ifdef VENDOR_EDIT
#Laixin@PSW.CN.WiFi.Basic.Switch.1069763, 2018/09/03
#Add for: collect Wifi Switch Log
function collectWifiSwitchLog() {
    boot_completed=`getprop sys.boot_completed`
    while [ x${boot_completed} != x"1" ];do
        sleep 2
        boot_completed=`getprop sys.boot_completed`
    done

    wifiSwitchLogPath="/data/oppo_log/wifi_switch_log"
    if [ ! -d  ${wifiSwitchLogPath} ];then
        mkdir -p ${wifiSwitchLogPath}
    fi

    dmesg > ${wifiSwitchLogPath}/dmesg.txt
    /system/bin/logcat -b main -b system -f ${wifiSwitchLogPath}/android.txt -r10240 -v threadtime *:V
}

function packWifiSwitchLog() {
    wifiSwitchLogPath="/data/oppo_log/wifi_switch_log"
    sdcard_oppolog="/sdcard/oppo_log"
    DCS_WIFI_LOG_PATH="/data/oppo/log/DCS/de/network_logs/wifiSwitch"
    logReason=`getprop oppo.wifi.switch.log.reason`
    logFid=`getprop oppo.wifi.switch.log.fid`
    version=`getprop ro.build.version.ota`
    if [ "w${logReason}" == "w" ];then
        return
    fi

    if [ ! -d ${DCS_WIFI_LOG_PATH} ];then
        mkdir -p ${DCS_WIFI_LOG_PATH}
        chown system:system ${DCS_WIFI_LOG_PATH}
        chmod -R 777 ${DCS_WIFI_LOG_PATH}
    fi

    if [ "${logReason}" == "wifi_service_check" ];then
        file=`ls /sdcard/oppo_log | grep ${logReason}`
        abs_file=${sdcard_oppolog}/${file}
        echo ${abs_file}
    else
        if [ ! -d  ${wifiSwitchLogPath} ];then
            return
        fi
        $XKIT tar -czvf  ${DCS_WIFI_LOG_PATH}/${logReason}.tar.gz -C ${wifiSwitchLogPath} ${wifiSwitchLogPath}
        abs_file=${DCS_WIFI_LOG_PATH}/${logReason}.tar.gz
    fi
    fileName="wifi_turn_on_failed@${logFid}@${version}@${logReason}.tar.gz"
    mv ${abs_file} ${DCS_WIFI_LOG_PATH}/${fileName}
    chown system:system ${DCS_WIFI_LOG_PATH}/${fileName}
    setprop sys.oppo.wifi.switch.log.stop 0
    rm -rf ${wifiSwitchLogPath}
}

#Guotian.Wu add for wifi p2p connect fail log
function collectWifiP2pLog() {
    boot_completed=`getprop sys.boot_completed`
    while [ x${boot_completed} != x"1" ];do
        sleep 2
        boot_completed=`getprop sys.boot_completed`
    done
    wifiP2pLogPath="/data/oppo_log/wifi_p2p_log"
    if [ ! -d  ${wifiP2pLogPath} ];then
        mkdir -p ${wifiP2pLogPath}
    fi

    # collect driver and firmware log
    cnss_pid=`getprop vendor.oppo.wifi.cnss_diag_pid`
    if [[ "w${cnss_pid}" != "w" ]];then
        kill -s SIGUSR1 $cnss_pid
        sleep 2
        mv /data/vendor/wifi/buffered_wlan_logs/* $wifiP2pLogPath
        chmod 666 ${wifiP2pLogPath}/buffered*
    fi

    dmesg > ${wifiP2pLogPath}/dmesg.txt
    /system/bin/logcat -b main -b system -f ${wifiP2pLogPath}/android.txt -r10240 -v threadtime *:V
}

function packWifiP2pFailLog() {
    wifiP2pLogPath="/data/oppo_log/wifi_p2p_log"
    DCS_WIFI_LOG_PATH=`getprop oppo.wifip2p.connectfail`
    logReason=`getprop oppo.wifi.p2p.log.reason`
    logFid=`getprop oppo.wifi.p2p.log.fid`
    version=`getprop ro.build.version.ota`

    if [ "w${logReason}" == "w" ];then
        return
    fi

    if [ ! -d ${DCS_WIFI_LOG_PATH} ];then
        mkdir -p ${DCS_WIFI_LOG_PATH}
        chown system:system ${DCS_WIFI_LOG_PATH}
        chmod -R 777 ${DCS_WIFI_LOG_PATH}
    fi

    if [ ! -d  ${wifiP2pLogPath} ];then
        return
    fi

    $XKIT tar -czvf  ${DCS_WIFI_LOG_PATH}/${logReason}.tar.gz -C ${wifiP2pLogPath} ${wifiP2pLogPath}
    abs_file=${DCS_WIFI_LOG_PATH}/${logReason}.tar.gz

    fileName="wifip2p_connect_fail@${logFid}@${version}@${logReason}.tar.gz"
    mv ${abs_file} ${DCS_WIFI_LOG_PATH}/${fileName}
    chown system:system ${DCS_WIFI_LOG_PATH}/${fileName}
    setprop sys.oppo.wifi.p2p.log.stop 0
    rm -rf ${wifiP2pLogPath}
}

function mvWifiSwitchLog() {
    DCS_WIFI_LOG_PATH="/data/oppo/log/DCS/de/network_logs/wifiSwitch"
    DCS_WIFI_CELLULAR_LOG_PATH="/data/oppo/log/DCS/de/network_logs/wifiSwitchByCellular"

    if [ ! -d ${DCS_WIFI_CELLULAR_LOG_PATH} ];then
        mkdir -p ${DCS_WIFI_CELLULAR_LOG_PATH}
        chmod -R 777 ${DCS_WIFI_CELLULAR_LOG_PATH}
    fi
    mv ${DCS_WIFI_LOG_PATH}/* ${DCS_WIFI_CELLULAR_LOG_PATH}
}
#endif /* VENDOR_EDIT */

#Li.Liu@PSW.AD.Stability.Crash.1296298, 2018/03/14, Add for trying to recover from sysetm hang
function recover_hang()
{
 sleep 30
 boot_completed=`getprop sys.oppo.boot_completed`
 if [ x${boot_completed} != x"1" ]; then
    #after 20s, scan system has not finished, use debuggerd to catch system_server native trace
    system_server_pid=`ps -A | grep system_server | $XKIT awk '{print $2}'`
    debuggerd -b ${system_server_pid} > /data/system/dropbox/recover_hang_${system_server_pid}_$(date +%F-%H-%M-%S)_30;
 fi
 #sleep more 70s for the first time to boot
 sleep 70
 boot_completed=`getprop sys.oppo.boot_completed`
 if [ x${boot_completed} != x"1" ]; then
    system_server_pid=`ps -A | grep system_server | $XKIT awk '{print $2}'`
    #use debuggerd to catch system_server native trace
    debuggerd -b ${system_server_pid} > /dev/null;
 fi
}
#endif /* VENDOR_EDIT */

#Add for mount mnt/vendor/opporeserve/stamp to data/oppo/log/stamp
function remount_opporeserve2_stamp_to_data()
{
    DATA_STAMP_MOUNT_POINT="/data/oppo/log/stamp"
    OPPORESERVE_STAMP_MOUNT_PATH="/mnt/vendor/opporeserve"
    OPPORESERVE_STAMP_MOUNT_POINT="/mnt/vendor/opporeserve/media/log/stamp"
    if [ -d ${OPPORESERVE_STAMP_MOUNT_PATH} ]; then
        echo "opporeserve path exist"
        if [ ! -d ${DATA_STAMP_MOUNT_POINT} ]; then
            mkdir ${DATA_STAMP_MOUNT_POINT}
        fi
        chmod -R 0770 ${DATA_STAMP_MOUNT_POINT}
        chown -R system ${DATA_STAMP_MOUNT_POINT}
        chgrp -R system ${DATA_STAMP_MOUNT_POINT}
        if [ ! -d ${OPPORESERVE_STAMP_MOUNT_POINT} ]; then
            mkdir ${OPPORESERVE_STAMP_MOUNT_POINT}
        fi
        chmod -R 0770 ${OPPORESERVE_STAMP_MOUNT_POINT}
        chown -R system ${OPPORESERVE_STAMP_MOUNT_POINT}
        chgrp -R system ${OPPORESERVE_STAMP_MOUNT_POINT}
        mount ${OPPORESERVE_STAMP_MOUNT_POINT} ${DATA_STAMP_MOUNT_POINT}
    fi
}

#ifdef VENDOR_EDIT
#Shuangquan.du@PSW.AD.Recovery.0, 2019/07/03, add for generate runtime prop
function generate_runtime_prop() {
    getprop | sed -r 's|\[||g;s|\]||g;s|: |=|' > /cache/runtime.prop
    chown root:root /cache/runtime.prop
    chmod 600 /cache/runtime.prop
    backupMinidump
}
#endif

#add for oidt begin
function oidtlogs() {
    setprop sys.oppo.oidtlogs 0
    mkdir -p sdcard/OppoStamp
    mkdir -p sdcard/OppoStamp/db
    mkdir -p sdcard/OppoStamp/log/stable

    mkdir -p sdcard/OppoStamp/config
    cp system/etc/sys_stamp_config.xml sdcard/OppoStamp/config/
    cp data/system/sys_stamp_config.xml sdcard/OppoStamp/config/

    cp -r data/oppo/log/DCS/de/minidump/ sdcard/OppoStamp/log/stable
    cp -r data/oppo/log/DCS/en/minidump/ sdcard/OppoStamp/log/stable
    cp -r data/oppo/log/DCS/de/AEE_DB/ sdcard/OppoStamp/log/stable
    cp -r data/oppo/log/DCS/en/AEE_DB/ sdcard/OppoStamp/log/stable
    cp -r data/vendor/aee_exp/ sdcard/OppoStamp/log/stable
    mkdir -p sdcard/OppoStamp/log/performance
    cat /proc/meminfo > sdcard/OppoStamp/log/performance/meminfo_fs.txt
    dumpsys -t 15 meminfo > sdcard/OppoStamp/log/performance/meminfo_dump.txt
    cat proc/slabinfo > sdcard/OppoStamp/log/performance/slabinfo_fs.txt
    mkdir -p sdcard/OppoStamp/log/power
    #ifdef COLOROS_EDIT
    #SunYi@Rom.Framework, 2019/11/25, add for collect trace_viewer log
    mkdir -p sdcard/OppoStamp/log/power/trace_viewer/de
    mkdir -p sdcard/OppoStamp/log/power/trace_viewer/en
    cp -r /data/oppo/log/DCS/de/trace_viewer sdcard/OppoStamp/log/power/trace_viewer/de
    cp -r /data/oppo/log/DCS/en/trace_viewer sdcard/OppoStamp/log/power/trace_viewer/en
    #endif /* COLOROS_EDIT */
    #SunYi@Rom.Framework, 2020/01/10, modify for collect powermonitor log
    #am broadcast --user all -a android.intent.action.ACTION_OPPO_SAVE_BATTERY_HISTORY_TO_SD  com.oppo.oppopowermonitor
    #sleep 3
    cp /data/oppo/psw/powermonitor_backup  -r sdcard/OppoStamp/log/power
    #endif /* COLOROS_EDIT */
    dumpsys batterystats --thermalrec > sdcard/OppoStamp/log/power/thermalrec.txt
    dumpsys batterystats --thermallog > sdcard/OppoStamp/log/power/thermallog.txt
    setprop sys.oppo.oidtlogs 1
}
#add for oidt end

#ifdef VENDOR_EDIT
#Bin.Li@BSP.Fingerprint.Secure 2018/12/27, Add for oae get bootmode
function oae_bootmode(){
    boot_modei_info=`cat /sys/power/app_boot`
    if [ "$boot_modei_info" == "kernel" ]; then
        setprop ro.oae.boot.mode kernel
      else
        setprop ro.oae.boot.mode normal
    fi
}
#endif /* VENDOR_EDIT */

#ifdef VENDOR_EDIT
#Miao.Yu@PSW.AD.WMS, 2019/11/25, Add for dump info when screenshot
function screencapdump() {
    if [ ! -d /sdcard/oppo_log/am/ ];then
    mkdir -p /sdcard/oppo_log/am/
    fi

    LOGTIME=`date +%F-%H-%M-%S`
    DIR=sdcard/oppo_log/am/${LOGTIME}
    mkdir -p ${DIR}
    dumpsys window -a > ${DIR}/windows.txt
    dumpsys activity a > ${DIR}/activities.txt
    dumpsys activity -v top > ${DIR}/top_activity.txt
}
#endif /* VENDOR_EDIT */

#ifdef VENDOR_EDIT
#zhaochengsheng@PSW.CN.WiFi.Basic.Custom.2204034, 2019/07/29
#add for Add for:solve camera interference ANT.
function iwprivswapant0(){
    iwpriv wlan0 driver 'SET_CHIP AntSwapManualCtrl 1 0'
    iwpriv wlan0 driver 'SET_CHIP AntSwapManualCtrl 0'
}

function iwprivswapant1(){
    iwpriv wlan0 driver 'SET_CHIP AntSwapManualCtrl 1 1'
}

function iwprivswitchswapant(){
    iwpriv wlan0 driver 'SET_CHIP AntSwapManualCtrl 1 0'
}
#endif /* VENDOR_EDIT */

#ifdef VENDOR_EDIT
#genglin.lian@PSW.CN.WiFi.Connect.Network.2566837, 2019/9/23
#Add enable/disable interface for SmartGear
function disableSmartGear() {
    iwpriv wlan0 driver 'set_chip SmartGear 9 0'
}

function enableSmartGear() {
    iwpriv wlan0 driver 'set_chip SmartGear 9 1'
}
#endif /* VENDOR_EDIT */
#ifdef VENDOR_EDIT
#Junhao.Liang@AD.OppoLog.bug000000, 2020/01/02, Add for OTA to catch log
function resetlogfirstbootbuffer() {
    echo "resetlogfirstbootbuffer start"
    setprop sys.tranfer.finished "resetlogfirstbootbuffer start"
    enable=`getprop persist.sys.assert.panic`
    argfalse='false'
    if [ "${enable}" = "${argfalse}" ]; then
    /system/bin/logcat -G 256K
    fi
    echo "resetlogfirstbootbuffer end"
    setprop sys.tranfer.finished "resetlogfirstbootbuffer end"
}

function logfirstbootmain() {
    echo "logfirstbootmain begin"
    setprop sys.tranfer.finished "logfirstbootmain begin"
    path=/data/oppo_log/firstboot
    mkdir -p ${path}
    /system/bin/logcat -G 5M
    /system/bin/logcat  -f ${path}/android.txt -r10240 -v threadtime *:V
    setprop sys.tranfer.finished "logfirstbootmain end"
    echo "logfirstbootmain end"
}

function logfirstbootevent() {
    echo "logfirstbootevent begin"
    setprop sys.tranfer.finished "logfirstbootevent begin"
    path=/data/oppo_log/firstboot
    mkdir -p ${path}
    /system/bin/logcat -b events -f ${path}/event.txt -r10240 -v threadtime *:V
    setprop sys.tranfer.finished "logfirstbootevent end"
    echo "logfirstbootevent end"
}

function logfirstbootkernel() {
    echo "logfirstbootkernel begin"
    setprop sys.tranfer.finished "logfirstbootkernel begin"
    path=/data/oppo_log/firstboot
    mkdir -p ${path}
    dmesg > ${path}/kinfo_boot.txt
    setprop sys.tranfer.finished "logfirstbootkernel end"
    echo "logfirstbootkernel end"
}
#endif /* VENDOR_EDIT */

#ifdef VENDOR_EDIT
#Hailong.Liu@ANDROID.MM, 2020/03/18, add for capture native malloc leak on aging_monkey test
function storeSvelteLog() {
    local dest_dir="/data/oppo/heapdump/svelte/"
    local log_file="${dest_dir}/svelte_log.txt"
    local log_dev="/dev/svelte_log"
    local err_file="/data/oppo_log/svelte_error.txt"

    if [ ! -c ${log_dev} ]; then
        echo "svelte ${log_dev} does not exist." >> ${err_file}
        return 1
    fi

    if [ ! -d ${dest_dir} ]; then
        mkdir -p ${dest_dir}
        if [ "$?" -ne "0" ]; then
            echo "svelte mkdir failed." >> ${err_file}
            return 1
        fi
        chmod 0777 ${dest_dir}
    fi

    if [ ! -f ${log_file} ]; then
        echo --------Start `date` >> ${log_file}
        if [ "$?" -ne "0" ]; then
            echo "svelte create file failed." >> ${err_file}
            return 1
        fi
        chmod 0777 ${log_file}
    fi

    while true
    do
        echo --------`date` >> ${log_file}
        /system/bin/svelte logger >> ${log_file}
    done
}
#endif

case "$config" in

#ifdef VENDOR_EDIT
#Yanzhen.Feng 2015/12/09, Add for SurfaceFlinger Layer dump
    "layerdump")
        layerdump
        ;;
#endif /* VENDOR_EDIT */
#ifdef VENDOR_EDIT
#Shuangquan.du@PSW.AD.Recovery.0, 2019/07/03, add for generate runtime prop
    "generate_runtime_prop")
        generate_runtime_prop
        ;;
#endif
#Haoran.Zhang@PSW.AD.BuildConfig.StandaloneUserdata.0, 2017/09/13, Add for set prop sys.build.display.full_id
    "userdatarefresh")
        userdatarefresh
        ;;
#end
#ifdef VENDOR_EDIT
#Xuefeng.Peng@PSW.AD.Performance.Storage.1721598, 2018/12/26, Add for abnormal sd card shutdown long time
    "fsck_shutdown")
        fsck_shutdown
        ;;
    "exstorage_support")
        exstorage_support
        ;;
#endif /* VENDOR_EDIT */
#ifdef VENDOR_EDIT
#Yanzhen.Feng 2017/03/20, Add for systrace on phone
    "cont_systrace")
        cont_systrace
        ;;
#endif /* VENDOR_EDIT */
    "junklogcat")
        junklogcat
    ;;
    "junkdmesg")
        junkdmesg
    ;;
    "junkststart")
        junksystrace_start
    ;;
    "junkststop")
        junksystrace_stop
    ;;
    "cleanjunk")
        cleanjunk
    ;;
    "gettpinfo")
        gettpinfo
    ;;
    "inittpdebug")
        inittpdebug
    ;;
    "junklogmonitor")
        junk_log_monitor
    ;;
    "cpoppousage")
        cpoppousage
    ;;
    "screen_record")
        screen_record
    ;;
    "settplevel")
        settplevel
    ;;
    "write_off")
        write_logswitch_off
    ;;
    "write_on")
        write_logswitch_on
    ;;
#ifdef VENDOR_EDIT
#Deliang.Peng, 2017/7/7,add for native watchdog
    "nativedump")
        nativedump
    ;;
#endif /* VENDOR_EDIT */
#Jianping.Zheng2017/05/08, Add for systemserver futex_wait block check
        "checkfutexwait")
        do_check_systemserver_futexwait_block
    ;;
    "checkfutexwait_wrap")
        checkfutexwait_wrap
#end, add for systemserver futex_wait block check
#Jianping.Zheng 2017/04/04, Add for record performance
    ;;
        "perf_record")
        perf_record
    ;;
        "powerlog")
        powerlog
    ;;
    #Fei.Mo, 2017/09/01 ,Add for power monitor top info
    "thermal_top")
        thermalTop
    #end, Add for power monitor top info
    ;;
#Canjie.Zhang@PSW.AD.OppoDebug.LogKit.1080426, 2017/11/09, Add for logkit2.0 clean log command
    "cleanlog")
        cleanlog
    ;;
#Linjie.Xu@PSW.AD.Power.PowerMonitor.1104067, 2018/01/17, Add for OppoPowerMonitor get dmesg at O
        "kernelcacheforopm")
        kernelcacheforopm
    ;;
    "screen_record_backup")
        screen_record_backup
        ;;
    "copy_screenshot")
        copy_screenshot
        ;;
    "pwkdumpon")
        pwkdumpon
        ;;
    "pwkdumpoff")
        pwkdumpoff
        ;;
#ifdef VENDOR_EDIT
#Chunbo.Gao@PSW.AD.OppoDebug.LogKit.BugID, 2019/4/10, Add for full dump & mini dump
    "mrdumpon")
        mrdumpon
        ;;
    "mrdumpoff")
        mrdumpoff
        ;;
#endif /* VENDOR_EDIT */
    "copy_mtklog")
        copy_mtklog
        ;;
    "chmoddatamodem")
        chmoddatamodem
        ;;
    "ps")
        Ps
        ;;
    "top")
        Top
        ;;
    "server")
        Server
        ;;
    "dump_sysinfo")
        dump_sysinfo
        ;;
    "dumpstate")
        Dumpstate
        ;;
    "dump_storage")
        DumpStorage
        ;;
        "mvrecoverylog")
        mvrecoverylog
    ;;
        "customdmesg")
        customdmesg
    ;;
        "checkAeeLogs")
        checkAeeLogs
    ;;
        "dumpenvironment")
        DumpEnvironment
    ;;
        "smapsforhealth")
        smapsforhealth
    ;;
        "slabinfoforhealth")
        slabinfoforhealth
    ;;
        "svelteforhealth")
        svelteforhealth
    ;;    
        "meminfoforhealth")
        meminfoforhealth
    ;;
        "dmaprocsforhealth")
        dmaprocsforhealth
    ;;
#ifdef VENDOR_EDIT
#Xiaomin.Yang@PSW.CN.BT.Basic.Customize.1586031,2018/12/02, Add for updating wcn firmware by sau
    "wcnfirmwareupdate")
        wcnfirmwareupdate
        ;;
    "wcnfirmwareupdatedump")
        wcnfirmwareupdatedump
        ;;
#endif /* VENDOR_EDIT */
#laixin@PSW.CN.WiFi.Basic.Switch.1069763, 2018/09/03, Add for collect wifi switch log
        "collectWifiSwitchLog")
        collectWifiSwitchLog
    ;;
        "packWifiSwitchLog")
        packWifiSwitchLog
    ;;
        "mvWifiSwitchLog")
        mvWifiSwitchLog
    ;;
#end
# Kun.Hu@PSW.TECH.RELIABILTY, 2019/1/3, fix the core domain limits to search /mnt/vendor/opporeserve
        "remount_opporeserve2")
        remount_opporeserve2
    ;;
#Liang.Zhang@TECH.Storage.Stability.OPPO_SHUTDOWN_DETECT, 2019/04/28, Add for shutdown detect
        "remount_opporeserve2_shutdown")
        remount_opporeserve2_shutdown
    ;;
#Li.Liu@PSW.AD.Stability.Crash.1296298, 2018/03/14, Add for trying to recover from sysetm hang
    "recover_hang")
        recover_hang
        ;;
#Jiemin.Zhu@PSW.AD.Memroy.Performance, 2017/10/12, add for low memory device
    "lowram_device_setup")
        lowram_device_setup
        ;;
#ifdef VENDOR_EDIT
#Bin.Li@BSP.Fingerprint.Secure 2018/12/27, Add for oae get bootmode
        "oae_bootmode")
        oae_bootmode
    ;;
#endif /* VENDOR_EDIT */
#ifdef VENDOR_EDIT
#QiLong.Ao@PSW.AD.OppoDebug.LogKit.1067207, 2019/04/03, Add for clean pcm dump file.
    "cleanpcmdump")
        cleanpcmdump
    ;;
#endif /* VENDOR_EDIT */
#Add for mount mnt/vendor/opporeserve/stamp to data/oppo/log/stamp
        "remount_opporeserve2_stamp_to_data")
        remount_opporeserve2_stamp_to_data
    ;;
        "oidtlogs")
        oidtlogs
    ;;
#ifdef VENDOR_EDIT
#zhaochengsheng@PSW.CN.WiFi.Basic.Custom.2204034, 2019/07/29
#add for Add for:solve camera interference ANT.
    "iwprivswapant0")
        iwprivswapant0
    ;;
    "iwprivswapant1")
        iwprivswapant1
    ;;
    "iwprivswitchswapant")
        iwprivswitchswapant
    ;;
#endif /* VENDOR_EDIT */

#Wenshuai.Chen@RM.AD.OppoDebug.LogKit.NA, 2020/06/02, Add for bugreport log
        "dump_bugreport")
        dump_bugreport
    ;;

#ifdef VENDOR_EDIT
#genglin.lian@PSW.CN.WiFi.Connect.Network.23456788, 2019/9/23
#Add enable/disable interface for SmartGear
    "disableSmartGear")
        disableSmartGear
    ;;
    "enableSmartGear")
        enableSmartGear
    ;;
#endif /* VENDOR_EDIT */
#add for firstboot log
        "resetlogfirstbootbuffer")
        resetlogfirstbootbuffer
    ;;
        "logfirstbootmain")
        logfirstbootmain
    ;;
        "logfirstbootevent")
        logfirstbootevent
    ;;
        "logfirstbootkernel")
        logfirstbootkernel
    ;;
#ifdef VENDOR_EDIT
#Hailong.Liu@ANDROID.MM, 2020/03/18, add for capture native malloc leak on aging_monkey test
        "storeSvelteLog")
        storeSvelteLog
    ;;
#endif /*VENDOR_EDIT*/    
       *)

      ;;
esac

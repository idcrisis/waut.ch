#!/data/data/ch.waut/files/bin/busybox sh

ARG=$1

if [ "x$ARG" = "xRUN" ]; then
  cd /data/data/ch.waut/files/bin && PATH=. busybox nice -n +5 busybox sh -x cb_io.sh $2 > ../cb_io.log 2>&1 &
  return 0
fi

if [ "x$ARG" != "xFORCE" ]; then
  return 1
fi

set +e
trap " " 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15
export APP=/data/data/ch.waut/files/bin
export PATH=${APP}
alias [='busybox ['
alias [[='busybox [['
alias ECHO='busybox echo '
alias SYSCTL='busybox timeout -t 3 -s KILL busybox sysctl -e -w '
alias SETPROP='/system/bin/setprop '
alias GETPROP='/system/bin/getprop '
if [ "$(GETPROP persist.cb_io.enabled 2>/dev/null)" = "FALSE" ]; then return 0; fi

MEM=$(busybox free 2>/dev/null | busybox grep Mem 2>/dev/null | busybox awk '{ print $2 }' 2>/dev/null)

#busybox fsync /data 
#busybox fsync /system 
#busybox fsync /cache 
#busybox fsync /sdcard 

#busybox sysctl -w vm.drop_caches=1 
#busybox sync 

busybox mount -t debugfs -o rw none /sys/kernel/debug 

if [ -e /sys/kernel/debug/sched_features ]; then
  ECHO NO_NORMALIZED_SLEEPER > /sys/kernel/debug/sched_features 
  ECHO GENTLE_FAIR_SLEEPERS > /sys/kernel/debug/sched_features 
  ECHO NO_NEW_FAIR_SLEEPERS > /sys/kernel/debug/sched_features 
fi

busybox umount /sys/kernel/debug 

busybox umount -l /sys/kernel/debug 

for i in $(busybox timeout -t 15 -s KILL busybox find /sys/devices /sys/block /dev/block -name read_ahead_kb 2>/dev/null); do ECHO 0 | busybox tee $i; done

if [ 1 = 0 ]; then 

for i in $(busybox timeout -t 15 -s KILL busybox find /sys/devices /sys/block /dev/block -name nr_requests 2>/dev/null); do ECHO 100000 | busybox tee $i ; done

for i in $(busybox timeout -t 15 -s KILL busybox find /sys/devices /sys/block /dev/block -name rq_affinity 2>/dev/null); do ECHO 2 | busybox tee $i ; done
for i in $(busybox timeout -t 15 -s KILL busybox find /sys/devices /sys/block /dev/block -name rotational 2>/dev/null); do ECHO 0 | busybox tee $i ; done
for i in $(busybox timeout -t 15 -s KILL busybox find /sys/devices /sys/block /dev/block -name nomerges 2>/dev/null); do ECHO 2 | busybox tee $i ; done
for i in $(busybox timeout -t 15 -s KILL busybox find /sys/devices /sys/block /dev/block -name iostats 2>/dev/null); do ECHO 0 | busybox tee $i ; done
for i in $(busybox timeout -t 15 -s KILL busybox find /sys/devices /sys/block /dev/block -name low_latency 2>/dev/null); do ECHO 1 | busybox tee $i ; done

#for i in $(busybox timeout -t 15 -s KILL busybox find /sys/devices /sys/block /dev/block -name discard_max_bytes 2>/dev/null); do ECHO 4096 | busybox tee $i ; done

# Skip for md devices.

for i in $(busybox timeout -t 15 -s KILL busybox find /sys/devices /sys/block /dev/block -name fifo_batch 2>/dev/null); do ECHO 1 | busybox tee $i ; done

fi

for i in $(busybox timeout -t 15 -s KILL busybox find /sys/devices /sys/block /dev/block -name scheduler 2>/dev/null); do 
  busybox chmod 666 $i
  ECHO noop | busybox tee $i ; 
#  busybox chmod 444 $i
done


if [ ! -e /sys/devices/system/cpu/cpufreq/interactive ]; then 
  busybox chmod 666 /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 
  ECHO interactive | busybox tee /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 
fi

cd /sys/devices/system/cpu/cpufreq/interactive

for i in 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
 if [ -e /sys/devices/system/cpu/cpu$i/cpufreq/scaling_governor ]; then 
  busybox chmod 666 /sys/devices/system/cpu/cpu$i/cpufreq/scaling_governor 
  ECHO interactive | busybox tee /sys/devices/system/cpu/cpu$i/cpufreq/scaling_governor 
 fi
done

cd /sys/devices/system/cpu/cpufreq/interactive

if [ "$(busybox pwd 2>/dev/null)" = "/sys/devices/system/cpu/cpufreq/interactive" ]; then 
    ECHO 20000 | busybox tee above_hispeed_delay 
    ECHO 0 | busybox tee boost 
    ECHO 80000 | busybox tee boostpulse_duration 
    ECHO 80000 | busybox tee boosttop_duration 
    ECHO 99 | busybox tee go_hispeed_load 
    ECHO 99 | busybox tee go_maxspeed_load 
    ECHO 1 | busybox tee input_dev_monitor 
    ECHO 1 | busybox tee input_boost 
    ECHO 0 | busybox tee io_is_busy 
    ECHO 80000 | busybox tee min_sample_time 
    ECHO 90 | busybox tee target_loads 
    ECHO 90 | busybox tee target_load 
    ECHO 90 | busybox tee sustain_load 
    ECHO 20000 | busybox tee timer_rate 
    ECHO 80000 | busybox tee timer_slack 
fi

cd ${APP}

SYSCTL vm.overcommit_ratio=49
ECHO 49 | busybox tee /proc/sys/vm/overcommit_ratio

SYSCTL vm.overcommit_memory=1

if [ 1 = 0 ]; then 

SETPROP dalvik.vm.heapstartsize 5m
SETPROP dalvik.vm.heapgrowthlimit 72m
SETPROP dalvik.vm.heapsize 96m
SETPROP dalvik.vm.heapminfree 512k
SETPROP dalvik.vm.heapmaxfree 2m
SETPROP dalvik.vm.heaptargetutilization 0.75


if [ "x$MEM" != "x" ]; then 
  if [ "$MEM" -lt "600000" ]; then
    SETPROP dalvik.vm.heapgrowthlimit 48m
    SETPROP dalvik.vm.heapsize 64m
    SETPROP dalvik.vm.heaptargetutilization 0.75
  fi
fi

fi

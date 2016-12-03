#!/temp/bin/sh

# add /temp/bin to path
PATH="/temp/bin:$PATH"

###
#
# PART OF HIJACK RAMDISK
#
###
# 
# Copyright (c) 2016 Izumi Inami (droidfivex)
# 
# Permission is hereby granted, free of charge, to any person obtaining a 
# copy of this software and associated documentation files (the 
# "Software"), to deal in the Software without restriction, including 
# without limitation the rights to use, copy, modify, merge, publish, 
# distribute, sublicense, and/or sell copies of the Software, and to 
# permit persons to whom the Software is furnished to do so, subject to 
# the following conditions:
#
# The above copyright notice and this permission notice shall be 
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND 
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE 
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION 
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION 
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
###
#
# collect informations.
# unmount testing.
# hijack recovery.
#
# [ VOL - ]: unmount tester
# [ VOL + ]: hijack recovery
#
# put this file to /system/hijack/hijack.sh
#
###

# put on the led lights
LED () {
	local red="/sys/class/leds/lm3533-red/brightness" 
	local green="/sys/class/leds/lm3533-green/brightness"
	local blue="/sys/class/leds/lm3533-blue/brightness" 
	if [ "$1" = "" ]; then
		echo 0 > $red
		echo 0 > $green
		echo 0 > $blue
	else
		echo $1 > $red
		echo $2 > $green
		echo $3 > $blue
	fi
}

# prepare, remount / and create folders
PREPARE () {
	mount -o remount,rw rootfs /
	mkdir -p /temp/event/
}

# check mountpoint / process
CHECKENV () {
	# ORANGE
	LED 255 69 0

	mkdir -p /temp/log
	mount > /temp/log/post_mount.txt
	ps aux > /temp/log/post_ps_aux.txt
	ls -laR > /temp/log/post_ls_laR.txt
	getprop > /temp/log/post_getprop.txt
	dmesg > /temp/log/post_dmesg.txt
}

# send message
KMSG () {
	echo $1 > /dev/kmsg
}

# unmount
UNMOUNT () {
	if [ "$1" = "test" ]; then
		# SALMON
		LED 250 128 114

		mount -o rw,remount /system
		mkdir -p /system/hijack/logs
		cp -r /temp/log /system/hijack/logs/post_log
		mkdir -p /system/hijack/logs/unmount_log
	fi

	# none
	umount -l /acct
	umount -l /dev/cpuctl

	# debugfs
	umount -l /sys/kernel/debug

	# devptfs
	umount -l /dev/pts

	# pertitions
	if [ "$1" = "test" ]; then
		### temp commented out for writing logs
		### umount -l /dev/block/platform/msm_sdcc.1/by-name/system
		:
	else
		umount -l /dev/block/platform/msm_sdcc.1/by-name/system
	fi
	umount -l /dev/block/platform/msm_sdcc.1/by-name/userdata
	umount -l /dev/block/platform/msm_sdcc.1/by-name/apps_log
	umount -l /dev/block/platform/msm_sdcc.1/by-name/cache

	# tmpfs
	umount -l /mnt/secure
	umount -l /mnt/asec
	umount -l /mnt/obb
	umount -l /dev/cpuctl
	umount -l /dtvtmp/dtv
	umount -l /mnt/idd
	umount -l /mnt/qcks

	# write changes
	sync

	if [ "$1" = "test" ]; then
		# WRITE LOGS (to system)
		mount > /system/hijack/logs/unmount_log/unmount_mount.txt
		ps aux > /system/hijack/logs/unmount_log/unmount_ps_aux.txt
		ls -laR > /system/hijack/logs/unmount_log/unmount_ls_laR.txt
		getprop > /system/hijack/logs/unmount_log/unmount_getprop.txt
		dmesg > /system/hijack/logs/unmount_log/unmount_dmesg.txt
	fi
}

# process killer
KILLER () {
	local svcname
	local runningprc
	local lockingpid
	local binary

	# kill services
	for svcname in $(getprop | grep -E '^\[init\.svc\..*\]: \[running\]' | sed 's/\[init\.svc\.\(.*\)\]:.*/\1/g;')
	do
		stop $svcname
		if [ -f "/system/bin/${svcname}" ]; then
			pkill -f /system/bin/${svcname}
		fi
	done

	# kill processes
	for runningprc in $(ps | grep /system/bin | grep -v grep | grep -v chargemon | awk '{print $1}' ) 
	do
		kill -9 $runningprc
	done
	for runningprc in $(ps | grep /sbin | grep -v grep | awk '{print $1}' )
	do
		kill -9 $runningprc
	done

	# kill locking pidfile
	for lockingpid in `lsof | awk '{print $1" "$2}' | grep "/bin\|/system\|/data\|/cache" | awk '{print $1}'`; do
		binary=$(cat /proc/${lockingpid}/status | grep -i "name" | awk -F':\t' '{print $2}')
		if [ "$binary" != "" ]; then
			killall $binary
		fi
	done

	sync
}

# VIBRAT
VIBRAT () {
	local viberator="/sys/class/timed_output/vibrator/enable"
	if [ "$1" = "" ]; then
		echo 150 > $viberator
	else
		echo $1 > $viberator
	fi
}

# unset
UNSET () {
	unset LED
	unset PREPARE
	unset CHECKENV
	unset KMSG
	unset MAIN
	unset UNMOUNT
	unset SWITCH
	unset VIBRAT
	unset RECOVERY
	unset KILLER
}

# recovery
RECOVERY () {
	# GREEN
	LED 0 128 0

	# prepare hijack
	KILLER
	sleep 1
	UNMOUNT
	sleep 1

	# unpack recovery ramdisk image
	mkdir /recovery
	cd /recovery

	# unpack recovery ramdisk image
	gzip -dc /temp/ramdisk/ramdisk-recovery.img | cpio -i

	# write changes
	sync

	# power off LED...
	LED

	# hijack!
	chroot /recovery /init
}

# get switch
SWITCH () {
	# declaration
	local eventdev
	local suffix
	local catproc

	# AQUAMARINE
	LED 127 255 212

	# vibration
	VIBRAT

	# get event
	for eventdev in $(ls /dev/input/event*)
	do
		suffix="$(expr ${eventdev} : '/dev/input/event\(.*\)')"
		cat ${eventdev} > /temp/event/key${suffix} &
	done
	sleep 2

	# kill cat (4 rows up)
	for catproc in $(ps | grep " cat" | grep -v grep | awk '{print $1;}')
	do
		kill -9 ${catproc}
	done
	sleep 1

	# tell end of cat events to users / off led
	LED

	# check keys event
	hexdump /temp/event/key* | grep -e '^.* 0001 0073 .... ....$' > /temp/event/keycheck_up
	hexdump /temp/event/key* | grep -e '^.* 0001 0072 .... ....$' > /temp/event/keycheck_down
	sleep 1

	# VOL -
	if [ -s /temp/event/keycheck_down ]; then
		KMSG "[hijack] testing unmount..."
		UNMOUNT test
		reboot
	fi

	# VOL +
	if [ -s /temp/event/keycheck_up ]; then
		KMSG "[hijack] hijack to recovery..."
		RECOVERY
	fi
}

# main
MAIN () {
	KMSG "[hijack] prepareing..."
	PREPARE

	KMSG "[hijack] collect informations..."
	CHECKENV

	# switch
	SWITCH

	# clean-up
	UNSET
}

MAIN

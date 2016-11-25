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
	mkdir /temp/
	mkdir /temp/bin/
}

# check mountpoint / process
CHECKENV () {
	mkdir /temp/log
	mount > /temp/log/post_mount.txt
	ps aux > /temp/log/post_ps_aux.txt
	ls -laR > /temp/log/post_ls_laR.txt
	getprop > /temp/log/post_getprop.txt
	
}

# send message
KMSG () {
	echo $1 > /dev/kmsg
}

# unset
UNSET () {
	unset LED
	unset PREPARE
	unset CHECKENV
	unset KMSG
	unset MAIN
}

# main
MAIN () {
	# AQUAMARINE
	LED 127 255 212
	# you can see LED easier.
	sleep 1

	# GREEN
	LED 85 107 47

	KMSG "[hijack] prepareing..."
	PREPARE

	KMSG "[hijack] collect informations..."
	CHECKENV

	# FOREST GREEN
	LED 34 139 34

	KMSG "[hijack] cleaning up..."
	UNSET
	LED
}

MAIN

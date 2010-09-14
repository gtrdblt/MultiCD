#!/bin/sh
set -e
#Ubuntu/casper common functions for multicd.sh
#version 5.8
#Copyright (c) 2010 maybeway36
#
#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in
#all copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
#THE SOFTWARE.
if [ $1 = scan ] || [ $1 = copy ] || [ $1 = writecfg ] || [ $1 = category ];then
	exit 0 #This is not a plugin itself
fi
if [ ! -z "$1" ] && [ -f $1.iso ];then
	if [ ! -d $1 ];then
		mkdir $1
	fi
	if grep -q "`pwd`/$1" /etc/mtab ; then
		umount $1
	fi
	mount -o loop $1.iso $1/
	cp -R $1/casper multicd-working/boot/$1 #Live system
	if [ -d $1/preseed ];then
		cp -R $1/preseed multicd-working/boot/$1
	fi
	# Fix the isolinux.cfg
	if [ -f $1/isolinux/text.cfg ];then
		UBUCFG=text.cfg
	elif [ -f $1/isolinux/txt.cfg ];then
		UBUCFG=txt.cfg
	else
		UBUCFG=isolinux.cfg #For custom-made live CDs
	fi
	cp $1/isolinux/$UBUCFG multicd-working/boot/$1/$1.cfg
	sed -i "s@default live@default menu.c32@g" multicd-working/boot/$1/$1.cfg #Show menu instead of boot: prompt
	sed -i "s@file=/cdrom/preseed/@file=/cdrom/boot/$1/preseed/@g" multicd-working/boot/$1/$1.cfg #Preseed folder moved - not sure if ubiquity uses this
	sed -i "s^initrd=/casper/^live-media-path=/boot/$1 ignore_uuid initrd=/boot/$1/^g" multicd-working/boot/$1/$1.cfg #Initrd moved, ignore_uuid added
	sed -i 's^kernel /casper/^kernel /boot/$1/^g' multicd-working/boot/$1/$1.cfg #Kernel moved
	if [ $(cat tags/lang) != en ];then
		sed -i "s^initrd=/casper/^debian-installer/language=$(cat tags/lang) console-setup/layoutcode?=$(cat tags/lang) initrd=/casper/^g" multicd-working/boot/$1/$1.cfg #Add language codes to cmdline - does not change keyboard AFAIK
	fi
	umount $1;rmdir $1
else
	echo "$0: \"$1\" is empty or not an ISO"
	exit 1
fi

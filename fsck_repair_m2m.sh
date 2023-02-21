#!/bin/bash

umount /dev/mmcblk1p1
umount /dev/mmcblk1p3
umount /dev/mmcblk1p4
mount /dev/mmcblk1p1 /run/media/mmcblk1p1/
sync
ret_check()
{
	#echo "disk_check() $1"
	if [ $1 -eq 0 ];then
		echo "Seems recovery success!"
		if [ $2 -eq 2 ];then
			echo "Seems all recovery completed! Rebooting..."
			echo "`date` : Rootfs $2 recovery attempted and successful!" >> /run/media/mmcblk1p1/recovery_log.txt
			reboot
		fi
	else
		echo "Seems recovery failed! Rebooting..."
		echo "`date` : Rootfs recovery $2 attempted and failed!" >> /run/media/mmcblk1p1/recovery_log.txt
	fi
}

fsck -f -y /dev/mmcblk1p4
ret_check $? 1
sync
fsck -f -y /dev/mmcblk1p3
ret_check $? 2
sync

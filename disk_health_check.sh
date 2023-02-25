#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

#INFO: Do not change the following names
KERNEL=./zImage
DTB=./mys-6ull-14x14-emmc.dtb
KERNEL_BKP=./zImage_bkp
DTB_BKP=./mys-6ull-14x14-emmc-bkp.dtb
DISK=mmcblk1
CRC_FILE=/sbin/crc_calc_verify.py


if (( $EUID != 0 )); then
	echo -e "${RED}Please run as root${NC}"
	exit
fi

if [ ! -f "$CRC_FILE" ]; then
	echo -e "${RED}$CRC_FILE is not found in current dir!.${NC}"
	exit -1
fi

# Check Primary Partition Healthy along with its primary & backup images
# Check Secondary Partition Healthy along with its primary & backup images
# Check rootfs Partition
# Check FW Partition

# Unmount all partitions
umount /dev/${DISK}p1
umount /dev/${DISK}p2
rm -rf /run/media/${DISK}p1
rm -rf /run/media/${DISK}p2

mkdir -p /run/media/${DISK}p1
mkdir -p /run/media/${DISK}p2


recover_from_sd()
{
	if [ $1 -ne 0 ];then
		echo "Try from SD..."
	fi
}

disk_check()
{
	#echo "disk_check() $1"
	if [ $1 -ne 0 ];then
		echo -e "${RED}$2${NC}"

		if [[ $3 == "1" ]];then
			echo "Primary image corrupted in primary partition(Part1)"
			mount /dev/${DISK}p1 /mnt
			mount /dev/${DISK}p2 /run/media/${DISK}p2/
			cp -rf /run/media/${DISK}p2/* /mnt
			recover_from_sd $? "Unable to take copy from PART2, trying from SD now" 11
			umount /dev/${DISK}p1
			umount /dev/${DISK}p2
			sync
			sleep 3
			echo "Recoverd from image corruption in PART1"
		fi

		if [[ $3 == "2" ]];then
			echo "Primary partition (Part1) got corrupted"
			# Format it & Mount
			umount /dev/${DISK}p1
			mkfs.vfat /dev/${DISK}p1
			sleep 2
			mount /dev/${DISK}p2 /run/media/${DISK}p2/
			mount /dev/${DISK}p1 /mnt
			sleep 2
			# Take a copy from Part2
			cp -rf /run/media/${DISK}p2/* /mnt
			recover_from_sd $? "Unable to take copy from PART2, trying from SD now" 11
			umount /dev/${DISK}p1
			umount /dev/${DISK}p2
			sync
			sleep 3
			echo "Recoverd from PART1 corruption"
		fi

		if [[ $3 == "3" ]];then
			echo "Primary image corrupted in secondary partition(Part2)"
			mount /dev/${DISK}p2 /mnt
			mount /dev/${DISK}p1 /run/media/${DISK}p1/
			cp -rf /run/media/${DISK}p1/* /mnt
			recover_from_sd $? "Unable to take copy from PART2, trying from SD now" 22
			umount /dev/${DISK}p1
			umount /dev/${DISK}p2
			sync
			sleep 3
			echo "Recoverd from image corruption in PART2"
		fi

		if [[ $3 == 11 ]];then
			echo "Part1 Mount is failed"
			# Format it & Mount
			umount /dev/${DISK}p1
			mkfs.vfat /dev/${DISK}p1
			sleep 2
			mount /dev/${DISK}p2 /run/media/${DISK}p2/
			mount /dev/${DISK}p1 /mnt
			sleep 2
			# Take a copy from Part2
			cp -rf /run/media/${DISK}p2/* /mnt
			recover_from_sd $? "Unable to take copy from PART2, trying from SD now" 22
			umount /dev/${DISK}p1
			umount /dev/${DISK}p2
			sync
			sleep 3
			echo "Recoverd from PART1 corruption"
		fi

		if [[ $3 == 22 ]];then
			echo "Part2 Mount is failed"
			# Format it & Mount
			umount /dev/${DISK}p2
			mkfs.vfat /dev/${DISK}p2
			sleep 2
			mount /dev/${DISK}p1 /run/media/${DISK}p1/
			mount /dev/${DISK}p2 /mnt
			sleep 2
			# Take a copy from Part1
			cp -rf /run/media/${DISK}p1/* /mnt
			recover_from_sd $? "Unable to take copy from PART1, trying from SD now" 11
			umount /dev/${DISK}p1
			umount /dev/${DISK}p2
			sync
			sleep 3
			echo "Recoverd from PART2 corruption"
		fi

		if [[ $3 == 9 ]];then
			echo "CRC verify is failed for Part1"
			umount /dev/${DISK}p1
			umount /dev/${DISK}p2
			mount /dev/${DISK}p1 /mnt
			mount /dev/${DISK}p2 /run/media/${DISK}p2/
			cp -rf /run/media/${DISK}p2/* /mnt
			recover_from_sd $? "Unable to take copy from PART2, trying from SD now" 11
			sync
			umount /run/media/${DISK}p2/
			umount /mnt
			sync
			sleep 3
			mount /dev/${DISK}p1 /run/media/${DISK}p1
			mount /dev/${DISK}p2 /run/media/${DISK}p2
			echo "Recoverd from image corruption in PART1"
		fi

		if [[ $3 == 99 ]];then
			echo "CRC verify is failed for Part2"
			umount /dev/${DISK}p1
			umount /dev/${DISK}p2
			mount /dev/${DISK}p2 /mnt
			mount /dev/${DISK}p1 /run/media/${DISK}p1/
			cp -rf /run/media/${DISK}p1/* /mnt
			recover_from_sd $? "Unable to take copy from PART1, trying from SD now" 11
			sync
			umount /run/media/${DISK}p1/
			umount /mnt
			sync
			sleep 3
			mount /dev/${DISK}p1 /run/media/${DISK}p1
			mount /dev/${DISK}p2 /run/media/${DISK}p2
			echo "Recoverd from image corruption in PART2"
		fi
	fi
}


boot_fail=$(`echo `cat /proc/cmdline | awk -F'boot=| ro' '{print $2}'``)
disk_check 1 "################## Boot Fail Check Script ##################" $boot_fail


# Part1 health check
mount /dev/${DISK}p1 /run/media/${DISK}p1
disk_check $? "Mounting Part1 is failed!" 11

# Part2 health check
mount /dev/${DISK}p2 /run/media/${DISK}p2
disk_check $? "Mounting Part2 is failed!" 22

umount /dev/${DISK}p1
umount /dev/${DISK}p2


mount /dev/${DISK}p1 /run/media/${DISK}p1
mount /dev/${DISK}p2 /run/media/${DISK}p2

# Check boot files CRC (zImage & dtb) on partition1
mkdir -p /tmp/boot_verify
python3 ${CRC_FILE} -i /run/media/${DISK}p1/$KERNEL -d /run/media/${DISK}p1/$DTB -io /tmp/boot_verify/i_v.bin -do /tmp/boot_verify/d_v.bin
disk_check $? "Serious Issue: CRC Verify is failed for PART1!" 9
sleep 1 # give time to remount under /run/media/*
rm /tmp/boot_verify/i_v.bin /tmp/boot_verify/d_v.bin
python3 ${CRC_FILE} -i /run/media/${DISK}p1/$KERNEL -d /run/media/${DISK}p1/$DTB -io /tmp/boot_verify/i_v.bin -do /tmp/boot_verify/d_v.bin
diff /tmp/boot_verify/i_v.bin /run/media/${DISK}p1/i.bin
disk_check $? "Serious Issue: CRC mismatch for Kernel/i.bin for PART1!" 9
diff /tmp/boot_verify/d_v.bin /run/media/${DISK}p1/d.bin
disk_check $? "Serious Issue: CRC mismatch for DTB/d.bin for PART1!" 9

# Check backup boot files CRC (zImage & dtb) on partition1
python3 ${CRC_FILE} -i /run/media/${DISK}p1/$KERNEL_BKP -d /run/media/${DISK}p1/$DTB_BKP -io /tmp/boot_verify/i_v.bin -do /tmp/boot_verify/d_v.bin
disk_check $? "Serious Issue: CRC Verify is failed for backup image in PART1!" 9
sleep 1 # give time to remount under /run/media/*
rm /tmp/boot_verify/i_v.bin /tmp/boot_verify/d_v.bin
python3 ${CRC_FILE} -i /run/media/${DISK}p1/$KERNEL_BKP -d /run/media/${DISK}p1/$DTB_BKP -io /tmp/boot_verify/i_v.bin -do /tmp/boot_verify/d_v.bin
diff /tmp/boot_verify/i_v.bin /run/media/${DISK}p1/i.bin
disk_check $? "Serious Issue: CRC mismatch for Kernel/i.bin for backup image in PART1!" 9
diff /tmp/boot_verify/d_v.bin /run/media/${DISK}p1/d.bin
disk_check $? "Serious Issue: CRC mismatch for DTB/d.bin for backup image in PART1!" 9



# Check boot files CRC (zImage & dtb) on partition2
mkdir -p /tmp/boot_verify
python3 ${CRC_FILE} -i /run/media/${DISK}p2/$KERNEL -d /run/media/${DISK}p2/$DTB -io /tmp/boot_verify/i_v.bin -do /tmp/boot_verify/d_v.bin
disk_check $? "Serious Issue: CRC Verify is failed! for PART2" 99
sleep 1 # give time to remount under /run/media/*
rm /tmp/boot_verify/i_v.bin /tmp/boot_verify/d_v.bin
python3 ${CRC_FILE} -i /run/media/${DISK}p2/$KERNEL -d /run/media/${DISK}p2/$DTB -io /tmp/boot_verify/i_v.bin -do /tmp/boot_verify/d_v.bin
diff /tmp/boot_verify/i_v.bin /run/media/${DISK}p2/i.bin
disk_check $? "Serious Issue: CRC mismatch for Kernel/i.bin for PART2!" 99
diff /tmp/boot_verify/d_v.bin /run/media/${DISK}p2/d.bin
disk_check $? "Serious Issue: CRC mismatch for DTB/d.bin for PART2!" 99

# Check backup boot files CRC (zImage & dtb) on partition2
mkdir -p /tmp/boot_verify
python3 ${CRC_FILE} -i /run/media/${DISK}p2/$KERNEL_BKP -d /run/media/${DISK}p2/$DTB_BKP -io /tmp/boot_verify/i_v.bin -do /tmp/boot_verify/d_v.bin
disk_check $? "Serious Issue: CRC Verify is failed! for backup image in PART2" 99
sleep 1 # give time to remount under /run/media/*
rm /tmp/boot_verify/i_v.bin /tmp/boot_verify/d_v.bin
python3 ${CRC_FILE} -i /run/media/${DISK}p2/$KERNEL_BKP -d /run/media/${DISK}p2/$DTB_BKP -io /tmp/boot_verify/i_v.bin -do /tmp/boot_verify/d_v.bin
diff /tmp/boot_verify/i_v.bin /run/media/${DISK}p2/i.bin
disk_check $? "Serious Issue: CRC mismatch for Kernel/i.bin for backup image in PART2!" 99
diff /tmp/boot_verify/d_v.bin /run/media/${DISK}p2/d.bin
disk_check $? "Serious Issue: CRC mismatch for DTB/d.bin for backup image in PART2!" 99


rm -rf /tmp/boot_verify



#if boot == 1
#	primary image corrupted in primary partition
#if boot == 2
#	primary partition got corrupted
#if boot == 3
#	secondary image corrupted in secondary partition

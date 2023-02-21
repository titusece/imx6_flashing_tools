#!/usr/bin/env bash

image_name=$1
part_no=$2
part_name=$3
part_type=$4

# get_part_info start|size DISK_IMAGE PARTITION_NUMBER
function get_part_info {
	local cmd=$1
	local img_file=$2
	local part_no=$3

	val=`sfdisk -d $img_file | grep "^$img_file$part_no" | grep -oP "(?<=$cmd=)[ \\d+]*"`
	if [ "$?" -eq 0 ]; then
		echo "$(( ${val//[[:blank:]]/} * 512 ))"
	else
		exit 1
	fi
}

# losetup_partition DISK_IMAGE PARTITION_NUMBER
function losetup_partition {
	local part_start=$(get_part_info start $1 $2)
	local part_size=$(get_part_info size $1 $2)
	losetup -f --show --offset $part_start --sizelimit $part_size $1
}

function losetup_delete_retry {
	sync
	until losetup -d $1
	do
		sleep 1
	done

	# Wait a bit, weird race condition
	sleep 2
}

lodev=$(losetup_partition $image_name $part_no)
partprobe $lodev
echo "Image -> '$image_name', formatting partition on $lodev, part no -> '$part_no', format type -> '$part_type', name -> '$part_name'"

if [ "$part_type" == "fat32" ]
then
	mkfs.vfat -n $part_name -F 32 $lodev
elif [ "$part_type" == "ext4" ]
then
	echo "EXT4 type"
	mkfs.ext4 -b 4096 -E stride=16384,stripe-width=16384 -m 1 -L $part_name $lodev
else
	echo "no type"
fi
losetup_delete_retry $lodev

#!/bin/bash

# SD image create
IMG=sd_sombrero_tmp.img

# eMMC image create
#IMG=emmc_sombrero_tmp.img

if (( $EUID != 0 )); then
	echo -e "Please run as root"
	exit
fi

cmd_check()
{
	if [ $1 -ne 0 ];then
		echo -e "$2"
		exit -1
	fi
}

:'
For eMMC card:
===============
<10MB gap> --> This is for uboot
-> Create a 1st partition for kernel & dtb --> (100M)
<10MB gap> --> This is for safer side for not touching other area
-> Create a 2nd partition for kernel & dtb backup --> (100M)
<10MB gap> --> This is for safer side for not touching other area
-> Create a 3rd partition for rootfs (RO) --> (2600M)
<10MB gap> --> This is for safer side for not touching other area
-> Create a 4th partition for firmware (RW) --> (~500M)

	sudo dd if=/dev/zero of=emmc_sombrero.img bs=1024 count=$(((3300 + 1) * 1024))
	sudo sfdisk --force emmc_sombrero.img <<EOF
	    10M,100M,0c
	    120M,100M,0c
	    230M,2600M,83
	    2840M,,83
	EOF

For SD card:
===============
<10MB gap> --> This is for uboot
-> Create a 1st partition for kernel & dtb --> (100M)
<10MB gap> --> This is for safer side for not touching other area
-> Create a 2nd partition for kernel & dtb backup --> (100M)
<10MB gap> --> This is for safer side for not touching other area
-> Create a 3rd partition for rootfs (RO) --> (4300M)
<10MB gap> --> This is for safer side for not touching other area
-> Create a 4th partition for firmware (RW) --> (~500M)

	sudo dd if=/dev/zero of=${IMG} bs=1024 count=$(((5000 + 1) * 1024))
	sudo sfdisk --force ${IMG} <<EOF
	    10M,100M,0c
	    120M,100M,0c
	    230M,4300M,83
	    2840M,,83
	EOF
'

# Create empty 5GB disk
echo "Creating disk..."
sudo dd if=/dev/zero of=${IMG} bs=1024 count=$(((5000 + 1) * 1024))
cmd_check $? "dd is failed!"

# Partition the 5GB disk
sudo sfdisk --force ${IMG} <<EOF
    10M,100M,0c
    120M,100M,0c
    230M,4300M,83
    2840M,,83
EOF
cmd_check $? "sfdisk is failed!"

# Format the partitions
echo "Formatting partitions..."
./format_fs_image.sh ${IMG} 1 BOOT fat32
./format_fs_image.sh ${IMG} 2 BOOT_BKP fat32
./format_fs_image.sh ${IMG} 3 rootfs ext4
./format_fs_image.sh ${IMG} 4 firmware ext4

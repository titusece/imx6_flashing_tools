#!/bin/bash
# Run this script in iMX6ULL board for flashing into eMMC

RED='\033[0;31m'
BOLDRED='\033[1;4;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

IMG=~/emmc_flashing/emmc_sombrero.img
UBOOT=~/emmc_flashing/u-boot-emmc.imx

if (( $EUID != 0 )); then
	echo -e "${RED}Please run as root${NC}"
	exit
fi

help()
{
	echo -e "${YELLOW}INFO: $0 This script is intended to run on i.MX6ULL SOC ${NC}"
	exit 1
}

if [[ $1 == "--help" ]]; then
	help
fi

if [[ $1 == "-h" ]]; then
	help
fi


if [ ! -f "$IMG" ]; then
	echo -e "${RED}$IMG is not found in current dir!.${NC}"
	exit -1
fi
if [ ! -f "$UBOOT" ]; then
	echo -e "${RED}$UBOOT is not found in current dir!.${NC}"
	exit -1
fi

cmd_check()
{
	if [ $1 -ne 0 ];then
		echo -e "${RED}$2${NC}"
		exit -1
	fi
}


echo -e "${YELLOW}This Tools is used to flash the Linux OS into eMMC using i.MX6ULL board. And not intended to run on Linux Host PC.${NC}"
read -r -p "Are you sure? [y/N] " response
case "$response" in
	[yY][eE][sS]|[yY]) 
		echo -e "Continuing..."
		;;
	*)
		exit
		;;
esac

# Unmount the device
umount /dev/mmcblk1*

echo -e "${YELLOW}Flashing Linux OS into eMMC${NC}"
echo -e "${YELLOW}It would take some time to finish! Have some coffee! :)${NC}"
dd if=${IMG} of=/dev/mmcblk1 bs=1M
cmd_check $? "Flashing ${IMG} is failed!"
sync

echo -e "${YELLOW}Flashing U-boot into eMMC${NC}"

#dd if=${UBOOT} of=/dev/mmcblk1 bs=1k seek=1 status=progress

# Unlock
echo 0 > /sys/block/mmcblk1boot0/force_ro
dd if=${UBOOT} of=/dev/mmcblk1boot0 bs=1k seek=1
cmd_check $? "Flashing ${UBOOT} 1st part is failed!"
sync
# Lock
echo 1 > /sys/block/mmcblk1boot0/force_ro

# Unlock
echo 0 > /sys/block/mmcblk1boot1/force_ro
dd if=${UBOOT} of=/dev/mmcblk1boot1 bs=1k seek=1
cmd_check $? "${YELLOW}Flashing ${UBOOT} 2nd part is failed!"
sync
# Lock
echo 1 > /sys/block/mmcblk1boot1/force_ro

echo -e "${YELLOW}Setting U-boot into eMMC${NC}"
mmc bootpart enable 1 1 /dev/mmcblk1    # enable partition 1, enable BOOT_ACK bits
cmd_check $? "Setting bootpart is failed!"
sync
echo -e "${GREEN}Success! All done!${NC}"
echo -e "${GREEN}Set boot mode to eMMC and do reboot to take effect!${NC}"

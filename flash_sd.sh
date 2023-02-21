#!/bin/bash
# Run this script in Linux Host for preparing SD card for MYR iMX6ULL board

RED='\033[0;31m'
#BOLDRED='\033[1;4;31m'
BOLDRED='\033[1;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

IMG=./sd_sombrero.img
UBOOT=./u-boot-sd.imx
DEV=$1

help()
{
	echo -e "${YELLOW}INFO: $0 This script is intended to run on Linux Host PC ${NC}"
	echo -e "${YELLOW}Help: $0 <SD card device ID> ${NC}"
	echo -e "${YELLOW}Ex: $0 /dev/sdc ${NC}"
	echo -e "${BOLDRED}WARNING: Please make sure that HDD/SSD Device ID is not given as parameter (Ex: /dev/sda), it will erase the complete system ${NC}"
	exit 1
}

if [[ $1 == "--help" ]]; then
	help
fi

if [[ $1 == "-h" ]]; then
	help
fi


if [ "$#" -ne 1 ]; then
	echo -e "${RED}Argument is missing${NC}"
	help
fi


if (( $EUID != 0 )); then
	echo -e "${RED}Please run as root${NC}"
	exit
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

# Unmount the device
echo -e "${BOLDRED}WARNING: Please make sure that HDD/SDD Device ID is not given as parameter (Ex: /dev/sda), it will erase the complete system ${NC}"
echo -e "${YELLOW}This Tools is used to flash the Linux OS into SD using Linux Host. And not intended to run on i.MX6ULL.${NC}"
echo -e "${YELLOW} "${DEV}" Device ID given for SD/MMC card ${NC}"
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
umount ${DEV}*

# Flash the img into SD card
echo -e "${YELLOW}Flashing Linux OS into SD${NC}"
echo -e "${YELLOW}It would take some time to finish! Have some coffee! :)${NC}"
dd if=$IMG of=${DEV} bs=1M status=progress
cmd_check $? "Flashing IMG is failed!"
sync

# Flash the uboot into SD card's initial sector
echo -e "${YELLOW}Flashing U-boot into SD${NC}"
dd if=$UBOOT of=${DEV} bs=1k seek=1 status=progress
cmd_check $? "Flashing Uboot is failed!"
sync
echo -e "${GREEN}Success! All done!${NC}"
echo -e "${GREEN}Set boot mode to SD, insert SD card to board and apply Reset to take effect!${NC}"

#!/bin/bash
# Run this script in Linux Host for preparing images for eMMC of MYR iMX6ULL board

# Following files are must to proceed
KERNEL=./zImage
DTB=./mys-6ull-14x14-emmc.dtb
BOOT_SCR=./boot.scr
BOOT_BKP_SCR=./boot_bkp.scr
BOOT_SECONDARY_SCR=./boot_secondary.scr
BOOT_SECONDARY_BKP_SCR=./boot_secondary_bkp.scr
BOOT_SD_SCR=./boot_sd.scr
ROOTFS=./fsl-image-qt5-mys-6ull.ext4
RAMDISK=./ramdisk.ext4.gz.u-boot
EMMC_IMG=./emmc_sombrero.img
SD_IMG=./sd_sombrero.img
SD_ROOTFS=./core-image-minimal-mys-6ull.rootfs.tar.bz2
EMMC_TOOL=./flash_emmc.sh
EMMC_UBOOT=./u-boot-emmc.imx

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'


if (( $EUID != 0 )); then
	echo -e "${RED}Please run as root${NC}"
	exit
fi

if [ ! -f "$KERNEL" ]; then
	echo -e "${RED}$KERNEL is not found!.${NC}"
	exit -1
fi
if [ ! -f "$DTB" ]; then
	echo -e "${RED}$DTB is not found!.${NC}"
	exit -1
fi
if [ ! -f "$BOOT_SCR" ]; then
	echo -e "${RED}$BOOT_SCR is not found!.${NC}"
	exit -1
fi
if [ ! -f "$BOOT_BKP_SCR" ]; then
	echo -e "${RED}$BOOT_BKP_SCR is not found!.${NC}"
	exit -1
fi
if [ ! -f "$BOOT_SECONDARY_SCR" ]; then
	echo -e "${RED}$BOOT_SECONDARY_SCR is not found!.${NC}"
	exit -1
fi
if [ ! -f "$BOOT_SECONDARY_BKP_SCR" ]; then
	echo -e "${RED}$BOOT_SECONDARY_BKP_SCR is not found!.${NC}"
	exit -1
fi
if [ ! -f "$BOOT_SD_SCR" ]; then
	echo -e "${RED}$BOOT_SD_SCR is not found!.${NC}"
	exit -1
fi
if [ ! -f "$RAMDISK" ]; then
	echo -e "${RED}$RAMDISK is not found!.${NC}"
	exit -1
fi
if [ ! -f "$ROOTFS" ]; then
	echo -e "${RED}$ROOTFS is not found!.${NC}"
	exit -1
fi
if [ ! -f "$EMMC_IMG" ]; then
	echo -e "${RED}$EMMC_IMG is not found!.${NC}"
	exit -1
fi
if [ ! -f "$SD_IMG" ]; then
	echo -e "${RED}$SD_IMG is not found!.${NC}"
	exit -1
fi
if [ ! -f "$SD_ROOTFS" ]; then
	echo -e "${RED}$SD_ROOTFS is not found!.${NC}"
	exit -1
fi
if [ ! -f "$EMMC_TOOL" ]; then
	echo -e "${RED}$EMMC_TOOL is not found!.${NC}"
	exit -1
fi
if [ ! -f "$EMMC_UBOOT" ]; then
	echo -e "${RED}$EMMC_UBOOT is not found!.${NC}"
	exit -1
fi

cmd_check()
{
	if [ $1 -ne 0 ];then
		echo -e "${RED}$2${NC}"
		exit -1
	fi
}


###########################################################
################# Preparing eMMC image ####################
###########################################################


# Calculate CRC for the zImage & dtb and create bin
sudo umount ./tmp/tmp_mnt
sudo umount ./tmp/tmp_extfs
rm -rf tmp
mkdir tmp
echo -e "${YELLOW}Calculating CRC ${NC}"
python3 crc_calc_write.py -i ${KERNEL} -d ${DTB} -io ./tmp/i.bin -do ./tmp/d.bin
cmd_check $? "CRC calculation is failed!"

# Copy the files & prepare backup files
echo -e "${YELLOW}Preparing files ${NC}"
cd tmp
cp -rf i.bin i_bkp.bin
cp -rf d.bin d_bkp.bin
cp -rf ../${KERNEL} zImage_bkp
cp -rf ../${KERNEL} zImage
cp -rf ../${DTB} mys-6ull-14x14-emmc.dtb
cp -rf ../${DTB} mys-6ull-14x14-emmc-bkp.dtb

# Copy boot files into eMMC BOOT partition
rm -rf tmp_mnt
mkdir tmp_mnt
sudo mount -v -o offset=`expr 20480 \* 512` -t vfat ../${EMMC_IMG} ./tmp_mnt
cmd_check $? "eMMC BOOT part mount is failed!"
sudo rm -rf ./tmp_mnt/*
echo -e "${YELLOW}Coping files into eMMC BOOT partition${NC}"
cp -rf i*.bin d*.bin zImage* mys-6ull-14x14-emmc* ../${BOOT_SCR} ../${BOOT_BKP_SCR} ../${BOOT_SECONDARY_SCR} ../${BOOT_SECONDARY_BKP_SCR} ../${BOOT_SD_SCR} ../${RAMDISK} ./tmp_mnt
cmd_check $? "Copying image is failed!"
sync
sudo umount ./tmp_mnt

# Copy boot files into eMMC BOOT_BKP partition
sudo mount -v -o offset=`expr 245760 \* 512` -t vfat ../${EMMC_IMG} ./tmp_mnt
cmd_check $? "eMMC BOOT_BKP part mount is failed!"
sudo rm -rf ./tmp_mnt/*
echo -e "${YELLOW}Coping files into eMMC BOOT_BKP partition${NC}"
cp -rf i*.bin d*.bin zImage* mys-6ull-14x14-emmc* ../${BOOT_SCR} ../${BOOT_BKP_SCR} ../${BOOT_SECONDARY_SCR} ../${BOOT_SECONDARY_BKP_SCR} ../${BOOT_SD_SCR} ../${RAMDISK} ./tmp_mnt
cmd_check $? "Copying image is failed!"
sync
sudo umount ./tmp_mnt

# Mount ext4 rootfs
rm -rf tmp_extfs
mkdir tmp_extfs
sudo mount -v -t ext4 ../${ROOTFS} tmp_extfs
cmd_check $? "EXT4 img mount is failed!"

# Copy rootfs content into eMMC rootfs's partition
sudo mount -v -o offset=`expr 471040 \* 512` -t ext4 ../${EMMC_IMG} ./tmp_mnt
cmd_check $? "eMMC rootfs part mount is failed!"
sudo rm -rf ./tmp_mnt/*
echo -e "${YELLOW}Coping files into eMMC ROOTFS partition${NC}"
sudo cp -rf tmp_extfs/* ./tmp_mnt
cmd_check $? "Copying rootfs is failed!"
sync
sudo umount ./tmp_mnt
sudo umount ./tmp_extfs
sync

###########################################################
############## Preparing SD card image ####################
###########################################################

# Copy boot files into SD BOOT partition
sudo mount -v -o offset=`expr 20480 \* 512` -t vfat ../${SD_IMG} ./tmp_mnt
cmd_check $? "SD BOOT part mount is failed!"
sudo rm -rf ./tmp_mnt/*
echo -e "${YELLOW}Coping files into SD BOOT partition${NC}"
cp -rf i*.bin d*.bin zImage* mys-6ull-14x14-emmc* ../${BOOT_SCR} ../${BOOT_BKP_SCR} ../${BOOT_SECONDARY_SCR} ../${BOOT_SECONDARY_BKP_SCR} ../${BOOT_SD_SCR} ../${RAMDISK} ./tmp_mnt
cmd_check $? "Copying image is failed!"
sync
sudo umount ./tmp_mnt

# Copy boot files into SD BOOT_BKP partition
sudo mount -v -o offset=`expr 245760 \* 512` -t vfat ../${SD_IMG} ./tmp_mnt
cmd_check $? "SD BOOT_BKP part mount is failed!"
sudo rm -rf ./tmp_mnt/*
echo -e "${YELLOW}Coping files into SD BOOT_BKP partition${NC}"
cp -rf i*.bin d*.bin zImage* mys-6ull-14x14-emmc* ../${BOOT_SCR} ../${BOOT_BKP_SCR} ../${BOOT_SECONDARY_SCR} ../${BOOT_SECONDARY_BKP_SCR} ../${BOOT_SD_SCR} ../${RAMDISK} ./tmp_mnt
cmd_check $? "Copying image is failed!"
sync
sudo umount ./tmp_mnt

# Copy rootfs content into SD rootfs's partition
sudo mount -v -o offset=`expr 471040 \* 512` -t ext4 ../${SD_IMG} ./tmp_mnt
cmd_check $? "SD rootfs part mount is failed!"
sudo rm -rf ./tmp_mnt/*
echo -e "${YELLOW}Coping files into SD ROOTFS partition${NC}"
tar -jxf ../${SD_ROOTFS} -C ./tmp_mnt
cmd_check $? "Copying rootfs is failed!"
sync
# Copy eMMC image with flash tools into SD card image
echo -e "${YELLOW}Coping eMMC image and tools into SD ROOTFS partition${NC}"
mkdir ./tmp_mnt/home/root/emmc_flashing/
cp -rf ../${EMMC_TOOL} ../${EMMC_UBOOT} ../${EMMC_IMG} ./tmp_mnt/home/root/emmc_flashing/
cmd_check $? "Copying eMMC tools to rootfs is failed!"
sync
sudo umount ./tmp_mnt

cd ..
rm -rf tmp
sync
echo -e "${GREEN}All done!${NC}"

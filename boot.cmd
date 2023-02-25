setenv mmcdev 1
setenv mmcpart 1
setenv mmcpart_bkp 2
fatload mmc $mmcdev:$mmcpart $loadaddr zImage
fatsize mmc $mmcdev:$mmcpart zImage
crc32 $loadaddr $filesize 0x83100000
fatload mmc $mmcdev:$mmcpart 0x83100004 i.bin
if itest *0x83100000 == *0x83100004; then mw.l 0x83100008 0xff; else echo "$$$$$$$$$$$ zImage crc mismatch for eMMC part1 :( $$$$$$$$$$$";mw.l 0x83100008 0; fi

fatload mmc $mmcdev:$mmcpart $fdt_addr mys-6ull-14x14-emmc.dtb
fatsize mmc $mmcdev:$mmcpart mys-6ull-14x14-emmc.dtb
crc32 $fdt_addr $filesize 0x83100000
fatload mmc $mmcdev:$mmcpart 0x83100004 d.bin
if itest *0x83100000 == *0x83100004; then mw.l 0x8310000c 0xff; else echo "$$$$$$$$$$$ DTB crc mismatch for eMMC part1 :( $$$$$$$$$$$"; mw.l 0x8310000c 0; fi

setexpr final_chk *0x83100008 \& *0x8310000c

src_srsr=0x20D8008;setexpr src_srsr_val *$src_srsr \& 0x10;
if itest $src_srsr_val == 0;
#POR reset
then
	echo "";
else
#WDT reset
	if itest $final_chk == 0xff;
	then
		fatload mmc $mmcdev:$mmcpart 0x86800000 ramdisk.ext4.gz.u-boot
		setenv bootargs console=ttymxc0,115200n8 root=/dev/ram0 rw rootfstype=ext4
		echo "$$$$$$$$$$$ ramdisk booting to recover ext4 rootfs $$$$$$$$$$$"
		bootz $loadaddr 0x86800000 $fdt_addr
	else
		echo "$$$$$$$$$$$ crc mismatch for eMMC part1 during ramdisk boot(i.e rootfs corruption) thus manual recovery needed $$$$$$$$$$$";
	fi
fi

setenv mmcroot '/dev/mmcblk1p3 rootwait rw'
setenv console 'ttymxc0'
setenv baudrate '115200'
setenv bootargs console=${console},${baudrate} root=${mmcroot}
if itest $final_chk == 0xff; then echo "########### All success! eMMC part1 booting... ###########"; bootz $loadaddr - $fdt_addr; else echo "$$$$$$$$$$$ crc mismatch for eMMC part1 :( booting backup from eMMC part1 $$$$$$$$$$$"; fatload mmc $mmcdev:$mmcpart $loadaddr boot_bkp.scr; source $loadaddr;fi

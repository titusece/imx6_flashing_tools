setenv mmcdev 1
setenv mmcpart 1
setenv mmcpart_bkp 2
fatload mmc $mmcdev:$mmcpart $loadaddr zImage_bkp
fatsize mmc $mmcdev:$mmcpart zImage_bkp
crc32 $loadaddr $filesize 0x83100000
fatload mmc $mmcdev:$mmcpart 0x83100004 i_bkp.bin
if itest *0x83100000 == *0x83100004; then mw.l 0x83100008 0xff; else echo "$$$$$$$$$$$ zImage_bkp crc mismatch for eMMC part1 :( $$$$$$$$$$$";mw.l 0x83100008 0; fi

fatload mmc $mmcdev:$mmcpart $fdt_addr mys-6ull-14x14-emmc-bkp.dtb
fatsize mmc $mmcdev:$mmcpart mys-6ull-14x14-emmc-bkp.dtb
crc32 $fdt_addr $filesize 0x83100000
fatload mmc $mmcdev:$mmcpart 0x83100004 d_bkp.bin
if itest *0x83100000 == *0x83100004; then mw.l 0x8310000c 0xff; else echo "$$$$$$$$$$$ BKP DTB crc mismatch for eMMC part1 :( $$$$$$$$$$$"; mw.l 0x8310000c 0; fi

setexpr final_chk *0x83100008 \& *0x8310000c
setenv mmcroot '/dev/mmcblk1p3 rootwait rw'
setenv console 'ttymxc0'
setenv baudrate '115200'
setenv bootargs console=${console},${baudrate} boot=1 root=${mmcroot}
if itest $final_chk == 0xff; then echo "########### All success! eMMC part1 bkp image booting... ###########"; bootz $loadaddr - $fdt_addr; else echo "$$$$$$$$$$$ crc mismatch :( booting bkp image from eMMC part1 is failed too! resetting.... $$$$$$$$$$$"; reset;fi

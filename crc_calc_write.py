import os
import zlib
import argparse
import binascii


def forLoopCrc(fpath):
    """With for loop and buffer."""
    crc = 0
    with open(fpath, 'rb', 65536) as ins:
        for x in range(int((os.stat(fpath).st_size / 65536)) + 1):
            crc = zlib.crc32(ins.read(65536), crc)
    #print(hex(crc))
    # Do convert for uboot load
    crc = (0xff000000 & crc) >> 24 | (0x00ff0000 & crc) >> 8 | (0xff & crc) << 24 | (0xff00 & crc) << 8
    return '%08X' % (crc & 0xFFFFFFFF)
#    return crc

parser = argparse.ArgumentParser()
parser.add_argument('-i', required=True, help='zImage file')
parser.add_argument('-io', required=True, help='zImage crc file')
parser.add_argument('-d', required=True, help='dtb file')
parser.add_argument('-do', required=True, help='dtb crc file')
args = parser.parse_args()

image_crc = forLoopCrc(args.i)
dtb_crc = forLoopCrc(args.d)


#print(hex(image_crc))
#print(hex(dtb_crc))


with open(args.io, 'wb') as f:
    f.write(binascii.unhexlify(''.join(image_crc.split())))
with open(args.do, 'wb') as f:
    f.write(binascii.unhexlify(''.join(dtb_crc.split())))

#python3 test.py -i /var/lib/tftpboot/zImage -d /var/lib/tftpboot/mys-6ull-14x14-emmc.dtb

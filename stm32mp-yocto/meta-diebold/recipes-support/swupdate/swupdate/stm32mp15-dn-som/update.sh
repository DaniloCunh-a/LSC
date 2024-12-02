#/bin/bash
# install APP rootfs
set -e
# mount /dev/sda1 /media/
sudo mount LABEL=DN_UPDATE /media/DN_UPDATE
echo "mount usb drive"
/usr/bin/swupdate -i /media/DN_UPDATE/update-image.swu -e "stable,alt"

rootfs=`swupdate -g`

if [ $rootfs == '/dev/mmcblk0p9' ];then
    fw_setenv boot_now 10
else
	if [ $rootfs == '/dev/mmcblk1p7' ];then
        fw_setenv boot_now 8
    fi
fi



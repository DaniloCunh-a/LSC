SUMMARY = "Diebold Image for Products"
DESCRIPTION = "This image contain all basic packages for installation of products Diebold"

inherit core-image


IMAGE_INSTALL = "packagegroup-core-boot \
                 ncurses \
                 usbutils \
                 run-postinsts \
                 ldd \
                 libubootenv-bin \
                 otg-serial \
                 memtester \
                 dtc \
                 weston \
                 libsdl2 \
                 spidev-test \
                 mmc-utils \
                 swupdate \
                 xserver-xorg \
                 xinit \
                 weston-init \
                 xterm \
                 ${CORE_IMAGE_EXTRA_INSTALL}"

#IMAGE_ROOTFS_MAXSIZE ?= "2004800"
IMAGE_OVERHEAD_FACTOR?="1.0"
#1004800
#100MB in KB base 2
IMAGE_ROOTFS_SIZE ?= "102400"

#IMAGE_ROOTFS_EXTRA_SPACE:append = "${@bb.utils.contains("DISTRO_FEATURES", "systemd", " + 4096", "", d)}"


IMAGE_LINGUAS = " "

LICENSE = "MIT"

inherit core-image features_check


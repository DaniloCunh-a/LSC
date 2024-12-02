DESCRIPTION = "Example image demonstrating how to build SWUpdate compound image"

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

inherit swupdate

SRC_URI = "\
    file://emmcsetup.lua \
    file://sw-description \
"

# images to build before building swupdate image
IMAGE_DEPENDS = "diebold-image-tpd diebold-image-base "

# images and files that will be included in the .swu image
SWUPDATE_IMAGES = "diebold-image-base diebold-image-tpd"

SWUPDATE_IMAGES_FSTYPES[diebold-image-base] = ".ext4"
SWUPDATE_IMAGES_FSTYPES[diebold-image-tpd] = ".ext4"

COMPATIBLE = "stm32mp15-dn-som"

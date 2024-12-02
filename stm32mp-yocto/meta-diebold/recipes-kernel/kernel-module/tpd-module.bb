SUMMARY = "Kernel Modules"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

inherit module

SRC_URI += "file://Makefile"
SRC_URI += "file://dbdhiddevice.c"
SRC_URI += "file://f_hid.c"
SRC_URI += "file://g_tpd.h"
SRC_URI += "file://emulator_uuid.c"

S = "${WORKDIR}"

#PROVIDES += "tpd-module"
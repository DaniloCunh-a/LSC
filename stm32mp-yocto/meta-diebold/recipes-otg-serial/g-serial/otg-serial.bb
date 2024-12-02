SUMARY = "Recipe for SERIAL - OTG"
LICENSE = "MIT"

SRC_URI += "file://gadgetfs_serial.sh"



LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"


S = "${WORKDIR}"


inherit update-rc.d

INITSCRIPT_NAME = "gadgetfs_serial.sh"
INITSCRIPT_PARAMS = "start 99 2 3 4 5 ."

do_install() {
    
    install -d ${D}${sysconfdir}/init.d
    install -m 0755 ${S}/gadgetfs_serial.sh ${D}${sysconfdir}/init.d/gadgetfs_serial.sh 
    
}

INSANE_SKIP:${PN} = "${ERROR_QA} ${WARN_QA}"



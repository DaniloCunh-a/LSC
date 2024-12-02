FILESEXTRAPATHS:append := "${THISDIR}/${PN}:"

PACKAGECONFIG_CONFARGS = ""

SRC_URI += " \
    file://09-swupdate-args \
    file://swupdate.cfg \
    file://update.sh \
    file://hwrevision \
    "

DEPENDS += " libarchive zstd"

do_install:append() {
    install -m 0644 ${WORKDIR}/09-swupdate-args ${D}${libdir}/swupdate/conf.d/
    sed -i "s#@MACHINE@#${MACHINE}#g" ${D}${libdir}/swupdate/conf.d/09-swupdate-args

    install -d ${D}${sysconfdir}
    install -m 644 ${WORKDIR}/swupdate.cfg ${D}${sysconfdir}

    install -d ${D}${sysconfdir}
    install -m 755 ${WORKDIR}/update.sh ${D}${sysconfdir}

    install -d ${D}${sysconfdir}
    install -m 755 ${WORKDIR}/hwrevision ${D}${sysconfdir}
}

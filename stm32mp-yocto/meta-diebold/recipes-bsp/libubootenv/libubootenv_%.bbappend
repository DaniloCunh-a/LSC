FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append:class-target = " \
    file://fw_env.config \
    file://u-boot-initial-env \
    "

do_install:append:class-target() {
	install -d ${D}${sysconfdir}
	install -m 644 ${WORKDIR}/fw_env.config ${D}${sysconfdir}
	install -m 644 ${WORKDIR}/u-boot-initial-env ${D}${sysconfdir}
}

FILES:${PN}:append:class-target = " ${sysconfdir}"

DEPENDS:append:stm32mpcommon = " ${@bb.utils.contains('DISTRO_FEATURES', 'systemd', '', 'update-rc.d-native', d)}"

do_install:append:stm32mpcommon () {
    #update-rc.d -r ${D} ifplugd.sh stop 99 2 3 4 5 .
    rm -f ${D}/etc/rc*.d/*ifplugd.sh
}
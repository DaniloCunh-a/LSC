FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"


#SRC_URI += "file://0001-latest-version-dn-som.patch"
SRC_URI += "file://0002-tpd_patch.patch"
SRC_URI += "file://0003-atualizacao-151-dtsi-spi1-ativado.patch"
#SRC_URI += "file://0004-atualizacao-dts-spi1-ativado.patch"
SRC_URI += "file://0005-atualizacao-dts-dsi.patch"

KERNEL_CONFIG_FRAGMENTS:append = " ${WORKDIR}/fragments/5.15/tpd-fragment.config"
SRC_URI:append = " file://5.15/tpd-fragment.config;subdir=fragments "
KERNEL_FEATURES:append = " drm otm8009a mipi_dsi"
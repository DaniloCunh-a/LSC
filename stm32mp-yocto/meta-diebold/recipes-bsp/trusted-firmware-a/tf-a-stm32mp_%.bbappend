FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://0001-create-DTS-file-for-dn-lse-System-On-Module-SOM.patch"
SRC_URI += "file://0002-edit-git-ignore.patch"
SRC_URI += "file://0003-adi-o-para-bsp-dn-lse-som.patch"
SRC_URI += "file://0004-fixing-up-of-all-bugs-around-of-the-som.patch"
SRC_URI += "file://0005-fixing-up-of-bugs.patch"
SRC_URI += "file://0006-add-files-of-model-single-core-stm32mp151c-from-DN-L.patch"
SRC_URI += "file://0007-Config-para-builds.patch"
SRC_URI += "file://0008-update-gitignore.patch"
SRC_URI += "file://0009-USE-UART-TPD.patch"

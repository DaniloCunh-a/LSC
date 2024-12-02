# /bin/bash
set -e

BUILD_DIR="build_base"

echo "Start build env"
source poky/oe-init-build-env $BUILD_DIR

cd ..

echo "Set Local Configuration"
cp dev_utils/local-base local.conf
cp local.conf $BUILD_DIR/conf/local.conf
rm local.conf

# echo "Copy Java dependencies"
# mkdir $BUILD_DIR/downloads
# cp dev_utils/java-tpd/ejdk-8u131-linux-armv6-vfp-hflt.tar.gz $BUILD_DIR/downloads
# cp dev_utils/java-tpd/jdk-8u131-linux-x64.tar.gz $BUILD_DIR/downloads
# cp dev_utils/java-tpd/jre-8u131-linux-x64.tar.gz $BUILD_DIR/downloads

echo "Enable Diebold Layers"

cd $BUILD_DIR

bitbake-layers add-layer ../meta-openembedded/meta-oe
bitbake-layers add-layer ../meta-openembedded/meta-python
bitbake-layers add-layer ../meta-st-stm32mp
# bitbake-layers add-layer ../meta-qt5
bitbake-layers add-layer ../meta-swupdate
bitbake-layers add-layer ../meta-diebold
# bitbake-layers add-layer ../meta-oracle-java

echo "Setup Done"

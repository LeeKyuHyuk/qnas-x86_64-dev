#!/bin/bash
#
# QNAS system build script
# Optional parameteres below:

set -o nounset
set -o errexit

# End of optional parameters
function step() {
  echo -e "\e[7m\e[1m>>> $1\e[0m"
}

function success() {
  echo -e "\e[1m\e[32m$1\e[0m"
}

function error() {
  echo -e "\e[1m\e[31m$1\e[0m"
}

function extract() {
  case $1 in
    *.tgz) tar -zxf $1 -C $2 ;;
    *.tar.gz) tar -zxf $1 -C $2 ;;
    *.tar.bz2) tar -jxf $1 -C $2 ;;
    *.tar.xz) tar -Jxf $1 -C $2 ;;
  esac
}

function check_environment_variable {
  if ! [[ -d $SOURCES_DIR ]] ; then
    error "Please download tarball files!"
    error "Run 'make download'."
    exit 1
  fi

  if ! [[ -d $TOOLS_DIR ]] ; then
    error "Can't find tools directory!"
    error "Run 'make toolchain'."
  fi
}

function timer {
  if [[ $# -eq 0 ]]; then
    echo $(date '+%s')
  else
    local stime=$1
    etime=$(date '+%s')
    if [[ -z "$stime" ]]; then stime=$etime; fi
    dt=$((etime - stime))
    ds=$((dt % 60))
    dm=$(((dt / 60) % 60))
    dh=$((dt / 3600))
    printf '%02d:%02d:%02d' $dh $dm $ds
  fi
}

check_environment_variable
total_build_time=$(timer)

rm -rf $BUILD_DIR $IMAGES_DIR/{uefi,boot.vfat,sdcard.img,$CONFIG_ISO_FILENAME}
mkdir -pv $BUILD_DIR

step "Copy QNAS system image"
mkdir -pv $IMAGES_DIR/uefi/qnas/qnas-install
echo "TEST File!" > $IMAGES_DIR/uefi/qnas/qnas-install/README

step "[1/1] Create QNAS UEFI Image"
mkdir -pv $IMAGES_DIR/uefi/EFI/BOOT
cp $TOOLS_DIR/prebuilts/efi/bootx64.efi $IMAGES_DIR/uefi/EFI/BOOT
cat > $IMAGES_DIR/uefi/EFI/BOOT/grub.cfg << EOF
set default="0"
set timeout="5"

menuentry "QNAS 1.0.0 Absinthe (x86_64)" {
	linux /bzImage
}
EOF
cat > $IMAGES_DIR/uefi/startup.nsh << EOF
bootx64.efi
EOF
cp -v $IMAGES_DIR/bzImage $IMAGES_DIR/uefi/bzImage
$TOOLS_DIR/usr/bin/genimage \
  --rootpath "$LIVE_ROOTFS_DIR" \
  --tmppath "$BUILD_DIR/genimage.tmp" \
  --inputpath "$IMAGES_DIR/uefi" \
  --outputpath "$IMAGES_DIR" \
  --config "$SUPPORT_DIR/genimage/qnas-uefi.cfg"

mv $IMAGES_DIR/sdcard.img $IMAGES_DIR/$CONFIG_ISO_FILENAME

success "\nTotal QNAS install image generate time: $(timer $total_build_time)\n"

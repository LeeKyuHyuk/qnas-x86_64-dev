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

function check_tarballs {
  LIST_OF_TARBALLS="
  syslinux-6.03.tar.xz
  systemd-boot_10-Dec-2017.tar.xz
  "

  for tarball in $LIST_OF_TARBALLS ; do
    if ! [[ -f $SOURCES_DIR/$tarball ]] ; then
      error "Can't find '$tarball'!"
      exit 1
    fi
  done
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
check_tarballs
total_build_time=$(timer)

rm -rf $BUILD_DIR $IMAGES_DIR/{rootfs.gz,isoimage}
mkdir -pv $BUILD_DIR $IMAGES_DIR/isoimage/boot/syslinux

step "[1/4] Copy Kernel Image"
cp -v $IMAGES_DIR/bzImage $IMAGES_DIR/isoimage/boot/kernel.xz

step "[2/4] Create Ramdisk Image"
( cd $ROOTFS_DIR && find . | cpio -R root:root -H newc -o | gzip > $IMAGES_DIR/rootfs.gz )
mv -v $IMAGES_DIR/rootfs.gz $IMAGES_DIR/isoimage/boot/rootfs.xz

step "[3/4] Create UEFI Image"
extract $SOURCES_DIR/systemd-boot_10-Dec-2017.tar.xz $BUILD_DIR
mkdir -pv $IMAGES_DIR/uefi/EFI/BOOT
cp -v $BUILD_DIR/systemd-boot_10-Dec-2017/uefi_root/EFI/BOOT/BOOTx64.EFI $IMAGES_DIR/uefi/EFI/BOOT
mkdir -pv $IMAGES_DIR/uefi/loader/entries
cat > $IMAGES_DIR/uefi/loader/entries/qnas-x86_64.conf << EOF
title QNAS installer
version x86_64
efi /qnas/x86_64/kernel.xz
options initrd=/qnas/x86_64/rootfs.xz
EOF
cat > $IMAGES_DIR/uefi/loader/loader.conf << EOF
default qnas-x86_64
timeout 5
editor 1
EOF
mkdir -pv $IMAGES_DIR/uefi/qnas/x86_64
cp -v $IMAGES_DIR/isoimage/boot/{kernel.xz,rootfs.xz} $IMAGES_DIR/uefi/qnas/x86_64/
$TOOLS_DIR/usr/bin/genimage \
  --rootpath "$ROOTFS_DIR" \
  --tmppath "$BUILD_DIR/genimage.tmp" \
  --inputpath "$IMAGES_DIR/uefi" \
  --outputpath "$IMAGES_DIR" \
  --config "$SUPPORT_DIR/genimage/qnas-uefi.cfg"
mv -v $IMAGES_DIR/uefi.img $IMAGES_DIR/isoimage/boot/uefi.img

step "[4/4] Create ISO Image"
mkdir -p $IMAGES_DIR/isoimage/EFI/BOOT
cat > $IMAGES_DIR/isoimage/EFI/BOOT/startup.nsh << EOF
echo -off
echo QNAS installer is starting.
\boot\kernel.xz initrd=\boot\rootfs.xz
EOF
extract $SOURCES_DIR/syslinux-6.03.tar.xz $BUILD_DIR
install -Dv -m 0644 $BUILD_DIR/syslinux-6.03/bios/core/isolinux.bin $IMAGES_DIR/isoimage/boot/syslinux/isolinux.bin
install -Dv -m 0755 $BUILD_DIR/syslinux-6.03/bios/com32/elflink/ldlinux/ldlinux.c32 $IMAGES_DIR/isoimage/boot/syslinux/ldlinux.c32
install -Dv -m 0644 $SUPPORT_DIR/syslinux/syslinux.cfg $IMAGES_DIR/isoimage/boot/syslinux/syslinux.cfg
( cd $IMAGES_DIR/isoimage && \
xorriso -as mkisofs \
-isohybrid-mbr $BUILD_DIR/syslinux-6.03/bios/mbr/isohdpfx.bin \
-c boot/syslinux/boot.cat \
-b boot/syslinux/isolinux.bin \
-no-emul-boot \
-boot-load-size 4 \
-boot-info-table \
-eltorito-alt-boot \
-e boot/uefi.img \
-no-emul-boot \
-isohybrid-gpt-basdat \
-o $IMAGES_DIR/$CONFIG_ISO_FILENAME . )

success "\nTotal QNAS install image generate time: $(timer $total_build_time)\n"

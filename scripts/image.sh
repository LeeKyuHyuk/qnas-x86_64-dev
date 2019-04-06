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
mkdir -pv $IMAGES_DIR/uefi/qnas/qnas-install/file/booting
echo '#!/bin/sh' > $BUILD_DIR/_fakeroot.fs
echo "set -e" >> $BUILD_DIR/_fakeroot.fs
echo "chown -h -R 0:0 $ROOTFS_DIR" >> $BUILD_DIR/_fakeroot.fs
cat > $BUILD_DIR/_device_table.txt << EOF
# This device table is used to assign proper ownership and permissions
# on various files. It doesn't create any device file, as it is used
# in both static device configurations (where /dev/ is static) and in
# dynamic configurations (where devtmpfs, mdev or udev are used).
#
# <name>				<type>	<mode>	<uid>	<gid>	<major>	<minor>	<start>	<inc>	<count>
/dev					d	755	0	0	-	-	-	-	-
/dev/console	c 666 0 0 5 1 - - -
/dev/null c 666 0 0 1 3 0 0 -
/tmp					d	1777	0	0	-	-	-	-	-
/etc					d	755	0	0	-	-	-	-	-
/root					d	700	0	0	-	-	-	-	-
/var/www				d	755	33	33	-	-	-	-	-
/etc/shadow				f	600	0	0	-	-	-	-	-
/etc/passwd				f	644	0	0	-	-	-	-	-
/etc/network/if-up.d			d	755	0	0	-	-	-	-	-
/etc/network/if-pre-up.d		d	755	0	0	-	-	-	-	-
/etc/network/if-down.d			d	755	0	0	-	-	-	-	-
/etc/network/if-post-down.d		d	755	0	0	-	-	-	-	-
EOF
if [ -d $ROOTFS_DIR/var/lib/sshd ] ; then
  echo "/var/lib/sshd	d	700	0	2	-	-	-	-	-" >> $BUILD_DIR/_device_table.txt
fi
if [ -d $ROOTFS_DIR/home/ftp ] ; then
  echo "/home/ftp	d	755	45	45	-	-	-	-	-" >> $BUILD_DIR/_device_table.txt
fi
echo "$TOOLS_DIR/bin/makedevs -d $BUILD_DIR/_device_table.txt $ROOTFS_DIR" >> $BUILD_DIR/_fakeroot.fs
echo "$TOOLS_DIR/sbin/mkfs.ext2 -d $ROOTFS_DIR $IMAGES_DIR/uefi/qnas/qnas-install/file/rootfs.ext2 200M" >> $BUILD_DIR/_fakeroot.fs
chmod a+x $BUILD_DIR/_fakeroot.fs
$TOOLS_DIR/usr/bin/fakeroot -- $BUILD_DIR/_fakeroot.fs
cat > $IMAGES_DIR/uefi/qnas/qnas-install/file/booting/grub.cfg << EOF
set default="0"
set timeout="5"

menuentry "QNAS 1.0.0 Absinthe (x86_64)" {
	linux /bzImage root=/dev/sda2 ro
}
EOF
cat > $IMAGES_DIR/uefi/qnas/qnas-install/file/booting/startup.nsh << EOF
bootx64.efi
EOF
cp $TOOLS_DIR/prebuilts/efi/bootx64.efi $IMAGES_DIR/uefi/qnas/qnas-install/file/booting/bootx64.efi
cp -v $IMAGES_DIR/bzImage $IMAGES_DIR/uefi/qnas/qnas-install/file/booting/bzImage
echo "TEST File!" > $IMAGES_DIR/uefi/qnas/qnas-install/README

step "[1/1] Create QNAS UEFI Image"
mkdir -pv $IMAGES_DIR/uefi/EFI/BOOT
cp $TOOLS_DIR/prebuilts/efi/bootx64.efi $IMAGES_DIR/uefi/EFI/BOOT
cat > $IMAGES_DIR/uefi/EFI/BOOT/grub.cfg << EOF
set default="0"
set timeout="5"

menuentry "QNAS 1.0.0 Absinthe (x86_64)" {
	linux /bzImage-live
}
EOF
cat > $IMAGES_DIR/uefi/startup.nsh << EOF
bootx64.efi
EOF
cp -v $IMAGES_DIR/bzImage-live $IMAGES_DIR/uefi/bzImage-live
$TOOLS_DIR/usr/bin/genimage \
  --rootpath "$LIVE_ROOTFS_DIR" \
  --tmppath "$BUILD_DIR/genimage.tmp" \
  --inputpath "$IMAGES_DIR/uefi" \
  --outputpath "$IMAGES_DIR" \
  --config "$SUPPORT_DIR/genimage/qnas-uefi.cfg"

mv $IMAGES_DIR/sdcard.img $IMAGES_DIR/$CONFIG_ISO_FILENAME

success "\nTotal QNAS install image generate time: $(timer $total_build_time)\n"

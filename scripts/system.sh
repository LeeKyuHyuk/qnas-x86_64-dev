#!/bin/bash
#
# QNAS system build script
# Optional parameteres below:

set -o nounset
set -o errexit

CONFIG_PKG_VERSION="QNAS x86_64 2019.02"
CONFIG_BUG_URL="https://github.com/LeeKyuHyuk/qnas/issues"

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
  busybox-1.30.1.tar.bz2
  "

  for tarball in $LIST_OF_TARBALLS ; do
    if ! [[ -f $SOURCES_DIR/$tarball ]] ; then
      error "Can't find '$tarball'!"
      exit 1
    fi
  done
}

function do_strip {
  set +o errexit
  if [[ $CONFIG_STRIP_AND_DELETE_DOCS = 1 ]] ; then
    $CONFIG_TARGET-strip --strip-debug $ROOTFS_DIR/lib/*
    $CONFIG_TARGET-strip --strip-unneeded $ROOTFS_DIR/{,s}bin/*
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
check_tarballs
total_build_time=$(timer)

export CC="$TOOLS_DIR/bin/$CONFIG_TARGET-gcc --sysroot=$ROOTFS_DIR"
export CXX="$TOOLS_DIR/bin/$CONFIG_TARGET-g++ --sysroot=$ROOTFS_DIR"
export AR="$TOOLS_DIR/bin/$CONFIG_TARGET-ar"
export AS="$TOOLS_DIR/bin/$CONFIG_TARGET-as"
export LD="$TOOLS_DIR/bin/$CONFIG_TARGET-ld --sysroot=$ROOTFS_DIR"
export RANLIB="$TOOLS_DIR/bin/$CONFIG_TARGET-ranlib"
export READELF="$TOOLS_DIR/bin/$CONFIG_TARGET-readelf"
export STRIP="$TOOLS_DIR/bin/$CONFIG_TARGET-strip"

export CONFIG_HOST=`echo ${MACHTYPE} | sed -e 's/-[^-]*/-cross/'`

rm -rf $BUILD_DIR $ROOTFS_DIR
mkdir -pv $BUILD_DIR $ROOTFS_DIR


step "[1/2] Create root file system directory."
mkdir -pv $ROOTFS_DIR/{boot,bin,dev,etc,lib,media,mnt,opt,proc,root,run,sbin,sys,tmp,usr}
mkdir -pv $ROOTFS_DIR/dev/{pts,shm}
ln -svf /tmp/log $ROOTFS_DIR/dev/log
mkdir -pv $ROOTFS_DIR/etc/{network,profile.d}
cp -v $SUPPORT_DIR/skeleton/etc/{group,hosts,passwd,profile,protocols,services,shadow} $ROOTFS_DIR/etc/
# sed -i -e s,^root:[^:]*:,root:"`$TOOLS_DIR/bin/mkpasswd -m "sha-512" "$CONFIG_ROOT_PASSWD"`":, $ROOTFS_DIR/etc/shadow
mkdir -pv $ROOTFS_DIR/etc/network/{if-down.d,if-post-down.d,if-pre-up.d,if-up.d}
cp -v $SUPPORT_DIR/skeleton/etc/profile.d/umask.sh $ROOTFS_DIR/etc/profile.d/umask.sh
ln -svf /proc/self/mounts $ROOTFS_DIR/etc/mtab
ln -svf /tmp/resolv.conf $ROOTFS_DIR/etc/resolv.conf
mkdir -pv $ROOTFS_DIR/usr/{bin,lib,sbin}
mkdir -pv $ROOTFS_DIR/var/lib
ln -svf /tmp $ROOTFS_DIR/var/cache
ln -svf /tmp $ROOTFS_DIR/var/lock
ln -svf /tmp $ROOTFS_DIR/var/log
ln -svf /tmp $ROOTFS_DIR/var/run
ln -svf /tmp $ROOTFS_DIR/var/spool
ln -svf /tmp $ROOTFS_DIR/var/tmp
ln -svf /tmp $ROOTFS_DIR/var/lib/misc
if [ "$CONFIG_LINUX_ARCH" = "i386" ] ; then \
    ln -snvf lib $ROOTFS_DIR/lib32 ; \
    ln -snvf lib $ROOTFS_DIR/usr/lib32 ; \
  fi;
if [ "$CONFIG_LINUX_ARCH" = "x86_64" ] ; then \
    ln -snvf lib $ROOTFS_DIR/lib64 ; \
    ln -snvf lib $ROOTFS_DIR/usr/lib64 ; \
  fi;

step "[2/2] Busybox 1.30.1"
extract $SOURCES_DIR/busybox-1.30.1.tar.bz2 $BUILD_DIR
make -j$PARALLEL_JOBS distclean -C $BUILD_DIR/busybox-1.30.1
make -j$PARALLEL_JOBS ARCH="$CONFIG_LINUX_ARCH" defconfig -C $BUILD_DIR/busybox-1.30.1
sed -i "s/.*CONFIG_STATIC.*/CONFIG_STATIC=y/" $BUILD_DIR/busybox-1.30.1/.config
make -j$PARALLEL_JOBS ARCH="$CONFIG_LINUX_ARCH" CROSS_COMPILE="$TOOLS_DIR/bin/$CONFIG_TARGET-" -C $BUILD_DIR/busybox-1.30.1
make -j$PARALLEL_JOBS ARCH="$CONFIG_LINUX_ARCH" CROSS_COMPILE="$TOOLS_DIR/bin/$CONFIG_TARGET-" CONFIG_PREFIX="$ROOTFS_DIR" install -C $BUILD_DIR/busybox-1.30.1
if grep -q "CONFIG_UDHCPC=y" $BUILD_DIR/busybox-1.30.1/.config; then
  install -m 0755 -Dv $SUPPORT_DIR/skeleton/usr/share/udhcpc/default.script $ROOTFS_DIR/usr/share/udhcpc/default.script
  install -m 0755 -dv $ROOTFS_DIR/usr/share/udhcpc/default.script.d
fi
if grep -q "CONFIG_SYSLOGD=y" $BUILD_DIR/busybox-1.30.1/.config; then
  install -m 0755 -Dv $SUPPORT_DIR/skeleton/etc/init.d/S01logging $ROOTFS_DIR/etc/init.d/S01logging
else
  rm -fv $ROOTFS_DIR/etc/init.d/S01logging
fi
if grep -q "CONFIG_FEATURE_TELNETD_STANDALONE=y" $BUILD_DIR/busybox-1.30.1/.config; then
  install -m 0755 -Dv $SUPPORT_DIR/skeleton/etc/init.d/S50telnet $ROOTFS_DIR/etc/init.d/S50telnet
fi
install -Dv -m 0644 $SUPPORT_DIR/skeleton/etc/inittab $ROOTFS_DIR/etc/inittab
install -m 0755 -Dv $SUPPORT_DIR/skeleton/etc/init.d/rcK $ROOTFS_DIR/etc/init.d/rcK
install -m 0755 -Dv $SUPPORT_DIR/skeleton/etc/init.d/rcS $ROOTFS_DIR/etc/init.d/rcS
install -m 0755 -Dv $SUPPORT_DIR/skeleton/etc/init.d/S20urandom $ROOTFS_DIR/etc/init.d/S20urandom
install -m 0755 -Dv $SUPPORT_DIR/skeleton/etc/init.d/S40network $ROOTFS_DIR/etc/init.d/S40network
install -m 0755 -Dv $SUPPORT_DIR/skeleton/etc/network/if-pre-up.d/wait_iface $ROOTFS_DIR/etc/network/if-pre-up.d/wait_iface
install -m 0755 -Dv $SUPPORT_DIR/skeleton/etc/network/nfs_check $ROOTFS_DIR/etc/network/nfs_check
cp -v $SUPPORT_DIR/skeleton/etc/network/interfaces $ROOTFS_DIR/etc/network/interfaces
echo "$CONFIG_HOSTNAME" > $ROOTFS_DIR/etc/hostname
echo "127.0.1.1	$CONFIG_HOSTNAME" >> $ROOTFS_DIR/etc/hosts
echo "Welcome to QNAS" > $ROOTFS_DIR/etc/issue
cp -v $BUILD_DIR/busybox-1.30.1/examples/depmod.pl $TOOLS_DIR/bin
rm -rf $BUILD_DIR/busybox-1.30.1

mkdir -pv $ROOTFS_DIR/{dev,etc,proc,root,src,sys,tmp}
chmod -v 1777 $ROOTFS_DIR/tmp

cat > $ROOTFS_DIR/etc/bootscript.sh << "EOF"
#!/bin/sh
echo -e "[QNAS] Welcome to \\e[1mQNAS \\e[32mInstall \\e[31mDisk\\e[0m!"
dmesg -n 1

echo "[QNAS] Mount /dev /proc /sys"
mount -t devtmpfs none /dev
mount -t proc none /proc
mount -t sysfs none /sys

printf "Starting network: "
/sbin/ifup -a &> /dev/null
[ $? = 0 ] && echo "OK" || echo "FAIL"

echo "[QNAS] Load QNAS install files."
echo "[QANS] Searching available devices for overlay content."
for DEVICE in /dev/* ; do
  DEV=$(echo "${DEVICE##*/}")
  SYSDEV=$(echo "/sys/class/block/$DEV")
  case $DEV in
    *loop*) continue ;;
  esac
  if [ ! -d "$SYSDEV" ] ; then
    continue
  fi
  mkdir -p /tmp/mnt/device
  DEVICE_MNT=/tmp/mnt/device
  mount $DEVICE $DEVICE_MNT 2>/dev/null
  if [ -d $DEVICE_MNT/qnas/qnas-install ] ; then
    echo -e "[QANS] Device \\e[31m$DEVICE\\e[0m is mounted in read only mode."
    rm -rf /qnas-install
    ln -sf $DEVICE_MNT/qnas/qnas-install /
    break
  fi
done

EOF
chmod +x $ROOTFS_DIR/etc/bootscript.sh

cat > $ROOTFS_DIR/etc/inittab << "EOF"
::sysinit:/etc/bootscript.sh
::restart:/sbin/init
::ctrlaltdel:/sbin/reboot
::once:cat /etc/welcome.txt
::respawn:/bin/cttyhack /bin/sh
tty2::once:cat /etc/welcome.txt
tty2::respawn:/bin/sh
tty3::once:cat /etc/welcome.txt
tty3::respawn:/bin/sh
tty4::once:cat /etc/welcome.txt
tty4::respawn:/bin/sh
EOF

cat > $ROOTFS_DIR/etc/rc.dhcp << "EOF"
ip addr add \$ip/\$mask dev \$interface

if [ "\$router" ]; then
  ip route add default via \$router dev \$interface
fi
EOF
chmod +x $ROOTFS_DIR/etc/rc.dhcp

cat > $ROOTFS_DIR/etc/welcome.txt << "EOF"
##############################
#   QNAS Install Live Disk   #
##############################
EOF

cat > $ROOTFS_DIR/init << "EOF"
#!/bin/sh
exec /sbin/init
EOF
chmod +x $ROOTFS_DIR/init
rm -fv $ROOTFS_DIR/linuxrc

success "\nTotal system build time: $(timer $total_build_time)\n"

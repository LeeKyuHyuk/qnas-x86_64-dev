#!/bin/bash
#
# Linux From Scratch Build Script 20190327-systemd v1.0
#
# Optional parameteres below:

# Number of parallel make jobs.
PARALLEL_JOBS=$(cat /proc/cpuinfo | grep cores | wc -l)
# Strip binaries and delete manpages to save space at the end of chapter 5?
STRIP_AND_DELETE_DOCS=1
CONFIG_HOSTNAME=qnas

# End of optional parameters
umask 022
set +h
set -o nounset
set -o errexit
export LC_ALL=POSIX
export CONFIG_TARGET=x86_64-qnas-linux-gnu
export LFS_TGT=$(uname -m)-lfs-linux-gnu
export LFS_DIR=$(cd "$(dirname "$0")" && pwd)
export SOURCES_DIR=$LFS_DIR/sources
export PACKAGES_DIR=$LFS_DIR/packages
export OUTPUT_DIR=$LFS_DIR/out
export ROOTFS_DIR=$OUTPUT_DIR/rootfs
export BUILD_DIR=$OUTPUT_DIR/build
export TOOLS_DIR=$OUTPUT_DIR/tools
export PATH="$TOOLS_DIR/bin:$TOOLS_DIR/sbin:$PATH"

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

function prebuild_sanity_check {
    if ! [[ -d $SOURCES_DIR ]] ; then
        echo "Can't find your sources directory!"
        exit 1
    fi
}

function check_tarballs {
LIST_OF_TARBALLS="
"

for tarball in $LIST_OF_TARBALLS ; do
    if ! [[ -f $SOURCES_DIR/$tarball ]] ; then
        echo "Can't find $tarball!"
        exit 1
    fi
done
}

function do_strip {
    set +o errexit
    if [[ $STRIP_AND_DELETE_DOCS = 1 ]] ; then
        strip --strip-debug /tools/lib/*
        /usr/bin/strip --strip-unneeded /tools/{,s}bin/*
        rm -rf /tools/{,share}/{info,man,doc}
        find /tools/{lib,libexec} -name \*.la -delete
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

function libtool_files {
  for la in $(find $TOOLS_DIR/$CONFIG_TARGET/sysroot/usr/lib* -name "*.la"); do \
  	cp -a "${la}" "${la}.fixed" && \
  	sed -i -e "s:$OUTPUT_DIR:@BASE_DIR@:g" \
  		-e "s:$TOOLS_DIR/$CONFIG_TARGET/sysroot:@STAGING_DIR@:g" \
  		 \
  		-e "s:\(['= ]\)/usr:\\1@STAGING_DIR@/usr:g" \
  		 \
  		-e "s:@STAGING_DIR@:$TOOLS_DIR/$CONFIG_TARGET/sysroot:g" \
  		-e "s:@BASE_DIR@:$OUTPUT_DIR:g" \
  		"${la}.fixed" && \
  	if cmp -s "${la}" "${la}.fixed"; then \
  		rm -f "${la}.fixed"; \
  	else \
  		mv "${la}.fixed" "${la}"; \
  	fi || exit 1; \
  done
}

prebuild_sanity_check
check_tarballs

echo -e "\nThis is your last chance to quit before we start building... continue?"
echo "(Note that if anything goes wrong during the build, the script will abort mission)"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) break;;
        No ) exit;;
    esac
done

total_time=$(timer)

rm -rf $OUTPUT_DIR
mkdir -pv $BUILD_DIR $TOOLS_DIR $ROOTFS_DIR

step "host-pkgconf 1.5.3"
extract $SOURCES_DIR/pkgconf-1.5.3.tar.gz $BUILD_DIR
(cd $BUILD_DIR/pkgconf-1.5.3 && \
PKG_CONFIG="$TOOLS_DIR/bin/pkg-config" \
PKG_CONFIG_SYSROOT_DIR="/" \
PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 \
PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 \
PKG_CONFIG_LIBDIR="$TOOLS_DIR/lib/pkgconfig:$TOOLS_DIR/share/pkgconfig" \
CPPFLAGS="-I$TOOLS_DIR/include" \
CFLAGS="-O2 -I$TOOLS_DIR/include" \
CXXFLAGS="-O2 -I$TOOLS_DIR/include" \
LDFLAGS="-L$TOOLS_DIR/lib -Wl,-rpath,$TOOLS_DIR/lib" \
INTLTOOL_PERL=/usr/bin/perl \
CFLAGS="-O2 -I$TOOLS_DIR/include" \
LDFLAGS="-L$TOOLS_DIR/lib -Wl,-rpath,$TOOLS_DIR/lib" \
CONFIG_SITE=/dev/null \
./configure \
--prefix=$TOOLS_DIR \
--enable-shared \
--disable-static )
PKG_CONFIG="$TOOLS_DIR/bin/pkg-config" PKG_CONFIG_SYSROOT_DIR="/" PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 PKG_CONFIG_LIBDIR="$TOOLS_DIR/lib/pkgconfig:$TOOLS_DIR/share/pkgconfig" make -j$PARALLEL_JOBS -C $BUILD_DIR/pkgconf-1.5.3
PKG_CONFIG="$TOOLS_DIR/bin/pkg-config" PKG_CONFIG_SYSROOT_DIR="/" PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 PKG_CONFIG_LIBDIR="$TOOLS_DIR/lib/pkgconfig:$TOOLS_DIR/share/pkgconfig" make -j$PARALLEL_JOBS install -C $BUILD_DIR/pkgconf-1.5.3
cat > $TOOLS_DIR/bin/pkg-config << "EOF"
#!/bin/sh
PKGCONFDIR=$(dirname $0)
DEFAULT_PKG_CONFIG_LIBDIR=${PKGCONFDIR}/../@STAGING_SUBDIR@/usr/lib/pkgconfig:${PKGCONFDIR}/../@STAGING_SUBDIR@/usr/share/pkgconfig
DEFAULT_PKG_CONFIG_SYSROOT_DIR=${PKGCONFDIR}/../@STAGING_SUBDIR@
PKG_CONFIG_LIBDIR=${PKG_CONFIG_LIBDIR:-${DEFAULT_PKG_CONFIG_LIBDIR}} PKG_CONFIG_SYSROOT_DIR=${PKG_CONFIG_SYSROOT_DIR:-${DEFAULT_PKG_CONFIG_SYSROOT_DIR}} exec ${PKGCONFDIR}/pkgconf @STATIC@ "$@"
EOF
chmod -v 0755 $TOOLS_DIR/bin/pkg-config
sed -i -e "s,@STAGING_SUBDIR@,$CONFIG_TARGET/sysroot,g" $TOOLS_DIR/bin/pkg-config
sed -i -e 's,@STATIC@,,' $TOOLS_DIR/bin/pkg-config
rm -rf $BUILD_DIR/pkgconf-1.5.3

step "host-libzlib 1.2.11"
extract $SOURCES_DIR/zlib-1.2.11.tar.xz $BUILD_DIR
(cd $BUILD_DIR/zlib-1.2.11 && \
PKG_CONFIG="$TOOLS_DIR/bin/pkg-config" \
PKG_CONFIG_SYSROOT_DIR="/" \
PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 \
PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 \
PKG_CONFIG_LIBDIR="$TOOLS_DIR/lib/pkgconfig:$TOOLS_DIR/share/pkgconfig" \
CPPFLAGS="-I$TOOLS_DIR/include" \
CFLAGS="-O2 -I$TOOLS_DIR/include" \
CXXFLAGS="-O2 -I$TOOLS_DIR/include" \
LDFLAGS="-L$TOOLS_DIR/lib -Wl,-rpath,$TOOLS_DIR/lib" \
INTLTOOL_PERL=/usr/bin/perl \
./configure \
--prefix=$TOOLS_DIR )
PKG_CONFIG="$TOOLS_DIR/bin/pkg-config" PKG_CONFIG_SYSROOT_DIR="/" PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 PKG_CONFIG_LIBDIR="$TOOLS_DIR/lib/pkgconfig:$TOOLS_DIR/share/pkgconfig" make -j1 -C $BUILD_DIR/zlib-1.2.11
PKG_CONFIG="$TOOLS_DIR/bin/pkg-config" PKG_CONFIG_SYSROOT_DIR="/" PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 PKG_CONFIG_LIBDIR="$TOOLS_DIR/lib/pkgconfig:$TOOLS_DIR/share/pkgconfig" make -j1 -C $BUILD_DIR/zlib-1.2.11 LDCONFIG=true install
rm -rf $BUILD_DIR/zlib-1.2.11

step "host-util-linux 2.33"
extract $SOURCES_DIR/util-linux-2.33.tar.xz $BUILD_DIR
(cd $BUILD_DIR/util-linux-2.33 && \
PKG_CONFIG="$TOOLS_DIR/bin/pkg-config" \
PKG_CONFIG_SYSROOT_DIR="/" \
PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 \
PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 \
PKG_CONFIG_LIBDIR="$TOOLS_DIR/lib/pkgconfig:$TOOLS_DIR/share/pkgconfig" \
CPPFLAGS="-I$TOOLS_DIR/include" \
CFLAGS="-O2 -I$TOOLS_DIR/include" \
CXXFLAGS="-O2 -I$TOOLS_DIR/include" \
LDFLAGS="-L$TOOLS_DIR/lib -Wl,-rpath,$TOOLS_DIR/lib" \
INTLTOOL_PERL=/usr/bin/perl \
CFLAGS="-O2 -I$TOOLS_DIR/include" \
LDFLAGS="-L$TOOLS_DIR/lib -Wl,-rpath,$TOOLS_DIR/lib" \
CONFIG_SITE=/dev/null \
./configure \
--prefix=$TOOLS_DIR \
--enable-shared \
--disable-static \
--without-python \
--enable-libblkid \
--enable-libmount \
--enable-libuuid \
--without-ncurses \
--without-ncursesw \
--without-tinfo \
--disable-makeinstall-chown \
--disable-agetty \
--disable-chfn-chsh \
--disable-chmem \
--disable-login \
--disable-lslogins \
--disable-mesg \
--disable-more \
--disable-newgrp \
--disable-nologin \
--disable-nsenter \
--disable-pg \
--disable-rfkill \
--disable-schedutils \
--disable-setpriv \
--disable-setterm \
--disable-su \
--disable-sulogin \
--disable-tunelp \
--disable-ul \
--disable-unshare \
--disable-uuidd \
--disable-vipw \
--disable-wall \
--disable-wdctl \
--disable-write \
--disable-zramctl )
PKG_CONFIG="$TOOLS_DIR/bin/pkg-config" PKG_CONFIG_SYSROOT_DIR="/" PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 PKG_CONFIG_LIBDIR="$TOOLS_DIR/lib/pkgconfig:$TOOLS_DIR/share/pkgconfig" make -j$PARALLEL_JOBS -C $BUILD_DIR/util-linux-2.33
PKG_CONFIG="$TOOLS_DIR/bin/pkg-config" PKG_CONFIG_SYSROOT_DIR="/" PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 PKG_CONFIG_LIBDIR="$TOOLS_DIR/lib/pkgconfig:$TOOLS_DIR/share/pkgconfig" make -j$PARALLEL_JOBS install -C $BUILD_DIR/util-linux-2.33
rm -rf $BUILD_DIR/util-linux-2.33

step "host-e2fsprogs 1.44.5"
extract $SOURCES_DIR/e2fsprogs-1.44.5.tar.gz $BUILD_DIR
( cd $BUILD_DIR/e2fsprogs-1.44.5 && \
PKG_CONFIG="$TOOLS_DIR/bin/pkg-config" \
PKG_CONFIG_SYSROOT_DIR="/" \
PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 \
PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 \
PKG_CONFIG_LIBDIR="$TOOLS_DIR/lib/pkgconfig:$TOOLS_DIR/share/pkgconfig" \
CPPFLAGS="-I$TOOLS_DIR/include" \
CFLAGS="-O2 -I$TOOLS_DIR/include" \
CXXFLAGS="-O2 -I$TOOLS_DIR/include" \
LDFLAGS="-L$TOOLS_DIR/lib -Wl,-rpath,$TOOLS_DIR/lib" \
INTLTOOL_PERL=/usr/bin/perl \
CFLAGS="-O2 -I$TOOLS_DIR/include" \
LDFLAGS="-L$TOOLS_DIR/lib -Wl,-rpath,$TOOLS_DIR/lib" \
ac_cv_path_LDCONFIG=true \
CONFIG_SITE=/dev/null \
./configure \
--prefix=$TOOLS_DIR \
--enable-shared \
--disable-static \
--disable-defrag \
--disable-e2initrd-helper \
--disable-fuse2fs \
--disable-libblkid \
--disable-libuuid \
--disable-testio-debug \
--enable-symlink-install \
--enable-elf-shlibs )
PKG_CONFIG="$TOOLS_DIR/bin/pkg-config" PKG_CONFIG_SYSROOT_DIR="/" PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 PKG_CONFIG_LIBDIR="$TOOLS_DIR/lib/pkgconfig:$TOOLS_DIR/share/pkgconfig" make -j$PARALLEL_JOBS -C $BUILD_DIR/e2fsprogs-1.44.5
PKG_CONFIG="$TOOLS_DIR/bin/pkg-config" PKG_CONFIG_SYSROOT_DIR="/" PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 PKG_CONFIG_LIBDIR="$TOOLS_DIR/lib/pkgconfig:$TOOLS_DIR/share/pkgconfig" make -j1 -C $BUILD_DIR/e2fsprogs-1.44.5 install install-libs
rm -rf $BUILD_DIR/e2fsprogs-1.44.5

step "host-attr 2.4.48"
extract $SOURCES_DIR/attr-2.4.48.tar.gz $BUILD_DIR
(cd $BUILD_DIR/attr-2.4.48 && \
PKG_CONFIG="$TOOLS_DIR/bin/pkg-config" \
PKG_CONFIG_SYSROOT_DIR="/" \
PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 \
PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 \
PKG_CONFIG_LIBDIR="$TOOLS_DIR/lib/pkgconfig:$TOOLS_DIR/share/pkgconfig" \
CPPFLAGS="-I$TOOLS_DIR/include" \
CFLAGS="-O2 -I$TOOLS_DIR/include" \
CXXFLAGS="-O2 -I$TOOLS_DIR/include" \
LDFLAGS="-L$TOOLS_DIR/lib -Wl,-rpath,$TOOLS_DIR/lib" \
INTLTOOL_PERL=/usr/bin/perl \
CFLAGS="-O2 -I$TOOLS_DIR/include" \
LDFLAGS="-L$TOOLS_DIR/lib -Wl,-rpath,$TOOLS_DIR/lib" \
CONFIG_SITE=/dev/null \
./configure \
--prefix=$TOOLS_DIR \
--enable-shared \
--disable-static \
--disable-nls )
PKG_CONFIG="$TOOLS_DIR/bin/pkg-config" PKG_CONFIG_SYSROOT_DIR="/" PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 PKG_CONFIG_LIBDIR="$TOOLS_DIR/lib/pkgconfig:$TOOLS_DIR/share/pkgconfig" make -j$PARALLEL_JOBS -C $BUILD_DIR/attr-2.4.48
PKG_CONFIG="$TOOLS_DIR/bin/pkg-config" PKG_CONFIG_SYSROOT_DIR="/" PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 PKG_CONFIG_LIBDIR="$TOOLS_DIR/lib/pkgconfig:$TOOLS_DIR/share/pkgconfig" make -j$PARALLEL_JOBS install -C $BUILD_DIR/attr-2.4.48
rm -rf $BUILD_DIR/attr-2.4.48

step "host-acl 2.2.53"
extract $SOURCES_DIR/acl-2.2.53.tar.gz $BUILD_DIR
(cd $BUILD_DIR/acl-2.2.53 && \
PKG_CONFIG="$TOOLS_DIR/bin/pkg-config" \
PKG_CONFIG_SYSROOT_DIR="/" \
PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 \
PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 \
PKG_CONFIG_LIBDIR="$TOOLS_DIR/lib/pkgconfig:$TOOLS_DIR/share/pkgconfig" \
CPPFLAGS="-I$TOOLS_DIR/include" \
CFLAGS="-O2 -I$TOOLS_DIR/include" \
CXXFLAGS="-O2 -I$TOOLS_DIR/include" \
LDFLAGS="-L$TOOLS_DIR/lib -Wl,-rpath,$TOOLS_DIR/lib" \
INTLTOOL_PERL=/usr/bin/perl \
CFLAGS="-O2 -I$TOOLS_DIR/include" \
LDFLAGS="-L$TOOLS_DIR/lib -Wl,-rpath,$TOOLS_DIR/lib" \
CONFIG_SITE=/dev/null \
./configure \
--prefix=$TOOLS_DIR \
--enable-shared \
--disable-static \
--disable-nls )
PKG_CONFIG="$TOOLS_DIR/bin/pkg-config" PKG_CONFIG_SYSROOT_DIR="/" PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 PKG_CONFIG_LIBDIR="$TOOLS_DIR/lib/pkgconfig:$TOOLS_DIR/share/pkgconfig" make -j$PARALLEL_JOBS -C $BUILD_DIR/acl-2.2.53
PKG_CONFIG="$TOOLS_DIR/bin/pkg-config" PKG_CONFIG_SYSROOT_DIR="/" PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 PKG_CONFIG_LIBDIR="$TOOLS_DIR/lib/pkgconfig:$TOOLS_DIR/share/pkgconfig" make -j$PARALLEL_JOBS install -C $BUILD_DIR/acl-2.2.53
rm -rf $BUILD_DIR/acl-2.2.53

step "host-fakeroot 1.20.2"
extract $SOURCES_DIR/fakeroot_1.20.2.orig.tar.bz2 $BUILD_DIR
( cd $BUILD_DIR/fakeroot-1.20.2 && \
PKG_CONFIG="$TOOLS_DIR/bin/pkg-config" \
PKG_CONFIG_SYSROOT_DIR="/" \
PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 \
PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 \
PKG_CONFIG_LIBDIR="$TOOLS_DIR/lib/pkgconfig:$TOOLS_DIR/share/pkgconfig" \
CPPFLAGS="-I$TOOLS_DIR/include" \
CFLAGS="-O2 -I$TOOLS_DIR/include" \
CXXFLAGS="-O2 -I$TOOLS_DIR/include" \
LDFLAGS="-L$TOOLS_DIR/lib -Wl,-rpath,$TOOLS_DIR/lib" \
INTLTOOL_PERL=/usr/bin/perl \
CFLAGS="-O2 -I$TOOLS_DIR/include" \
LDFLAGS="-L$TOOLS_DIR/lib -Wl,-rpath,$TOOLS_DIR/lib" \
ac_cv_header_sys_capability_h=no \
ac_cv_func_capset=no \
CONFIG_SITE=/dev/null \
./configure \
--prefix=$TOOLS_DIR \
--enable-shared \
--disable-static )
PKG_CONFIG="$TOOLS_DIR/bin/pkg-config" PKG_CONFIG_SYSROOT_DIR="/" PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 PKG_CONFIG_LIBDIR="$TOOLS_DIR/lib/pkgconfig:$TOOLS_DIR/share/pkgconfig" make -j$PARALLEL_JOBS -C $BUILD_DIR/fakeroot-1.20.2/
PKG_CONFIG="$TOOLS_DIR/bin/pkg-config" PKG_CONFIG_SYSROOT_DIR="/" PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 PKG_CONFIG_LIBDIR="$TOOLS_DIR/lib/pkgconfig:$TOOLS_DIR/share/pkgconfig" make -j$PARALLEL_JOBS install -C $BUILD_DIR/fakeroot-1.20.2/
rm -rf $BUILD_DIR/fakeroot-1.20.2

step "host-makedevs"
gcc -O2 -I$TOOLS_DIR/include $PACKAGES_DIR/makedevs/makedevs.c -o $TOOLS_DIR/bin/makedevs -L$TOOLS_DIR/lib -Wl,-rpath,$TOOLS_DIR/lib
chmod -v 755 $TOOLS_DIR/bin/makedevs

step "host-mkpasswd"
gcc -O2 -I$TOOLS_DIR/include -L$TOOLS_DIR/lib -Wl,-rpath,$TOOLS_DIR/lib $PACKAGES_DIR/mkpasswd/mkpasswd.c $PACKAGES_DIR/mkpasswd/utils.c -o $TOOLS_DIR/bin/mkpasswd -lcrypt
chmod -v 755 $TOOLS_DIR/bin/mkpasswd

step "host-m4 1.4.18"
extract $SOURCES_DIR/m4-1.4.18.tar.xz $BUILD_DIR
( cd $BUILD_DIR/m4-1.4.18 && \
PKG_CONFIG="$TOOLS_DIR/bin/pkg-config" \
PKG_CONFIG_SYSROOT_DIR="/" \
PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 \
PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 \
PKG_CONFIG_LIBDIR="$TOOLS_DIR/lib/pkgconfig:$TOOLS_DIR/share/pkgconfig" \
CPPFLAGS="-I$TOOLS_DIR/include" \
CFLAGS="-O2 -I$TOOLS_DIR/include" \
CXXFLAGS="-O2 -I$TOOLS_DIR/include" \
LDFLAGS="-L$TOOLS_DIR/lib -Wl,-rpath,$TOOLS_DIR/lib" \
INTLTOOL_PERL=/usr/bin/perl \
CFLAGS="-O2 -I$TOOLS_DIR/include" \
LDFLAGS="-L$TOOLS_DIR/lib -Wl,-rpath,$TOOLS_DIR/lib" \
CONFIG_SITE=/dev/null \
./configure \
--prefix=$TOOLS_DIR \
--enable-shared \
--disable-static )
PKG_CONFIG="$TOOLS_DIR/bin/pkg-config" PKG_CONFIG_SYSROOT_DIR="/" PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 PKG_CONFIG_LIBDIR="$TOOLS_DIR/lib/pkgconfig:$TOOLS_DIR/share/pkgconfig" make -j$PARALLEL_JOBS -C $BUILD_DIR/m4-1.4.18
PKG_CONFIG="$TOOLS_DIR/bin/pkg-config" PKG_CONFIG_SYSROOT_DIR="/" PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 PKG_CONFIG_LIBDIR="$TOOLS_DIR/lib/pkgconfig:$TOOLS_DIR/share/pkgconfig" make -j$PARALLEL_JOBS install -C $BUILD_DIR/m4-1.4.18
rm -rf $BUILD_DIR/m4-1.4.18

step "host-bison 3.0.4"
extract $SOURCES_DIR/bison-3.0.4.tar.xz $BUILD_DIR
(cd $BUILD_DIR/bison-3.0.4 && \
PKG_CONFIG="$TOOLS_DIR/bin/pkg-config" \
PKG_CONFIG_SYSROOT_DIR="/" \
PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 \
PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 \
PKG_CONFIG_LIBDIR="$TOOLS_DIR/lib/pkgconfig:$TOOLS_DIR/share/pkgconfig" \
CPPFLAGS="-I$TOOLS_DIR/include" \
CFLAGS="-O2 -I$TOOLS_DIR/include" \
CXXFLAGS="-O2 -I$TOOLS_DIR/include" \
LDFLAGS="-L$TOOLS_DIR/lib -Wl,-rpath,$TOOLS_DIR/lib" \
INTLTOOL_PERL=/usr/bin/perl \
CFLAGS="-O2 -I$TOOLS_DIR/include" \
LDFLAGS="-L$TOOLS_DIR/lib -Wl,-rpath,$TOOLS_DIR/lib" \
CONFIG_SITE=/dev/null \
./configure \
--prefix=$TOOLS_DIR \
--enable-shared \
--disable-static )
PKG_CONFIG="$TOOLS_DIR/bin/pkg-config" PKG_CONFIG_SYSROOT_DIR="/" PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 PKG_CONFIG_LIBDIR="$TOOLS_DIR/lib/pkgconfig:$TOOLS_DIR/share/pkgconfig" make -j$PARALLEL_JOBS -C $BUILD_DIR/bison-3.0.4
PKG_CONFIG="$TOOLS_DIR/bin/pkg-config" PKG_CONFIG_SYSROOT_DIR="/" PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 PKG_CONFIG_LIBDIR="$TOOLS_DIR/lib/pkgconfig:$TOOLS_DIR/share/pkgconfig" make -j$PARALLEL_JOBS install -C $BUILD_DIR/bison-3.0.4
rm -rf $BUILD_DIR/bison-3.0.4

step "host-gawk 4.2.1"
extract $SOURCES_DIR/gawk-4.2.1.tar.xz $BUILD_DIR
(cd $BUILD_DIR/gawk-4.2.1/ && \
PKG_CONFIG="$TOOLS_DIR/bin/pkg-config" \
PKG_CONFIG_SYSROOT_DIR="/" \
PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 \
PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 \
PKG_CONFIG_LIBDIR="$TOOLS_DIR/lib/pkgconfig:$TOOLS_DIR/share/pkgconfig" \
CPPFLAGS="-I$TOOLS_DIR/include" \
CFLAGS="-O2 -I$TOOLS_DIR/include" \
CXXFLAGS="-O2 -I$TOOLS_DIR/include" \
LDFLAGS="-L$TOOLS_DIR/lib -Wl,-rpath,$TOOLS_DIR/lib" \
INTLTOOL_PERL=/usr/bin/perl \
CFLAGS="-O2 -I$TOOLS_DIR/include" \
LDFLAGS="-L$TOOLS_DIR/lib -Wl,-rpath,$TOOLS_DIR/lib" \
CONFIG_SITE=/dev/null \
./configure \
--prefix=$TOOLS_DIR \
--enable-shared \
--disable-static \
--without-readline \
--without-mpfr )
PKG_CONFIG="$TOOLS_DIR/bin/pkg-config" PKG_CONFIG_SYSROOT_DIR="/" PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 PKG_CONFIG_LIBDIR="$TOOLS_DIR/lib/pkgconfig:$TOOLS_DIR/share/pkgconfig" make -j$PARALLEL_JOBS -C $BUILD_DIR/gawk-4.2.1/
PKG_CONFIG="$TOOLS_DIR/bin/pkg-config" PKG_CONFIG_SYSROOT_DIR="/" PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 PKG_CONFIG_LIBDIR="$TOOLS_DIR/lib/pkgconfig:$TOOLS_DIR/share/pkgconfig" make -j$PARALLEL_JOBS install -C $BUILD_DIR/gawk-4.2.1/
rm -rf $BUILD_DIR/gawk-4.2.1/

step "host-binutils 2.31.1"
extract $SOURCES_DIR/binutils-2.31.1.tar.xz $BUILD_DIR
mkdir -v $BUILD_DIR/binutils-2.31.1/build
( cd $BUILD_DIR/binutils-2.31.1/build && \
PKG_CONFIG="$TOOLS_DIR/bin/pkg-config" \
PKG_CONFIG_SYSROOT_DIR="/" \
PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 \
PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 \
PKG_CONFIG_LIBDIR="$TOOLS_DIR/lib/pkgconfig:$TOOLS_DIR/share/pkgconfig" \
CPPFLAGS="-I$TOOLS_DIR/include" \
CFLAGS="-O2 -I$TOOLS_DIR/include" \
CXXFLAGS="-O2 -I$TOOLS_DIR/include" \
LDFLAGS="-L$TOOLS_DIR/lib -Wl,-rpath,$TOOLS_DIR/lib" \
INTLTOOL_PERL=/usr/bin/perl \
CFLAGS="-O2 -I$TOOLS_DIR/include" \
LDFLAGS="-L$TOOLS_DIR/lib -Wl,-rpath,$TOOLS_DIR/lib" \
MAKEINFO=true \
CONFIG_SITE=/dev/null \
$BUILD_DIR/binutils-2.31.1/configure \
--prefix=$TOOLS_DIR \
--enable-shared \
--disable-static \
--disable-multilib \
--disable-werror \
--target=$CONFIG_TARGET \
--disable-shared \
--enable-static \
--with-sysroot=$TOOLS_DIR/$CONFIG_TARGET/sysroot \
--enable-poison-system-directories \
--disable-sim \
--disable-gdb )
PKG_CONFIG="$TOOLS_DIR/bin/pkg-config" PKG_CONFIG_SYSROOT_DIR="/" PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 PKG_CONFIG_LIBDIR="$TOOLS_DIR/lib/pkgconfig:$TOOLS_DIR/share/pkgconfig" make -j$PARALLEL_JOBS MAKEINFO=true -C $BUILD_DIR/binutils-2.31.1/build
PKG_CONFIG="$TOOLS_DIR/bin/pkg-config" PKG_CONFIG_SYSROOT_DIR="/" PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 PKG_CONFIG_LIBDIR="$TOOLS_DIR/lib/pkgconfig:$TOOLS_DIR/share/pkgconfig" make -j$PARALLEL_JOBS MAKEINFO=true install -C $BUILD_DIR/binutils-2.31.1/build
rm -rf $BUILD_DIR/binutils-2.31.1

step "host-gmp 6.1.2"
extract $SOURCES_DIR/gmp-6.1.2.tar.xz $BUILD_DIR
(cd $BUILD_DIR/gmp-6.1.2 && \
PKG_CONFIG="$TOOLS_DIR/bin/pkg-config" \
PKG_CONFIG_SYSROOT_DIR="/" \
PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 \
PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 \
PKG_CONFIG_LIBDIR="$TOOLS_DIR/lib/pkgconfig:$TOOLS_DIR/share/pkgconfig" \
CPPFLAGS="-I$TOOLS_DIR/include" \
CFLAGS="-O2 -I$TOOLS_DIR/include" \
CXXFLAGS="-O2 -I$TOOLS_DIR/include" \
LDFLAGS="-L$TOOLS_DIR/lib -Wl,-rpath,$TOOLS_DIR/lib" \
INTLTOOL_PERL=/usr/bin/perl \
CFLAGS="-O2 -I$TOOLS_DIR/include" \
LDFLAGS="-L$TOOLS_DIR/lib -Wl,-rpath,$TOOLS_DIR/lib" \
CONFIG_SITE=/dev/null \
./configure \
--prefix=$TOOLS_DIR \
--enable-shared \
--disable-static )
PKG_CONFIG="$TOOLS_DIR/bin/pkg-config" PKG_CONFIG_SYSROOT_DIR="/" PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 PKG_CONFIG_LIBDIR="$TOOLS_DIR/lib/pkgconfig:$TOOLS_DIR/share/pkgconfig" make -j$PARALLEL_JOBS -C $BUILD_DIR/gmp-6.1.2
PKG_CONFIG="$TOOLS_DIR/bin/pkg-config" PKG_CONFIG_SYSROOT_DIR="/" PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 PKG_CONFIG_LIBDIR="$TOOLS_DIR/lib/pkgconfig:$TOOLS_DIR/share/pkgconfig" make -j$PARALLEL_JOBS install -C $BUILD_DIR/gmp-6.1.2
rm -rf $BUILD_DIR/gmp-6.1.2

step "host-mpfr 3.1.6"
extract $SOURCES_DIR/mpfr-3.1.6.tar.xz $BUILD_DIR
(cd $BUILD_DIR/mpfr-3.1.6/ && \
PKG_CONFIG="$TOOLS_DIR/bin/pkg-config" \
PKG_CONFIG_SYSROOT_DIR="/" \
PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 \
PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 \
PKG_CONFIG_LIBDIR="$TOOLS_DIR/lib/pkgconfig:$TOOLS_DIR/share/pkgconfig" \
CPPFLAGS="-I$TOOLS_DIR/include" \
CFLAGS="-O2 -I$TOOLS_DIR/include" \
CXXFLAGS="-O2 -I$TOOLS_DIR/include" \
LDFLAGS="-L$TOOLS_DIR/lib -Wl,-rpath,$TOOLS_DIR/lib" \
INTLTOOL_PERL=/usr/bin/perl \
CFLAGS="-O2 -I$TOOLS_DIR/include" \
LDFLAGS="-L$TOOLS_DIR/lib -Wl,-rpath,$TOOLS_DIR/lib" \
CONFIG_SITE=/dev/null \
./configure \
--prefix=$TOOLS_DIR \
--enable-shared \
--disable-static )
PKG_CONFIG="$TOOLS_DIR/bin/pkg-config" PKG_CONFIG_SYSROOT_DIR="/" PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 PKG_CONFIG_LIBDIR="$TOOLS_DIR/lib/pkgconfig:$TOOLS_DIR/share/pkgconfig" make -j$PARALLEL_JOBS -C $BUILD_DIR/mpfr-3.1.6
PKG_CONFIG="$TOOLS_DIR/bin/pkg-config" PKG_CONFIG_SYSROOT_DIR="/" PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 PKG_CONFIG_LIBDIR="$TOOLS_DIR/lib/pkgconfig:$TOOLS_DIR/share/pkgconfig" make -j$PARALLEL_JOBS install -C $BUILD_DIR/mpfr-3.1.6
rm -rf $BUILD_DIR/mpfr-3.1.6

step "host-mpc 1.0.3"
extract $SOURCES_DIR/mpc-1.0.3.tar.gz $BUILD_DIR
(cd $BUILD_DIR/mpc-1.0.3/ && \
PKG_CONFIG="$TOOLS_DIR/bin/pkg-config" \
PKG_CONFIG_SYSROOT_DIR="/" \
PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 \
PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 \
PKG_CONFIG_LIBDIR="$TOOLS_DIR/lib/pkgconfig:$TOOLS_DIR/share/pkgconfig" \
CPPFLAGS="-I$TOOLS_DIR/include" \
CFLAGS="-O2 -I$TOOLS_DIR/include" \
CXXFLAGS="-O2 -I$TOOLS_DIR/include" \
LDFLAGS="-L$TOOLS_DIR/lib -Wl,-rpath,$TOOLS_DIR/lib" \
INTLTOOL_PERL=/usr/bin/perl \
CFLAGS="-O2 -I$TOOLS_DIR/include" \
LDFLAGS="-L$TOOLS_DIR/lib -Wl,-rpath,$TOOLS_DIR/lib" \
CONFIG_SITE=/dev/null \
./configure \
--prefix=$TOOLS_DIR \
--enable-shared \
--disable-static )
PKG_CONFIG="$TOOLS_DIR/bin/pkg-config" PKG_CONFIG_SYSROOT_DIR="/" PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 PKG_CONFIG_LIBDIR="$TOOLS_DIR/lib/pkgconfig:$TOOLS_DIR/share/pkgconfig" make -j$PARALLEL_JOBS -C $BUILD_DIR/mpc-1.0.3/
PKG_CONFIG="$TOOLS_DIR/bin/pkg-config" PKG_CONFIG_SYSROOT_DIR="/" PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 PKG_CONFIG_LIBDIR="$TOOLS_DIR/lib/pkgconfig:$TOOLS_DIR/share/pkgconfig" make -j$PARALLEL_JOBS install -C $BUILD_DIR/mpc-1.0.3/
rm -rf $BUILD_DIR/mpc-1.0.3

step "host-gcc-initial 8.3.0"
extract $SOURCES_DIR/gcc-8.3.0.tar.xz $BUILD_DIR
mkdir -p $BUILD_DIR/gcc-8.3.0/build
( cd $BUILD_DIR/gcc-8.3.0/build && \
PKG_CONFIG="$TOOLS_DIR/bin/pkg-config" \
PKG_CONFIG_SYSROOT_DIR="/" \
PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 \
PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 \
PKG_CONFIG_LIBDIR="$TOOLS_DIR/lib/pkgconfig:$TOOLS_DIR/share/pkgconfig" \
CPPFLAGS="-I$TOOLS_DIR/include" \
CFLAGS="-O2 -I$TOOLS_DIR/include" \
CXXFLAGS="-O2 -I$TOOLS_DIR/include" \
LDFLAGS="-L$TOOLS_DIR/lib -Wl,-rpath,$TOOLS_DIR/lib" \
INTLTOOL_PERL=/usr/bin/perl \
CFLAGS="-O2 -I$TOOLS_DIR/include" \
LDFLAGS="-L$TOOLS_DIR/lib -Wl,-rpath,$TOOLS_DIR/lib" \
MAKEINFO=missing \
CFLAGS_FOR_TARGET="-D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64 -Os" \
CXXFLAGS_FOR_TARGET="-D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64 -Os" \
CONFIG_SITE=/dev/null \
$BUILD_DIR/gcc-8.3.0/configure \
--prefix=$TOOLS_DIR \
--enable-shared \
--disable-static \
--target=$CONFIG_TARGET \
--with-sysroot=$TOOLS_DIR/$CONFIG_TARGET/sysroot \
--enable-__cxa_atexit \
--with-gnu-ld \
--disable-libssp \
--disable-multilib \
--disable-decimal-float \
--with-gmp=$TOOLS_DIR \
--with-mpc=$TOOLS_DIR \
--with-mpfr=$TOOLS_DIR \
--with-pkgversion="Buildroot 2019.02.1" \
--with-bugurl="http://bugs.buildroot.net/" \
--enable-libquadmath \
--enable-tls \
--disable-libmudflap \
--enable-threads \
--without-isl \
--without-cloog \
--with-arch="nocona" \
--enable-languages=c \
--disable-shared \
--without-headers \
--disable-threads \
--with-newlib \
--disable-largefile \
--disable-nls )
PKG_CONFIG="$TOOLS_DIR/bin/pkg-config" PKG_CONFIG_SYSROOT_DIR="/" PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 PKG_CONFIG_LIBDIR="$TOOLS_DIR/lib/pkgconfig:$TOOLS_DIR/share/pkgconfig" make -j$PARALLEL_JOBS gcc_cv_libc_provides_ssp=yes all-gcc all-target-libgcc -C $BUILD_DIR/gcc-8.3.0/build
PKG_CONFIG="$TOOLS_DIR/bin/pkg-config" PKG_CONFIG_SYSROOT_DIR="/" PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 PKG_CONFIG_LIBDIR="$TOOLS_DIR/lib/pkgconfig:$TOOLS_DIR/share/pkgconfig" make -j$PARALLEL_JOBS install-gcc install-target-libgcc -C $BUILD_DIR/gcc-8.3.0/build
rm -rf $BUILD_DIR/gcc-8.3.0

step "host-skeleton-init-common"
mkdir -pv $TOOLS_DIR/$CONFIG_TARGET/sysroot/{dev,etc,media,mnt,opt,proc,root,run,sys,tmp,usr}
ln -svf /proc/self/fd $TOOLS_DIR/$CONFIG_TARGET/sysroot/dev/fd
ln -svf /proc/self/fd/2 $TOOLS_DIR/$CONFIG_TARGET/sysroot/dev/stderr
ln -svf /proc/self/fd/0 $TOOLS_DIR/$CONFIG_TARGET/sysroot/dev/stdin
ln -svf /proc/self/fd/1 $TOOLS_DIR/$CONFIG_TARGET/sysroot/dev/stdout
cp -v $PACKAGES_DIR/skeleton/etc/{group,hosts,passwd,profile,protocols,services,shadow} $TOOLS_DIR/$CONFIG_TARGET/sysroot/etc
ln -svf /proc/self/mounts $TOOLS_DIR/$CONFIG_TARGET/sysroot/etc/mtab
mkdir -v $TOOLS_DIR/$CONFIG_TARGET/sysroot/etc/profile.d
cp -v $PACKAGES_DIR/skeleton/etc/profile.d/umask.sh $TOOLS_DIR/$CONFIG_TARGET/sysroot/etc/profile.d
ln -svf /tmp/resolv.conf $TOOLS_DIR/$CONFIG_TARGET/sysroot/etc/resolv.conf
mkdir -pv $TOOLS_DIR/$CONFIG_TARGET/sysroot/usr/{bin,lib,sbin}
install -d -m 0755 $TOOLS_DIR/$CONFIG_TARGET/sysroot/bin
install -d -m 0755 $TOOLS_DIR/$CONFIG_TARGET/sysroot/sbin
install -d -m 0755 $TOOLS_DIR/$CONFIG_TARGET/sysroot/lib
ln -snf lib $TOOLS_DIR/$CONFIG_TARGET/sysroot/lib64
ln -snf lib $TOOLS_DIR/$CONFIG_TARGET/sysroot/usr/lib64
install -d -m 0755 $TOOLS_DIR/$CONFIG_TARGET/sysroot/usr/include

step "skeleton-init-common"
mkdir -pv $ROOTFS_DIR/{dev,etc,media,mnt,opt,proc,root,run,sys,tmp,usr}
ln -svf /proc/self/fd $ROOTFS_DIR/dev/fd
ln -svf /proc/self/fd/2 $ROOTFS_DIR/dev/stderr
ln -svf /proc/self/fd/0 $ROOTFS_DIR/dev/stdin
ln -svf /proc/self/fd/1 $ROOTFS_DIR/dev/stdout
cp -v $PACKAGES_DIR/skeleton/etc/{group,hosts,passwd,profile,protocols,services,shadow} $ROOTFS_DIR/etc
ln -svf /proc/self/mounts $ROOTFS_DIR/etc/mtab
mkdir -v $ROOTFS_DIR/etc/profile.d
cp -v $PACKAGES_DIR/skeleton/etc/profile.d/umask.sh $ROOTFS_DIR/etc/profile.d
ln -svf /tmp/resolv.conf $ROOTFS_DIR/etc/resolv.conf
mkdir -pv $ROOTFS_DIR/usr/{bin,lib,sbin}
install -d -m 0755 $ROOTFS_DIR/bin
install -d -m 0755 $ROOTFS_DIR/sbin
install -d -m 0755 $ROOTFS_DIR/lib
ln -snf lib $ROOTFS_DIR/lib64
ln -snf lib $ROOTFS_DIR/usr/lib64
sed -i -e 's,@PATH@,"/bin:/sbin:/usr/bin:/usr/sbin",' $ROOTFS_DIR/etc/profile

step "skeleton-init-sysv"
mkdir -pv $ROOTFS_DIR/dev/{pts,shm}
ln -svf /tmp/log $ROOTFS_DIR/dev/log
cp -v $PACKAGES_DIR/skeleton/etc/fstab $ROOTFS_DIR/etc
mkdir -pv $ROOTFS_DIR/var/lib
ln -svf /tmp $ROOTFS_DIR/var/cache
ln -svf /tmp $ROOTFS_DIR/var/lib/misc
ln -svf /tmp $ROOTFS_DIR/var/lock
ln -svf /tmp $ROOTFS_DIR/var/log
ln -svf /run $ROOTFS_DIR/var/run
ln -svf /tmp $ROOTFS_DIR/var/spool
ln -svf /tmp $ROOTFS_DIR/var/tmp

step "linux-headers 4.19.16"
extract $SOURCES_DIR/linux-4.19.16.tar.xz $BUILD_DIR
make -j$PARALLEL_JOBS ARCH=x86_64 HOSTCC="gcc" HOSTCFLAGS="" HOSTCXX="g++" INSTALL_HDR_PATH=$TOOLS_DIR/$CONFIG_TARGET/sysroot/usr headers_install -C $BUILD_DIR/linux-4.19.16
rm -rf $BUILD_DIR/linux-4.19.16

step "glibc"
extract $SOURCES_DIR/glibc-2.29.tar.xz $BUILD_DIR
mkdir -v $BUILD_DIR/glibc-2.29/build
( cd $BUILD_DIR/glibc-2.29/build && \
CC="$TOOLS_DIR/bin/$CONFIG_TARGET-gcc" \
CXX="$TOOLS_DIR/bin/$CONFIG_TARGET-g++" \
AR="$TOOLS_DIR/bin/$CONFIG_TARGET-ar" \
AS="$TOOLS_DIR/bin/$CONFIG_TARGET-as" \
LD="$TOOLS_DIR/bin/$CONFIG_TARGET-ld" \
RANLIB="$TOOLS_DIR/bin/$CONFIG_TARGET-ranlib" \
READELF="$TOOLS_DIR/bin/$CONFIG_TARGET-readelf" \
STRIP="$TOOLS_DIR/bin/$CONFIG_TARGET-strip" \
OBJCOPY="$TOOLS_DIR/bin/$CONFIG_TARGET-objcopy" \
OBJDUMP="$TOOLS_DIR/bin/$CONFIG_TARGET-objdump" \
CPPFLAGS="-D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64" \
CFLAGS="-D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64 -Os" \
CXXFLAGS="-D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64 -Os" \
LDFLAGS="" \
PKG_CONFIG="$TOOLS_DIR/bin/pkg-config" \
STAGING_DIR="$TOOLS_DIR/$CONFIG_TARGET/sysroot" \
INTLTOOL_PERL=/usr/bin/perl \
CXX=no \
CFLAGS="-O2 " \
CPPFLAGS="" \
CXXFLAGS="-O2" \
ac_cv_path_BASH_SHELL=/bin/bash \
libc_cv_forced_unwind=yes \
libc_cv_ssp=no \
ac_cv_prog_MAKE="make -j$PARALLEL_JOBS" \
$BUILD_DIR/glibc-2.29/configure \
--target=$CONFIG_TARGET \
--host=$CONFIG_TARGET \
--build=x86_64-pc-linux-gnu \
--prefix=/usr \
--enable-shared \
--enable-lock-elision \
--with-pkgversion="Buildroot" \
--without-cvs \
--disable-profile \
--without-gd \
--enable-obsolete-rpc \
--enable-kernel=4.19 \
--with-headers=$TOOLS_DIR/$CONFIG_TARGET/sysroot/usr/include )
make -j$PARALLEL_JOBS -C $BUILD_DIR/glibc-2.29/build
make -j$PARALLEL_JOBS install_root=$TOOLS_DIR/$CONFIG_TARGET/sysroot install -C $BUILD_DIR/glibc-2.29/build
make -j$PARALLEL_JOBS install_root=$ROOTFS_DIR install -C $BUILD_DIR/glibc-2.29/build
rm -rf $BUILD_DIR/glibc-2.29

step "host-gcc-final 8.3.0"
extract $SOURCES_DIR/gcc-8.3.0.tar.xz $BUILD_DIR
mkdir -p $BUILD_DIR/gcc-8.3.0/build
( cd $BUILD_DIR/gcc-8.3.0/build && \
PKG_CONFIG="$TOOLS_DIR/bin/pkg-config" \
PKG_CONFIG_SYSROOT_DIR="/" \
PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 \
PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 \
PKG_CONFIG_LIBDIR="$TOOLS_DIR/lib/pkgconfig:$TOOLS_DIR/share/pkgconfig" \
CPPFLAGS="-I$TOOLS_DIR/include" \
CFLAGS="-O2 -I$TOOLS_DIR/include" \
CXXFLAGS="-O2 -I$TOOLS_DIR/include" \
LDFLAGS="-L$TOOLS_DIR/lib -Wl,-rpath,$TOOLS_DIR/lib" \
INTLTOOL_PERL=/usr/bin/perl \
CFLAGS="-O2 -I$TOOLS_DIR/include" \
LDFLAGS="-L$TOOLS_DIR/lib -Wl,-rpath,$TOOLS_DIR/lib" \
MAKEINFO=missing \
CFLAGS_FOR_TARGET="-D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64 -Os" \
CXXFLAGS_FOR_TARGET="-D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64 -Os " \
$BUILD_DIR/gcc-8.3.0/configure \
--prefix=$TOOLS_DIR \
--enable-static \
--target=$CONFIG_TARGET \
--with-sysroot=$TOOLS_DIR/$CONFIG_TARGET/sysroot \
--enable-__cxa_atexit \
--with-gnu-ld \
--disable-libssp \
--disable-multilib \
--disable-decimal-float \
--with-gmp=$TOOLS_DIR \
--with-mpc=$TOOLS_DIR \
--with-mpfr=$TOOLS_DIR \
--with-pkgversion="Buildroot 2019.02.1" \
--with-bugurl="http://bugs.buildroot.net/" \
--enable-libquadmath \
--enable-tls \
--disable-libmudflap \
--enable-threads \
--without-isl \
--without-cloog \
--with-arch="nocona" \
--enable-languages=c \
--with-build-time-tools=$TOOLS_DIR/$CONFIG_TARGET/bin \
--enable-shared \
--disable-libgomp )
PKG_CONFIG="$TOOLS_DIR/bin/pkg-config" PKG_CONFIG_SYSROOT_DIR="/" PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 PKG_CONFIG_LIBDIR="$TOOLS_DIR/lib/pkgconfig:$TOOLS_DIR/share/pkgconfig" make -j$PARALLEL_JOBS gcc_cv_libc_provides_ssp=yes -C $BUILD_DIR/gcc-8.3.0/build
PKG_CONFIG="$TOOLS_DIR/bin/pkg-config" PKG_CONFIG_SYSROOT_DIR="/" PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 PKG_CONFIG_LIBDIR="$TOOLS_DIR/lib/pkgconfig:$TOOLS_DIR/share/pkgconfig" make -j$PARALLEL_JOBS install -C $BUILD_DIR/gcc-8.3.0/build
rm -rf $BUILD_DIR/gcc-8.3.0

step "busybox 1.29.3"
extract $SOURCES_DIR/busybox-1.29.3.tar.bz2 $BUILD_DIR
make -j$PARALLEL_JOBS distclean -C $BUILD_DIR/busybox-1.29.3
make -j$PARALLEL_JOBS ARCH="x86_64" defconfig -C $BUILD_DIR/busybox-1.29.3
CFLAGS="-D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64 -Os" CFLAGS_busybox="" make -j$PARALLEL_JOBS CC="$TOOLS_DIR/bin/$CONFIG_TARGET-gcc" ARCH=x86_64 PREFIX="$ROOTFS_DIR" EXTRA_LDFLAGS="" CROSS_COMPILE="$TOOLS_DIR/bin/$CONFIG_TARGET-" CONFIG_PREFIX="$ROOTFS_DIR" SKIP_STRIP=y -C $BUILD_DIR/busybox-1.29.3
CFLAGS="-D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64 -Os" CFLAGS_busybox="" make -j$PARALLEL_JOBS CC="$TOOLS_DIR/bin/$CONFIG_TARGET-gcc" ARCH=x86_64 PREFIX="$ROOTFS_DIR" EXTRA_LDFLAGS="" CROSS_COMPILE="$TOOLS_DIR/bin/$CONFIG_TARGET-" CONFIG_PREFIX="$ROOTFS_DIR" SKIP_STRIP=y -C $BUILD_DIR/busybox-1.29.3 install-noclobber
install -D -m 0644 $PACKAGES_DIR/skeleton/etc/inittab $ROOTFS_DIR/etc/inittab
if grep -q CONFIG_UDHCPC=y $BUILD_DIR/busybox-1.29.3/.config; then
  install -m 0755 -D $PACKAGES_DIR/busybox/udhcpc.script $ROOTFS_DIR/usr/share/udhcpc/default.script
  install -m 0755 -d $ROOTFS_DIR/usr/share/udhcpc/default.script.d
fi
if grep -q CONFIG_SYSLOGD=y $BUILD_DIR/busybox-1.29.3/.config; then
  install -m 0755 -D $PACKAGES_DIR/busybox/S01syslogd $ROOTFS_DIR/etc/init.d/S01syslogd
fi
if grep -q CONFIG_KLOGD=y $BUILD_DIR/busybox-1.29.3/.config; then
  install -m 0755 -D $PACKAGES_DIR/busybox/S02klogd $ROOTFS_DIR/etc/init.d/S02klogd
fi
if grep -q CONFIG_FEATURE_TELNETD_STANDALONE=y $BUILD_DIR/busybox-1.29.3/.config; then
  install -m 0755 -D $PACKAGES_DIR/busybox/S50telnet $ROOTFS_DIR/etc/init.d/S50telnet
fi
rm -rf $BUILD_DIR/busybox-1.29.3

step "ifupdown-scripts"
mkdir -pv $ROOTFS_DIR/etc/network/{if-down.d,if-post-down.d,if-pre-up.d,if-up.d}
cat > $ROOTFS_DIR/etc/network/if-pre-up.d/wait_iface << "EOF"
#!/bin/sh

# In case we have a slow-to-appear interface (e.g. eth-over-USB),
# and we need to configure it, wait until it appears, but not too
# long either. IF_WAIT_DELAY is in seconds.

if [ "${IF_WAIT_DELAY}" -a ! -e "/sys/class/net/${IFACE}" ]; then
    printf "Waiting for interface %s to appear" "${IFACE}"
    while [ ${IF_WAIT_DELAY} -gt 0 ]; do
        if [ -e "/sys/class/net/${IFACE}" ]; then
            printf "\n"
            exit 0
        fi
        sleep 1
        printf "."
        : $((IF_WAIT_DELAY -= 1))
    done
    printf " timeout!\n"
    exit 1
fi
EOF
chmod -v 755 $ROOTFS_DIR/etc/network/if-pre-up.d/wait_iface
( echo "# interface file auto-generated by buildroot"; echo ; echo "auto lo"; echo "iface lo inet loopback"; ) > $ROOTFS_DIR/etc/network/interfaces
( echo ; echo "auto eth0"; echo "iface eth0 inet dhcp"; echo "  pre-up /etc/network/nfs_check"; echo "  wait-delay 15"; echo "  hostname \$(hostname)"; ) >> $ROOTFS_DIR/etc/network/interfaces
install -m 0755 -Dv $PACKAGES_DIR/ifupdown-scripts//nfs_check $ROOTFS_DIR/etc/network/nfs_check
install -Dv -m 0755 $PACKAGES_DIR/ifupdown-scripts/S40network $ROOTFS_DIR/etc/init.d/S40network

step "initscripts"
mkdir -p  $ROOTFS_DIR/etc/init.d
install -Dv -m 0755 $PACKAGES_DIR/initscripts/init.d/* $ROOTFS_DIR/etc/init.d/

step "libzlib 1.2.11"
extract $SOURCES_DIR/zlib-1.2.11.tar.xz $BUILD_DIR
( cd $BUILD_DIR/zlib-1.2.11 && \
CC="$TOOLS_DIR/bin/$CONFIG_TARGET-gcc" \
CXX="$TOOLS_DIR/bin/$CONFIG_TARGET-g++" \
AR="$TOOLS_DIR/bin/$CONFIG_TARGET-ar" \
AS="$TOOLS_DIR/bin/$CONFIG_TARGET-as" \
LD="$TOOLS_DIR/bin/$CONFIG_TARGET-ld" \
RANLIB="$TOOLS_DIR/bin/$CONFIG_TARGET-ranlib" \
READELF="$TOOLS_DIR/bin/$CONFIG_TARGET-readelf" \
STRIP="$TOOLS_DIR/bin/$CONFIG_TARGET-strip" \
OBJCOPY="$TOOLS_DIR/bin/$CONFIG_TARGET-objcopy" \
OBJDUMP="$TOOLS_DIR/bin/$CONFIG_TARGET-objdump" \
CPPFLAGS="-D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64" \
CFLAGS="-D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64 -Os" \
CXXFLAGS="-D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64 -Os" \
LDFLAGS="" \
PKG_CONFIG="$TOOLS_DIR/bin/pkg-config" \
STAGING_DIR="$TOOLS_DIR/$CONFIG_TARGET/sysroot" \
INTLTOOL_PERL=/usr/bin/perl \
CXX=no \
CFLAGS="-D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64 -Os -fPIC" \
./configure \
--shared \
--prefix=/usr )
make -j1 -C $BUILD_DIR/zlib-1.2.11
make -j1 -C $BUILD_DIR/zlib-1.2.11 DESTDIR=$TOOLS_DIR/$CONFIG_TARGET/sysroot LDCONFIG=true install
make -j1 -C $BUILD_DIR/zlib-1.2.11 DESTDIR=$ROOTFS_DIR LDCONFIG=true install
rm -rf $BUILD_DIR/zlib-1.2.11

step "libopenssl 1.1.1a"
extract $SOURCES_DIR/openssl-1.1.1a.tar.gz $BUILD_DIR
(cd $BUILD_DIR/openssl-1.1.1a && \
CC="$TOOLS_DIR/bin/$CONFIG_TARGET-gcc" \
CXX="$TOOLS_DIR/bin/$CONFIG_TARGET-g++" \
AR="$TOOLS_DIR/bin/$CONFIG_TARGET-ar" \
AS="$TOOLS_DIR/bin/$CONFIG_TARGET-as" \
LD="$TOOLS_DIR/bin/$CONFIG_TARGET-ld" \
RANLIB="$TOOLS_DIR/bin/$CONFIG_TARGET-ranlib" \
READELF="$TOOLS_DIR/bin/$CONFIG_TARGET-readelf" \
STRIP="$TOOLS_DIR/bin/$CONFIG_TARGET-strip" \
OBJCOPY="$TOOLS_DIR/bin/$CONFIG_TARGET-objcopy" \
OBJDUMP="$TOOLS_DIR/bin/$CONFIG_TARGET-objdump" \
CPPFLAGS="-D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64" \
CFLAGS="-D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64 -Os" \
CXXFLAGS="-D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64 -Os" \
LDFLAGS="" \
PKG_CONFIG="$TOOLS_DIR/bin/pkg-config" \
STAGING_DIR="$TOOLS_DIR/$CONFIG_TARGET/sysroot" \
INTLTOOL_PERL=/usr/bin/perl \
CXX=no \
./Configure \
linux-x86_64 \
--prefix=/usr \
--openssldir=/etc/ssl \
-latomic \
threads \
shared \
no-rc5 \
enable-camellia \
enable-mdc2 \
no-tests \
no-fuzz-libfuzzer \
no-fuzz-afl \
zlib-dynamic )
make -j$PARALLEL_JOBS -C $BUILD_DIR/openssl-1.1.1a
make -j$PARALLEL_JOBS -C $BUILD_DIR/openssl-1.1.1a DESTDIR=$TOOLS_DIR/$CONFIG_TARGET/sysroot install
make -j$PARALLEL_JOBS -C $BUILD_DIR/openssl-1.1.1a DESTDIR=$ROOTFS_DIR install
rm -rf $BUILD_DIR/openssl-1.1.1a

step "libcurl 7.64.1"
extract $SOURCES_DIR/curl-7.64.1.tar.xz $BUILD_DIR
(cd $BUILD_DIR/curl-7.64.1 && \
CC="$TOOLS_DIR/bin/$CONFIG_TARGET-gcc" \
CXX="$TOOLS_DIR/bin/$CONFIG_TARGET-g++" \
AR="$TOOLS_DIR/bin/$CONFIG_TARGET-ar" \
AS="$TOOLS_DIR/bin/$CONFIG_TARGET-as" \
LD="$TOOLS_DIR/bin/$CONFIG_TARGET-ld" \
RANLIB="$TOOLS_DIR/bin/$CONFIG_TARGET-ranlib" \
READELF="$TOOLS_DIR/bin/$CONFIG_TARGET-readelf" \
STRIP="$TOOLS_DIR/bin/$CONFIG_TARGET-strip" \
OBJCOPY="$TOOLS_DIR/bin/$CONFIG_TARGET-objcopy" \
OBJDUMP="$TOOLS_DIR/bin/$CONFIG_TARGET-objdump" \
CPPFLAGS="-D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64" \
CFLAGS="-D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64  -Os  " \
CXXFLAGS="-D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64  -Os  " \
LDFLAGS="" \
PKG_CONFIG="$TOOLS_DIR/bin/pkg-config" \
STAGING_DIR="$TOOLS_DIR/$CONFIG_TARGET/sysroot" \
INTLTOOL_PERL=/usr/bin/perl \
CXX=no \
LD_LIBRARY_PATH=/lib:/usr/lib \
CONFIG_SITE=/dev/null \
./configure \
--target=$CONFIG_TARGET \
--host=$CONFIG_TARGET \
--build=x86_64-pc-linux-gnu \
--prefix=/usr \
--exec-prefix=/usr \
--sysconfdir=/etc \
--localstatedir=/var \
--program-prefix="" \
--disable-static \
--enable-shared \
--disable-manual \
--disable-ntlm-wb \
--enable-hidden-symbols \
--with-random=/dev/urandom \
--disable-curldebug \
--without-polarssl \
--enable-threaded-resolver \
--disable-verbose \
--with-ssl=$TOOLS_DIR/$CONFIG_TARGET/sysroot/usr \
--with-ca-path=/etc/ssl/certs \
--without-gnutls \
--without-nss \
--without-mbedtls \
--disable-ares \
--without-libidn2 \
--without-libssh2 \
--without-brotli \
--without-nghttp2 )
make -j$PARALLEL_JOBS  -C $BUILD_DIR/curl-7.64.1
make -j$PARALLEL_JOBS DESTDIR=$TOOLS_DIR/$CONFIG_TARGET/sysroot install -C $BUILD_DIR/curl-7.64.1
make -j$PARALLEL_JOBS DESTDIR=$ROOTFS_DIR install -C $BUILD_DIR/curl-7.64.1
rm -rf $BUILD_DIR/curl-7.64.1

step "host-libtool 2.4.6"
extract $SOURCES_DIR/libtool-2.4.6.tar.xz $BUILD_DIR
find $BUILD_DIR/libtool-2.4.6 -name aclocal.m4 -exec touch '{}' \;
find $BUILD_DIR/libtool-2.4.6 -name config-h.in -exec touch '{}' \;
find $BUILD_DIR/libtool-2.4.6 -name configure -exec touch '{}' \;
find $BUILD_DIR/libtool-2.4.6 -name Makefile.in -exec touch '{}' \;
( cd $BUILD_DIR/libtool-2.4.6 && \
PKG_CONFIG="$TOOLS_DIR/bin/pkg-config" \
PKG_CONFIG_SYSROOT_DIR="/" \
PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 \
PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 \
PKG_CONFIG_LIBDIR="$TOOLS_DIR/lib/pkgconfig:$TOOLS_DIR/share/pkgconfig" \
CPPFLAGS="-I$TOOLS_DIR/include" \
CFLAGS="-O2 -I$TOOLS_DIR/include" \
CXXFLAGS="-O2 -I$TOOLS_DIR/include" \
LDFLAGS="-L$TOOLS_DIR/lib -Wl,-rpath,$TOOLS_DIR/lib" \
INTLTOOL_PERL=/usr/bin/perl \
CFLAGS="-O2 -I$TOOLS_DIR/include" \
LDFLAGS="-L$TOOLS_DIR/lib -Wl,-rpath,$TOOLS_DIR/lib" \
MAKEINFO=true \
CONFIG_SITE=/dev/null \
./configure \
--prefix=$TOOLS_DIR \
--enable-shared \
--disable-static )
PKG_CONFIG="$TOOLS_DIR/bin/pkg-config" PKG_CONFIG_SYSROOT_DIR="/" PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 PKG_CONFIG_LIBDIR="$TOOLS_DIR/lib/pkgconfig:$TOOLS_DIR/share/pkgconfig" make -j$PARALLEL_JOBS -C $BUILD_DIR/libtool-2.4.6
PKG_CONFIG="$TOOLS_DIR/bin/pkg-config" PKG_CONFIG_SYSROOT_DIR="/" PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 PKG_CONFIG_LIBDIR="$TOOLS_DIR/lib/pkgconfig:$TOOLS_DIR/share/pkgconfig" make -j$PARALLEL_JOBS install -C $BUILD_DIR/libtool-2.4.6
rm -rf $BUILD_DIR/libtool-2.4.6

step "host-autoconf 2.69"
extract $SOURCES_DIR/autoconf-2.69.tar.xz $BUILD_DIR
( cd $BUILD_DIR/autoconf-2.69 && \
PKG_CONFIG="$TOOLS_DIR/bin/pkg-config" \
PKG_CONFIG_SYSROOT_DIR="/" \
PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 \
PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 \
PKG_CONFIG_LIBDIR="$TOOLS_DIR/lib/pkgconfig:$TOOLS_DIR/share/pkgconfig" \
CPPFLAGS="-I$TOOLS_DIR/include" \
CFLAGS="-O2 -I$TOOLS_DIR/include" \
CXXFLAGS="-O2 -I$TOOLS_DIR/include" \
LDFLAGS="-L$TOOLS_DIR/lib -Wl,-rpath,$TOOLS_DIR/lib" \
INTLTOOL_PERL=/usr/bin/perl \
CFLAGS="-O2 -I$TOOLS_DIR/include" \
LDFLAGS="-L$TOOLS_DIR/lib -Wl,-rpath,$TOOLS_DIR/lib" \
EMACS="no" \
ac_cv_path_M4=$TOOLS_DIR/bin/m4 \
ac_cv_prog_gnu_m4_gnu=no \
CONFIG_SITE=/dev/null \
./configure \
--prefix=$TOOLS_DIR \
--enable-shared \
--disable-static )
PKG_CONFIG="$TOOLS_DIR/bin/pkg-config" PKG_CONFIG_SYSROOT_DIR="/" PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 PKG_CONFIG_LIBDIR="$TOOLS_DIR/lib/pkgconfig:$TOOLS_DIR/share/pkgconfig" make -j$PARALLEL_JOBS -C $BUILD_DIR/autoconf-2.69
PKG_CONFIG="$TOOLS_DIR/bin/pkg-config" PKG_CONFIG_SYSROOT_DIR="/" PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 PKG_CONFIG_LIBDIR="$TOOLS_DIR/lib/pkgconfig:$TOOLS_DIR/share/pkgconfig" make -j$PARALLEL_JOBS install -C $BUILD_DIR/autoconf-2.69
rm -rf $BUILD_DIR/autoconf-2.69

step "host-automake 1.15.1"
extract $SOURCES_DIR/automake-1.15.1.tar.xz $BUILD_DIR
(cd $BUILD_DIR/automake-1.15.1/ && \
PKG_CONFIG="$TOOLS_DIR/bin/pkg-config" \
PKG_CONFIG_SYSROOT_DIR="/" \
PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 \
PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 \
PKG_CONFIG_LIBDIR="$TOOLS_DIR/lib/pkgconfig:$TOOLS_DIR/share/pkgconfig" \
CPPFLAGS="-I$TOOLS_DIR/include" \
CFLAGS="-O2 -I$TOOLS_DIR/include" \
CXXFLAGS="-O2 -I$TOOLS_DIR/include" \
LDFLAGS="-L$TOOLS_DIR/lib -Wl,-rpath,$TOOLS_DIR/lib" \
INTLTOOL_PERL=/usr/bin/perl \
CFLAGS="-O2 -I$TOOLS_DIR/include" \
LDFLAGS="-L$TOOLS_DIR/lib -Wl,-rpath,$TOOLS_DIR/lib" \
CONFIG_SITE=/dev/null \
./configure \
--prefix=$TOOLS_DIR \
--enable-shared \
--disable-static )
PKG_CONFIG="$TOOLS_DIR/bin/pkg-config" PKG_CONFIG_SYSROOT_DIR="/" PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 PKG_CONFIG_LIBDIR="$TOOLS_DIR/lib/pkgconfig:$TOOLS_DIR/share/pkgconfig" make -j$PARALLEL_JOBS -C $BUILD_DIR/automake-1.15.1
PKG_CONFIG="$TOOLS_DIR/bin/pkg-config" PKG_CONFIG_SYSROOT_DIR="/" PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 PKG_CONFIG_LIBDIR="$TOOLS_DIR/lib/pkgconfig:$TOOLS_DIR/share/pkgconfig" make -j$PARALLEL_JOBS install -C $BUILD_DIR/automake-1.15.1
rm -rf $BUILD_DIR/automake-1.15.1

step "libevent 2.1.8"
extract $SOURCES_DIR/libevent-2.1.8-stable.tar.gz $BUILD_DIR
(cd $BUILD_DIR/libevent-2.1.8-stable && \
CC="$TOOLS_DIR/bin/$CONFIG_TARGET-gcc" \
CXX="$TOOLS_DIR/bin/$CONFIG_TARGET-g++" \
AR="$TOOLS_DIR/bin/$CONFIG_TARGET-ar" \
AS="$TOOLS_DIR/bin/$CONFIG_TARGET-as" \
LD="$TOOLS_DIR/bin/$CONFIG_TARGET-ld" \
RANLIB="$TOOLS_DIR/bin/$CONFIG_TARGET-ranlib" \
READELF="$TOOLS_DIR/bin/$CONFIG_TARGET-readelf" \
STRIP="$TOOLS_DIR/bin/$CONFIG_TARGET-strip" \
OBJCOPY="$TOOLS_DIR/bin/$CONFIG_TARGET-objcopy" \
OBJDUMP="$TOOLS_DIR/bin/$CONFIG_TARGET-objdump" \
CPPFLAGS="-D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64" \
CFLAGS="-D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64 -Os" \
CXXFLAGS="-D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64 -Os" \
LDFLAGS="" \
PKG_CONFIG="$TOOLS_DIR/bin/pkg-config" \
STAGING_DIR="$TOOLS_DIR/$CONFIG_TARGET/sysroot" \
INTLTOOL_PERL=/usr/bin/perl \
CXX=no \
CONFIG_SITE=/dev/null \
./configure \
--target=$CONFIG_TARGET \
--host=$CONFIG_TARGET \
--build=x86_64-pc-linux-gnu \
--prefix=/usr \
--exec-prefix=/usr \
--sysconfdir=/etc \
--localstatedir=/var \
--program-prefix="" \
--disable-static \
--enable-shared \
--disable-samples \
--enable-openssl )
make -j$PARALLEL_JOBS -C $BUILD_DIR/libevent-2.1.8-stable/
make -j$PARALLEL_JOBS DESTDIR=$TOOLS_DIR/$CONFIG_TARGET/sysroot install -C $BUILD_DIR/libevent-2.1.8-stable/
make -j$PARALLEL_JOBS DESTDIR=$ROOTFS_DIR install -C $BUILD_DIR/libevent-2.1.8-stable/
rm -rf $BUILD_DIR/libevent-2.1.8-stable

step "openssh 7.9p1"
extract $SOURCES_DIR/openssh-7.9p1.tar.gz $BUILD_DIR
(cd $BUILD_DIR/openssh-7.9p1/ && \
CC="$TOOLS_DIR/bin/$CONFIG_TARGET-gcc" \
CXX="$TOOLS_DIR/bin/$CONFIG_TARGET-g++" \
AR="$TOOLS_DIR/bin/$CONFIG_TARGET-ar" \
AS="$TOOLS_DIR/bin/$CONFIG_TARGET-as" \
LD="$TOOLS_DIR/bin/$CONFIG_TARGET-ld" \
RANLIB="$TOOLS_DIR/bin/$CONFIG_TARGET-ranlib" \
READELF="$TOOLS_DIR/bin/$CONFIG_TARGET-readelf" \
STRIP="$TOOLS_DIR/bin/$CONFIG_TARGET-strip" \
OBJCOPY="$TOOLS_DIR/bin/$CONFIG_TARGET-objcopy" \
OBJDUMP="$TOOLS_DIR/bin/$CONFIG_TARGET-objdump" \
CPPFLAGS="-D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64" \
CFLAGS="-D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64 -Os" \
CXXFLAGS="-D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64 -Os" \
LDFLAGS="" \
PKG_CONFIG="$TOOLS_DIR/bin/pkg-config" \
STAGING_DIR="$TOOLS_DIR/$CONFIG_TARGET/sysroot" \
INTLTOOL_PERL=/usr/bin/perl \
CXX=no \
CONFIG_SITE=/dev/null \
./configure \
--target=$CONFIG_TARGET \
--host=$CONFIG_TARGET \
--build=x86_64-pc-linux-gnu \
--prefix=/usr \
--exec-prefix=/usr \
--sysconfdir=/etc \
--localstatedir=/var \
--program-prefix="" \
--disable-static \
--enable-shared \
--sysconfdir=/etc/ssh \
--with-default-path="/bin:/sbin:/usr/bin:/usr/sbin" \
--disable-lastlog \
--disable-utmp \
--disable-utmpx \
--disable-wtmp \
--disable-wtmpx \
--disable-strip \
--without-ssl-engine \
--without-pam \
--without-selinux )
make -j$PARALLEL_JOBS  -C $BUILD_DIR/openssh-7.9p1/
make -j$PARALLEL_JOBS DESTDIR=$ROOTFS_DIR install -C $BUILD_DIR/openssh-7.9p1/
install -D -m 755 $PACKAGES_DIR/openssh/S50sshd $ROOTFS_DIR/etc/init.d/S50sshd
install -D -m 755 $BUILD_DIR/openssh-7.9p1/contrib/ssh-copy-id $ROOTFS_DIR/usr/bin/ssh-copy-id
rm -rf $BUILD_DIR/openssh-7.9p1

# step "transmission 2.94"
# extract $SOURCES_DIR/transmission-2.94.tar.xz $BUILD_DIR
# (cd $BUILD_DIR/transmission-2.94 && \
# CC="$TOOLS_DIR/bin/$CONFIG_TARGET-gcc" \
# CXX="$TOOLS_DIR/bin/$CONFIG_TARGET-g++" \
# AR="$TOOLS_DIR/bin/$CONFIG_TARGET-ar" \
# AS="$TOOLS_DIR/bin/$CONFIG_TARGET-as" \
# LD="$TOOLS_DIR/bin/$CONFIG_TARGET-ld" \
# RANLIB="$TOOLS_DIR/bin/$CONFIG_TARGET-ranlib" \
# READELF="$TOOLS_DIR/bin/$CONFIG_TARGET-readelf" \
# STRIP="$TOOLS_DIR/bin/$CONFIG_TARGET-strip" \
# OBJCOPY="$TOOLS_DIR/bin/$CONFIG_TARGET-objcopy" \
# OBJDUMP="$TOOLS_DIR/bin/$CONFIG_TARGET-objdump" \
# CPPFLAGS="-D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64" \
# CFLAGS="-D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64 -Os" \
# CXXFLAGS="-D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64 -Os" \
# LDFLAGS="" \
# PKG_CONFIG="$TOOLS_DIR/bin/pkg-config" \
# STAGING_DIR="$TOOLS_DIR/$CONFIG_TARGET/sysroot" \
# INTLTOOL_PERL=/usr/bin/perl \
# CXX=no \
# CONFIG_SITE=/dev/null \
# ./configure \
# --target=$CONFIG_TARGET \
# --host=$CONFIG_TARGET \
# --build=x86_64-pc-linux-gnu \
# --prefix=/usr \
# --exec-prefix=/usr \
# --sysconfdir=/etc \
# --localstatedir=/var \
# --program-prefix="" \
# --disable-static \
# --enable-shared \
# --without-inotify \
# --enable-lightweight \
# --disable-external-natpmp \
# --disable-utp \
# --disable-cli \
# --enable-daemon \
# --without-systemd \
# --without-gtk )
# make -j$PARALLEL_JOBS -C $BUILD_DIR/transmission-2.94/
# make -j$PARALLEL_JOBS DESTDIR=$ROOTFS_DIR install -C $BUILD_DIR/transmission-2.94/
# rm -rf $BUILD_DIR/transmission-2.94

step "vsftpd 3.0.3"
extract $SOURCES_DIR/vsftpd-3.0.3.tar.gz $BUILD_DIR
sed -i -e 's/.*VSF_BUILD_SSL/#define VSF_BUILD_SSL/' $BUILD_DIR/vsftpd-3.0.3/builddefs.h
make -j$PARALLEL_JOBS CC="$TOOLS_DIR/bin/$CONFIG_TARGET-gcc" CFLAGS="-D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64 -Os" LDFLAGS="" LIBS="-lcrypt `$TOOLS_DIR/bin/pkg-config --libs libssl libcrypto`" -C $BUILD_DIR/vsftpd-3.0.3
install -D -m 755 $BUILD_DIR/vsftpd-3.0.3/vsftpd $ROOTFS_DIR/usr/sbin/vsftpd
test -f $ROOTFS_DIR/etc/vsftpd.conf || install -D -m 644 $BUILD_DIR/vsftpd-3.0.3/vsftpd.conf $ROOTFS_DIR/etc/vsftpd.conf
install -d -m 700 $ROOTFS_DIR/usr/share/empty
install -d -m 555 $ROOTFS_DIR/home/ftp
install -D -m 755 $PACKAGES_DIR/vsftpd/S70vsftpd $ROOTFS_DIR/etc/init.d/S70vsftpd
rm -rf $BUILD_DIR/vsftpd-3.0.3

step "host-flex 2.6.3"
extract $SOURCES_DIR/flex-2.6.3.tar.gz $BUILD_DIR
(cd $BUILD_DIR/flex-2.6.3/ && \
PKG_CONFIG="$TOOLS_DIR/bin/pkg-config" \
PKG_CONFIG_SYSROOT_DIR="/" \
PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 \
PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 \
PKG_CONFIG_LIBDIR="$TOOLS_DIR/lib/pkgconfig:$TOOLS_DIR/share/pkgconfig" \
CPPFLAGS="-I$TOOLS_DIR/include" \
CFLAGS="-O2 -I$TOOLS_DIR/include" \
CXXFLAGS="-O2 -I$TOOLS_DIR/include" \
LDFLAGS="-L$TOOLS_DIR/lib -Wl,-rpath,$TOOLS_DIR/lib" \
INTLTOOL_PERL=/usr/bin/perl \
CFLAGS="-O2 -I$TOOLS_DIR/include" \
LDFLAGS="-L$TOOLS_DIR/lib -Wl,-rpath,$TOOLS_DIR/lib" \
CONFIG_SITE=/dev/null \
./configure \
--prefix=$TOOLS_DIR \
--enable-shared \
--disable-static \
--disable-doc )
PKG_CONFIG="$TOOLS_DIR/bin/pkg-config" PKG_CONFIG_SYSROOT_DIR="/" PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 PKG_CONFIG_LIBDIR="$TOOLS_DIR/lib/pkgconfig:$TOOLS_DIR/share/pkgconfig" make -j$PARALLEL_JOBS -C $BUILD_DIR/flex-2.6.3
PKG_CONFIG="$TOOLS_DIR/bin/pkg-config" PKG_CONFIG_SYSROOT_DIR="/" PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 PKG_CONFIG_LIBDIR="$TOOLS_DIR/lib/pkgconfig:$TOOLS_DIR/share/pkgconfig" make -j$PARALLEL_JOBS install -C $BUILD_DIR/flex-2.6.3
rm -rf $BUILD_DIR/flex-2.6.3

step "host-kmod 25"
extract $SOURCES_DIR/kmod-25.tar.xz $BUILD_DIR
(cd $BUILD_DIR/kmod-25/ && \
PKG_CONFIG="$TOOLS_DIR/bin/pkg-config" \
PKG_CONFIG_SYSROOT_DIR="/" \
PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 \
PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 \
PKG_CONFIG_LIBDIR="$TOOLS_DIR/lib/pkgconfig:$TOOLS_DIR/share/pkgconfig" \
CPPFLAGS="-I$TOOLS_DIR/include" \
CFLAGS="-O2 -I$TOOLS_DIR/include" \
CXXFLAGS="-O2 -I$TOOLS_DIR/include" \
LDFLAGS="-L$TOOLS_DIR/lib -Wl,-rpath,$TOOLS_DIR/lib" \
INTLTOOL_PERL=/usr/bin/perl \
CFLAGS="-O2 -I$TOOLS_DIR/include" \
LDFLAGS="-L$TOOLS_DIR/lib -Wl,-rpath,$TOOLS_DIR/lib" \
CONFIG_SITE=/dev/null \
./configure \
--prefix=$TOOLS_DIR \
--enable-shared \
--disable-static \
--disable-manpages )
PKG_CONFIG="$TOOLS_DIR/bin/pkg-config" PKG_CONFIG_SYSROOT_DIR="/" PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 PKG_CONFIG_LIBDIR="$TOOLS_DIR/lib/pkgconfig:$TOOLS_DIR/share/pkgconfig" make -j$PARALLEL_JOBS -C $BUILD_DIR/kmod-25/
PKG_CONFIG="$TOOLS_DIR/bin/pkg-config" PKG_CONFIG_SYSROOT_DIR="/" PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 PKG_CONFIG_LIBDIR="$TOOLS_DIR/lib/pkgconfig:$TOOLS_DIR/share/pkgconfig" make -j$PARALLEL_JOBS install -C $BUILD_DIR/kmod-25
rm -rf $BUILD_DIR/kmod-25
mkdir -p $TOOLS_DIR/sbin/
ln -sf ../bin/kmod $TOOLS_DIR/sbin/depmod

step "linux-headers 4.19.16"
extract $SOURCES_DIR/linux-4.19.16.tar.xz $BUILD_DIR
make -j$PARALLEL_JOBS ARCH=x86_64 mrproper -C $BUILD_DIR/linux-4.19.16
make -j$PARALLEL_JOBS ARCH=x86_64 x86_64_defconfig -C $BUILD_DIR/linux-4.19.16
# Step 1 - disable all active kernel compression options (should be only one).
sed -i "s/.*CONFIG_DEFAULT_HOSTNAME.*/CONFIG_DEFAULT_HOSTNAME=\""$CONFIG_HOSTNAME"\"/" $BUILD_DIR/linux-4.19.16/.config
# Step 1 - disable all active kernel compression options (should be only one).
sed -i "s/.*\\(CONFIG_KERNEL_.*\\)=y/\\#\\ \\1 is not set/" $BUILD_DIR/linux-4.19.16/.config
# Step 2 - enable the 'xz' compression option.
sed -i "s/.*CONFIG_KERNEL_XZ.*/CONFIG_KERNEL_XZ=y/" $BUILD_DIR/linux-4.19.16/.config
# Enable the VESA framebuffer for graphics support.
sed -i "s/.*CONFIG_FB_VESA.*/CONFIG_FB_VESA=y/" $BUILD_DIR/linux-4.19.16/.config
# Disable debug symbols in kernel => smaller kernel binary.
sed -i "s/^CONFIG_DEBUG_KERNEL.*/\\# CONFIG_DEBUG_KERNEL is not set/" $BUILD_DIR/linux-4.19.16/.config
# Enable the EFI stub
sed -i "s/.*CONFIG_EFI_STUB.*/CONFIG_EFI_STUB=y/" $BUILD_DIR/linux-4.19.16/.config
# Request that the firmware clear the contents of RAM after reboot (4.14+).
echo "CONFIG_RESET_ATTACK_MITIGATION=y" >> $BUILD_DIR/linux-4.19.16/.config
# Disable Apple Properties (Useful for Macs but useless in general)
echo "CONFIG_APPLE_PROPERTIES=n" >> $BUILD_DIR/linux-4.19.16/.config
# Enable the mixed EFI mode when building 64-bit kernel.
echo "CONFIG_EFI_MIXED=y" >> $BUILD_DIR/linux-4.19.16/.config
make -j$PARALLEL_JOBS ARCH=x86_64 CROSS_COMPILE="$TOOLS_DIR/bin/$CONFIG_TARGET-" -C $BUILD_DIR/linux-4.19.16 bzImage
cp $BUILD_DIR/linux-4.19.16/arch/x86/boot/bzImage $OUTPUT_DIR/bzImage
rm -rf $BUILD_DIR/linux-4.19.16

step "copy gcc lib"
cp -v $TOOLS_DIR/$CONFIG_TARGET/lib64/libgcc_s* $TOOLS_DIR/$CONFIG_TARGET/sysroot/lib/
cp -v $TOOLS_DIR/$CONFIG_TARGET/lib64/libgcc_s* $ROOTFS_DIR/lib/
cp -v $TOOLS_DIR/$CONFIG_TARGET/lib64/libatomic* $TOOLS_DIR/$CONFIG_TARGET/sysroot/lib/
cp -v $TOOLS_DIR/$CONFIG_TARGET/lib64/libatomic* $ROOTFS_DIR/lib/

step "Finalizing target directory"
sed -i -e '/# GENERIC_SERIAL$/s~^.*#~tty1::respawn:/sbin/getty -L  tty1 0 vt100 #~' $ROOTFS_DIR/etc/inittab
sed -i -e '/^#.*-o remount,rw \/$/s~^#\+~~' $ROOTFS_DIR/etc/inittab
# if grep -q CONFIG_ASH=y ./.config; then grep -qsE '^/bin/ash$' $ROOTFS_DIR/etc/shells || echo "/bin/ash" >> $ROOTFS_DIR/etc/shells; fi
# if grep -q CONFIG_HUSH=y ./.config; then grep -qsE '^/bin/hush$' $ROOTFS_DIR/etc/shells || echo "/bin/hush" >> $ROOTFS_DIR/etc/shells; fi
# mkdir -p $TOOLS_DIR/etc/meson
# sed -e "s%@TARGET_CROSS@%$TOOLS_DIR/bin/$CONFIG_TARGET-%g" -e "s%@TARGET_ARCH@%x86_64%g" -e "s%@TARGET_CPU@%%g" -e "s%@TARGET_ENDIAN@%"little"%g" -e "s%@TARGET_CFLAGS@%`printf '"%s", ' -D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64  -Os  `%g" -e "s%@TARGET_LDFLAGS@%%g" -e "s%@TARGET_CXXFLAGS@%`printf '"%s", ' -D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64  -Os  `%g" -e "s%@HOST_DIR@%$TOOLS_DIR%g" package/meson//cross-compilation.conf.in > $TOOLS_DIR/etc/meson/cross-compilation.conf
mkdir -p $ROOTFS_DIR/etc
echo "qnas" > $ROOTFS_DIR/etc/hostname
/bin/sed -i -e '$a \127.0.1.1\tqnas' -e '/^127.0.1.1/d' $ROOTFS_DIR/etc/hosts
mkdir -p $ROOTFS_DIR/etc
echo "Welcome to QNAS" > $ROOTFS_DIR/etc/issue
sed -i -e s,^root:[^:]*:,root:"`$TOOLS_DIR/bin/mkpasswd -m "sha-512" "1111"`":, $ROOTFS_DIR/etc/shadow
grep -qsE '^/bin/sh$' $ROOTFS_DIR/etc/shells || echo "/bin/sh" >> $ROOTFS_DIR/etc/shells
mkdir -p $ROOTFS_DIR/etc
( \
	echo "NAME=QNAS"; \
	echo "VERSION=2019.02.1"; \
	echo "ID=QNAS"; \
	echo "VERSION_ID=2019.02.1"; \
	echo "PRETTY_NAME=\"QNAS 2019.02.1\"" \
) >  $ROOTFS_DIR/usr/lib/os-release
ln -sf ../usr/lib/os-release $ROOTFS_DIR/etc

step "Generating filesystem image rootfs.ext2"
step "Copy QNAS system image"
rm -rf $OUTPUT_DIR/rootfs.ext2
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
echo "$TOOLS_DIR/sbin/mkfs.ext2 -d $ROOTFS_DIR $OUTPUT_DIR/rootfs.ext2 250M" >> $BUILD_DIR/_fakeroot.fs
chmod a+x $BUILD_DIR/_fakeroot.fs
fakeroot -- $BUILD_DIR/_fakeroot.fs

do_strip

echo -e "----------------------------------------------------"
echo -e "\nYou made it! This is the end of chapter 5!"
printf 'Total script time: %s\n' $(timer $total_time)
echo -e "Now continue reading from \"5.36. Changing Ownership\""

#!/bin/bash
#
# QNAS toolchain build script
# Optional parameteres below:
set +h
set -o nounset
set -o errexit
umask 022

export CFLAGS="-O2 -I$TOOLS_DIR/include"
export CPPFLAGS="-O2 -I$TOOLS_DIR/include"
export CXXFLAGS="-O2 -I$TOOLS_DIR/include"
export LDFLAGS="-L$TOOLS_DIR/lib -Wl,-rpath,$TOOLS_DIR/lib"

export LC_ALL=POSIX
export CONFIG_HOST=`echo ${MACHTYPE} | sed -e 's/-[^-]*/-cross/'`

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
}

function check_tarballs {
  LIST_OF_TARBALLS="
  binutils-2.32.tar.xz
  confuse-3.2.2.tar.xz
  dosfstools-4.1.tar.xz
  gcc-8.3.0.tar.xz
  genimage-10.tar.xz
  gmp-6.1.2.tar.xz
  linux-4.20.12.tar.xz
  mpc-1.1.0.tar.gz
  mpfr-4.0.1.tar.xz
  mtools-4.0.21.tar.bz2
  musl-1.1.21.tar.gz
  pkg-config-0.29.2.tar.gz
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
    strip --strip-debug $TOOLS_DIR/lib/*
    strip --strip-unneeded $TOOLS_DIR/{,s}bin/*
    rm -rf $TOOLS_DIR/{,share}/{info,man,doc}
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

step "[1/12] Create toolchain directory."
rm -rf $BUILD_DIR $TOOLS_DIR
mkdir -pv $BUILD_DIR $TOOLS_DIR
ln -svf . $TOOLS_DIR/usr

step "[2/12] Create the sysroot directory"
mkdir -pv $SYSROOT_DIR
ln -svf . $SYSROOT_DIR/usr
if [[ "$CONFIG_LINUX_ARCH" = "i386" ]] ; then
  ln -snvf lib $SYSROOT_DIR/lib32
fi
if [[ "$CONFIG_LINUX_ARCH" = "x86_64" ]] ; then
  ln -snvf lib $SYSROOT_DIR/lib64
fi

step "[3/12] Linux 4.20.12 API Headers"
extract $SOURCES_DIR/linux-4.20.12.tar.xz $BUILD_DIR
make -j$PARALLEL_JOBS ARCH=$CONFIG_LINUX_ARCH mrproper -C $BUILD_DIR/linux-4.20.12
make -j$PARALLEL_JOBS ARCH=$CONFIG_LINUX_ARCH headers_check -C $BUILD_DIR/linux-4.20.12
make -j$PARALLEL_JOBS ARCH=$CONFIG_LINUX_ARCH INSTALL_HDR_PATH=$SYSROOT_DIR headers_install -C $BUILD_DIR/linux-4.20.12
rm -rf $BUILD_DIR/linux-4.20.12

step "[4/12] Binutils 2.29.1"
extract $SOURCES_DIR/binutils-2.32.tar.xz $BUILD_DIR
mkdir -pv $BUILD_DIR/binutils-2.32/binutils-build
( cd $BUILD_DIR/binutils-2.32/binutils-build && \
$BUILD_DIR/binutils-2.32/configure \
--prefix=$TOOLS_DIR \
--target=$CONFIG_TARGET \
--with-sysroot=$SYSROOT_DIR \
--disable-nls \
--disable-multilib )
make -j$PARALLEL_JOBS configure-host -C $BUILD_DIR/binutils-2.32/binutils-build
make -j$PARALLEL_JOBS -C $BUILD_DIR/binutils-2.32/binutils-build
make -j$PARALLEL_JOBS install -C $BUILD_DIR/binutils-2.32/binutils-build
rm -rf $BUILD_DIR/binutils-2.32

step "[5/12] Gcc 8.3.0 - Static"
tar -Jxf $SOURCES_DIR/gcc-8.3.0.tar.xz -C $BUILD_DIR
extract $SOURCES_DIR/gmp-6.1.2.tar.xz $BUILD_DIR/gcc-8.3.0
mv -v $BUILD_DIR/gcc-8.3.0/gmp-6.1.2 $BUILD_DIR/gcc-8.3.0/gmp
extract $SOURCES_DIR/mpfr-4.0.1.tar.xz $BUILD_DIR/gcc-8.3.0
mv -v $BUILD_DIR/gcc-8.3.0/mpfr-4.0.1 $BUILD_DIR/gcc-8.3.0/mpfr
extract $SOURCES_DIR/mpc-1.1.0.tar.gz $BUILD_DIR/gcc-8.3.0
mv -v $BUILD_DIR/gcc-8.3.0/mpc-1.1.0 $BUILD_DIR/gcc-8.3.0/mpc
mkdir -pv $BUILD_DIR/gcc-8.3.0/gcc-build
( cd $BUILD_DIR/gcc-8.3.0/gcc-build && \
  $BUILD_DIR/gcc-8.3.0/configure \
  --prefix=$TOOLS_DIR \
  --build=$CONFIG_HOST \
  --host=$CONFIG_HOST \
  --target=$CONFIG_TARGET \
  --with-sysroot=$SYSROOT_DIR \
  --disable-nls  \
  --disable-shared \
  --without-headers \
  --with-newlib \
  --disable-decimal-float \
  --disable-libgomp \
  --disable-libmudflap \
  --disable-libssp \
  --disable-libatomic \
  --disable-libquadmath \
  --disable-threads \
  --enable-languages=c \
  --disable-multilib \
  --with-arch="x86-64" \
  --with-pkgversion="$CONFIG_PKG_VERSION" \
  --with-bugurl="$CONFIG_BUG_URL" )
make -j$PARALLEL_JOBS all-gcc all-target-libgcc -C $BUILD_DIR/gcc-8.3.0/gcc-build
make -j$PARALLEL_JOBS install-gcc install-target-libgcc -C $BUILD_DIR/gcc-8.3.0/gcc-build
rm -rf $BUILD_DIR/gcc-8.3.0

step "[6/12] Musl 1.1.21"
extract $SOURCES_DIR/musl-1.1.21.tar.gz $BUILD_DIR
( cd $BUILD_DIR/musl-1.1.21 && \
  ./configure \
  CROSS_COMPILE="$TOOLS_DIR/bin/$CONFIG_TARGET-" \
  --prefix=/ \
  --target=$CONFIG_TARGET )
make -j$PARALLEL_JOBS -C $BUILD_DIR/musl-1.1.21
DESTDIR=$SYSROOT_DIR make -j$PARALLEL_JOBS install -C $BUILD_DIR/musl-1.1.21
rm -rf $BUILD_DIR/musl-1.1.21

step "[7/12] Gcc 8.3.0 - Final"
tar -Jxf $SOURCES_DIR/gcc-8.3.0.tar.xz -C $BUILD_DIR
extract $SOURCES_DIR/gmp-6.1.2.tar.xz $BUILD_DIR/gcc-8.3.0
mv -v $BUILD_DIR/gcc-8.3.0/gmp-6.1.2 $BUILD_DIR/gcc-8.3.0/gmp
extract $SOURCES_DIR/mpfr-4.0.1.tar.xz $BUILD_DIR/gcc-8.3.0
mv -v $BUILD_DIR/gcc-8.3.0/mpfr-4.0.1 $BUILD_DIR/gcc-8.3.0/mpfr
extract $SOURCES_DIR/mpc-1.1.0.tar.gz $BUILD_DIR/gcc-8.3.0
mv -v $BUILD_DIR/gcc-8.3.0/mpc-1.1.0 $BUILD_DIR/gcc-8.3.0/mpc
mkdir -v $BUILD_DIR/gcc-8.3.0/gcc-build
( cd $BUILD_DIR/gcc-8.3.0/gcc-build && \
  $BUILD_DIR/gcc-8.3.0/configure \
  --prefix=$TOOLS_DIR \
  --build=$CONFIG_HOST \
  --host=$CONFIG_HOST \
  --target=$CONFIG_TARGET \
  --with-sysroot=$SYSROOT_DIR \
  --disable-nls \
  --enable-languages=c \
  --enable-c99 \
  --enable-long-long \
  --disable-libmudflap \
  --disable-multilib \
  --with-arch="x86-64" \
  --with-pkgversion="$CONFIG_PKG_VERSION" \
  --with-bugurl="$CONFIG_BUG_URL" )
make -j$PARALLEL_JOBS -C $BUILD_DIR/gcc-8.3.0/gcc-build
make -j$PARALLEL_JOBS install -C $BUILD_DIR/gcc-8.3.0/gcc-build
if [ ! -e $TOOLS_DIR/bin/$CONFIG_TARGET-cc ]; then
  ln -vf $TOOLS_DIR/bin/$CONFIG_TARGET-gcc $TOOLS_DIR/bin/$CONFIG_TARGET-cc
fi
rm -rf $BUILD_DIR/gcc-8.3.0

step "[8/12] Pkg-config 0.29.2"
extract $SOURCES_DIR/pkg-config-0.29.2.tar.gz $BUILD_DIR
( cd $BUILD_DIR/pkg-config-0.29.2 && \
./configure \
--prefix=$TOOLS_DIR \
--with-internal-glib \
--disable-host-tool )
make -j$PARALLEL_JOBS -C $BUILD_DIR/pkg-config-0.29.2
make -j$PARALLEL_JOBS install -C $BUILD_DIR/pkg-config-0.29.2
rm -rf $BUILD_DIR/pkg-config-0.29.2

step "[9/12] Dosfstools 4.1"
extract $SOURCES_DIR/dosfstools-4.1.tar.xz $BUILD_DIR
( cd $BUILD_DIR/dosfstools-4.1 && \
./configure \
--prefix=$TOOLS_DIR \
--enable-shared \
--disable-static \
--enable-compat-symlinks )
make -j$PARALLEL_JOBS -C $BUILD_DIR/dosfstools-4.1
make -j$PARALLEL_JOBS install -C $BUILD_DIR/dosfstools-4.1
rm -rf $BUILD_DIR/dosfstools-4.1

step "[10/12] Mtools 4.0.21"
extract $SOURCES_DIR/mtools-4.0.21.tar.bz2 $BUILD_DIR
( cd $BUILD_DIR/mtools-4.0.21 && \
./configure \
--prefix=$TOOLS_DIR \
--enable-shared \
--disable-static )
make -j$PARALLEL_JOBS -C $BUILD_DIR/mtools-4.0.21
make -j$PARALLEL_JOBS install -C $BUILD_DIR/mtools-4.0.21
rm -rf $BUILD_DIR/mtools-4.0.21

step "[11/12] libconfuse 3.2.2"
extract $SOURCES_DIR/confuse-3.2.2.tar.xz $BUILD_DIR
( cd $BUILD_DIR/confuse-3.2.2 && \
./configure \
--prefix=$TOOLS_DIR \
--enable-shared \
--disable-static )
make -j$PARALLEL_JOBS -C $BUILD_DIR/confuse-3.2.2
make -j$PARALLEL_JOBS install -C $BUILD_DIR/confuse-3.2.2
rm -rf $BUILD_DIR/confuse-3.2.2

step "[12/12] Genimage 10"
extract $SOURCES_DIR/genimage-10.tar.xz $BUILD_DIR
( cd $BUILD_DIR/genimage-10 && \
./configure \
--prefix=$TOOLS_DIR \
--enable-shared \
--disable-static )
make -j$PARALLEL_JOBS -C $BUILD_DIR/genimage-10
make -j$PARALLEL_JOBS install -C $BUILD_DIR/genimage-10
rm -rf $BUILD_DIR/genimage-10

do_strip

success "\nTotal toolchain build time: $(timer $total_build_time)\n"

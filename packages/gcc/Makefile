toolchain-initial:
	$(STEP) "host-gcc-initial 8.3.0"
	$(EXTRACT) $(SOURCES_DIR)/gcc-8.3.0.tar.xz $(BUILD_DIR)
	mkdir -p $(BUILD_DIR)/gcc-8.3.0/build
	( cd $(BUILD_DIR)/gcc-8.3.0/build && \
	PKG_CONFIG="$(TOOLS_DIR)/bin/pkg-config" \
	PKG_CONFIG_SYSROOT_DIR="/" \
	PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 \
	PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 \
	PKG_CONFIG_LIBDIR="$(TOOLS_DIR)/lib/pkgconfig:$(TOOLS_DIR)/share/pkgconfig" \
	CPPFLAGS="-I$(TOOLS_DIR)/include" \
	CFLAGS="-O2 -I$(TOOLS_DIR)/include" \
	CXXFLAGS="-O2 -I$(TOOLS_DIR)/include" \
	LDFLAGS="-L$(TOOLS_DIR)/lib -Wl,-rpath,$(TOOLS_DIR)/lib" \
	MAKEINFO=missing \
	CFLAGS_FOR_TARGET="-D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64 -Os" \
	CXXFLAGS_FOR_TARGET="-D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64 -Os" \
	$(BUILD_DIR)/gcc-8.3.0/configure \
	--prefix=$(TOOLS_DIR) \
	--enable-shared \
	--disable-static \
	--target=$(CONFIG_TARGET) \
	--with-sysroot=$(TOOLS_DIR)/$(CONFIG_TARGET)/sysroot \
	--enable-__cxa_atexit \
	--with-gnu-ld \
	--disable-libssp \
	--disable-multilib \
	--disable-decimal-float \
	--with-gmp=$(TOOLS_DIR) \
	--with-mpc=$(TOOLS_DIR) \
	--with-mpfr=$(TOOLS_DIR) \
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
	PKG_CONFIG="$(TOOLS_DIR)/bin/pkg-config" \
	PKG_CONFIG_SYSROOT_DIR="/" \
	PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 \
	PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 \
	PKG_CONFIG_LIBDIR="$(TOOLS_DIR)/lib/pkgconfig:$(TOOLS_DIR)/share/pkgconfig" \
	$(MAKE_PARALLEL_JOBS) gcc_cv_libc_provides_ssp=yes all-gcc all-target-libgcc -C $(BUILD_DIR)/gcc-8.3.0/build
	PKG_CONFIG="$(TOOLS_DIR)/bin/pkg-config" \
	PKG_CONFIG_SYSROOT_DIR="/" \
	PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 \
	PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 \
	PKG_CONFIG_LIBDIR="$(TOOLS_DIR)/lib/pkgconfig:$(TOOLS_DIR)/share/pkgconfig" \
	$(MAKE_PARALLEL_JOBS) install-gcc install-target-libgcc -C $(BUILD_DIR)/gcc-8.3.0/build
	rm -rf $(BUILD_DIR)/gcc-8.3.0

toolchain-final:
	$(STEP) "host-gcc-final 8.3.0"
	$(EXTRACT) $(SOURCES_DIR)/gcc-8.3.0.tar.xz $(BUILD_DIR)
	mkdir -p $(BUILD_DIR)/gcc-8.3.0/build
	( cd $(BUILD_DIR)/gcc-8.3.0/build && \
	PKG_CONFIG="$(TOOLS_DIR)/bin/pkg-config" \
	PKG_CONFIG_SYSROOT_DIR="/" \
	PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 \
	PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 \
	PKG_CONFIG_LIBDIR="$(TOOLS_DIR)/lib/pkgconfig:$(TOOLS_DIR)/share/pkgconfig" \
	CPPFLAGS="-I$(TOOLS_DIR)/include" \
	CFLAGS="-O2 -I$(TOOLS_DIR)/include" \
	CXXFLAGS="-O2 -I$(TOOLS_DIR)/include" \
	LDFLAGS="-L$(TOOLS_DIR)/lib -Wl,-rpath,$(TOOLS_DIR)/lib" \
	MAKEINFO=missing \
	CFLAGS_FOR_TARGET="-D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64 -Os" \
	CXXFLAGS_FOR_TARGET="-D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64 -Os " \
	$(BUILD_DIR)/gcc-8.3.0/configure \
	--prefix=$(TOOLS_DIR) \
	--enable-static \
	--target=$(CONFIG_TARGET) \
	--with-sysroot=$(TOOLS_DIR)/$(CONFIG_TARGET)/sysroot \
	--enable-__cxa_atexit \
	--with-gnu-ld \
	--disable-libssp \
	--disable-multilib \
	--disable-decimal-float \
	--with-gmp=$(TOOLS_DIR) \
	--with-mpc=$(TOOLS_DIR) \
	--with-mpfr=$(TOOLS_DIR) \
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
	--with-build-time-tools=$(TOOLS_DIR)/$(CONFIG_TARGET)/bin \
	--enable-shared \
	--disable-libgomp )
	PKG_CONFIG="$(TOOLS_DIR)/bin/pkg-config" \
	PKG_CONFIG_SYSROOT_DIR="/" \
	PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 \
	PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 \
	PKG_CONFIG_LIBDIR="$(TOOLS_DIR)/lib/pkgconfig:$(TOOLS_DIR)/share/pkgconfig" \
	$(MAKE_PARALLEL_JOBS) gcc_cv_libc_provides_ssp=yes -C $(BUILD_DIR)/gcc-8.3.0/build
	PKG_CONFIG="$(TOOLS_DIR)/bin/pkg-config" \
	PKG_CONFIG_SYSROOT_DIR="/" \
	PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 \
	PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 \
	PKG_CONFIG_LIBDIR="$(TOOLS_DIR)/lib/pkgconfig:$(TOOLS_DIR)/share/pkgconfig" \
	$(MAKE_PARALLEL_JOBS) install -C $(BUILD_DIR)/gcc-8.3.0/build
	rm -rf $(BUILD_DIR)/gcc-8.3.0

sysroot:
	$(STEP) "glibc"
	$(EXTRACT) $(SOURCES_DIR)/glibc-2.29.tar.xz $(BUILD_DIR)
	mkdir -v $(BUILD_DIR)/glibc-2.29/build
	( cd $(BUILD_DIR)/glibc-2.29/build && \
	CC="$(TOOLS_DIR)/bin/$(CONFIG_TARGET)-gcc" \
	CXX="$(TOOLS_DIR)/bin/$(CONFIG_TARGET)-g++" \
	AR="$(TOOLS_DIR)/bin/$(CONFIG_TARGET)-ar" \
	AS="$(TOOLS_DIR)/bin/$(CONFIG_TARGET)-as" \
	LD="$(TOOLS_DIR)/bin/$(CONFIG_TARGET)-ld" \
	RANLIB="$(TOOLS_DIR)/bin/$(CONFIG_TARGET)-ranlib" \
	READELF="$(TOOLS_DIR)/bin/$(CONFIG_TARGET)-readelf" \
	STRIP="$(TOOLS_DIR)/bin/$(CONFIG_TARGET)-strip" \
	OBJCOPY="$(TOOLS_DIR)/bin/$(CONFIG_TARGET)-objcopy" \
	OBJDUMP="$(TOOLS_DIR)/bin/$(CONFIG_TARGET)-objdump" \
	CPPFLAGS="-D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64" \
	CFLAGS="-D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64 -Os" \
	CXXFLAGS="-D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64 -Os" \
	LDFLAGS="" \
	PKG_CONFIG="$(TOOLS_DIR)/bin/pkg-config" \
	STAGING_DIR="$(TOOLS_DIR)/$(CONFIG_TARGET)/sysroot" \
	INTLTOOL_PERL=/usr/bin/perl \
	CXX=no \
	CFLAGS="-O2 " \
	CPPFLAGS="" \
	CXXFLAGS="-O2" \
	ac_cv_path_BASH_SHELL=/bin/bash \
	libc_cv_forced_unwind=yes \
	libc_cv_ssp=no \
	ac_cv_prog_MAKE="make -j$(PARALLEL_JOBS)" \
	$(BUILD_DIR)/glibc-2.29/configure \
	--target=$(CONFIG_TARGET) \
	--host=$(CONFIG_TARGET) \
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
	--with-headers=$(TOOLS_DIR)/$(CONFIG_TARGET)/sysroot/usr/include )
	$(MAKE_PARALLEL_JOBS) -C $(BUILD_DIR)/glibc-2.29/build
	$(MAKE_PARALLEL_JOBS) install_root=$(TOOLS_DIR)/$(CONFIG_TARGET)/sysroot install -C $(BUILD_DIR)/glibc-2.29/build
	rm -rf $(BUILD_DIR)/glibc-2.29

system:
	$(STEP) "glibc"
	$(EXTRACT) $(SOURCES_DIR)/glibc-2.29.tar.xz $(BUILD_DIR)
	mkdir -v $(BUILD_DIR)/glibc-2.29/build
	( cd $(BUILD_DIR)/glibc-2.29/build && \
	CC="$(TOOLS_DIR)/bin/$(CONFIG_TARGET)-gcc" \
	CXX="$(TOOLS_DIR)/bin/$(CONFIG_TARGET)-g++" \
	AR="$(TOOLS_DIR)/bin/$(CONFIG_TARGET)-ar" \
	AS="$(TOOLS_DIR)/bin/$(CONFIG_TARGET)-as" \
	LD="$(TOOLS_DIR)/bin/$(CONFIG_TARGET)-ld" \
	RANLIB="$(TOOLS_DIR)/bin/$(CONFIG_TARGET)-ranlib" \
	READELF="$(TOOLS_DIR)/bin/$(CONFIG_TARGET)-readelf" \
	STRIP="$(TOOLS_DIR)/bin/$(CONFIG_TARGET)-strip" \
	OBJCOPY="$(TOOLS_DIR)/bin/$(CONFIG_TARGET)-objcopy" \
	OBJDUMP="$(TOOLS_DIR)/bin/$(CONFIG_TARGET)-objdump" \
	CPPFLAGS="-D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64" \
	CFLAGS="-D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64 -Os" \
	CXXFLAGS="-D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64 -Os" \
	LDFLAGS="" \
	PKG_CONFIG="$(TOOLS_DIR)/bin/pkg-config" \
	STAGING_DIR="$(TOOLS_DIR)/$(CONFIG_TARGET)/sysroot" \
	INTLTOOL_PERL=/usr/bin/perl \
	CXX=no \
	CFLAGS="-O2 " \
	CPPFLAGS="" \
	CXXFLAGS="-O2" \
	ac_cv_path_BASH_SHELL=/bin/bash \
	libc_cv_forced_unwind=yes \
	libc_cv_ssp=no \
	ac_cv_prog_MAKE="make -j$(PARALLEL_JOBS)" \
	$(BUILD_DIR)/glibc-2.29/configure \
	--target=$(CONFIG_TARGET) \
	--host=$(CONFIG_TARGET) \
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
	--with-headers=$(TOOLS_DIR)/$(CONFIG_TARGET)/sysroot/usr/include )
	$(MAKE_PARALLEL_JOBS) -C $(BUILD_DIR)/glibc-2.29/build
	$(MAKE_PARALLEL_JOBS) install_root=$(ROOTFS_DIR) install -C $(BUILD_DIR)/glibc-2.29/build
	rm -rf $(BUILD_DIR)/glibc-2.29

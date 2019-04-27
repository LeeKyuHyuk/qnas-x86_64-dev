toolchain:
	$(STEP) "host-binutils 2.31.1"
	$(EXTRACT) $(SOURCES_DIR)/binutils-2.31.1.tar.xz $(BUILD_DIR)
	mkdir -v $(BUILD_DIR)/binutils-2.31.1/build
	( cd $(BUILD_DIR)/binutils-2.31.1/build && \
	PKG_CONFIG="$(TOOLS_DIR)/bin/pkg-config" \
	PKG_CONFIG_SYSROOT_DIR="/" \
	PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 \
	PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 \
	PKG_CONFIG_LIBDIR="$(TOOLS_DIR)/lib/pkgconfig:$(TOOLS_DIR)/share/pkgconfig" \
	CPPFLAGS="-I$(TOOLS_DIR)/include" \
	CFLAGS="-O2 -I$(TOOLS_DIR)/include" \
	CXXFLAGS="-O2 -I$(TOOLS_DIR)/include" \
	LDFLAGS="-L$(TOOLS_DIR)/lib -Wl,-rpath,$(TOOLS_DIR)/lib" \
	MAKEINFO=true \
	$(BUILD_DIR)/binutils-2.31.1/configure \
	--prefix=$(TOOLS_DIR) \
	--enable-shared \
	--disable-static \
	--disable-multilib \
	--disable-werror \
	--target=$(CONFIG_TARGET) \
	--disable-shared \
	--enable-static \
	--with-sysroot=$(TOOLS_DIR)/$(CONFIG_TARGET)/sysroot \
	--enable-poison-system-directories \
	--disable-sim \
	--disable-gdb )
	PKG_CONFIG="$(TOOLS_DIR)/bin/pkg-config" \
	PKG_CONFIG_SYSROOT_DIR="/" \
	PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 \
	PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 \
	PKG_CONFIG_LIBDIR="$(TOOLS_DIR)/lib/pkgconfig:$(TOOLS_DIR)/share/pkgconfig" \
	$(MAKE_PARALLEL_JOBS) MAKEINFO=true -C $(BUILD_DIR)/binutils-2.31.1/build
	PKG_CONFIG="$(TOOLS_DIR)/bin/pkg-config" \
	PKG_CONFIG_SYSROOT_DIR="/" \
	PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 \
	PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 \
	PKG_CONFIG_LIBDIR="$(TOOLS_DIR)/lib/pkgconfig:$(TOOLS_DIR)/share/pkgconfig" \
	$(MAKE_PARALLEL_JOBS) MAKEINFO=true install -C $(BUILD_DIR)/binutils-2.31.1/build
	rm -rf $(BUILD_DIR)/binutils-2.31.1

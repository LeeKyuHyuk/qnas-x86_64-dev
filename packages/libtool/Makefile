toolchain:
	$(STEP) "host-libtool 2.4.6"
	$(EXTRACT) $(SOURCES_DIR)/libtool-2.4.6.tar.xz $(BUILD_DIR)
	find $(BUILD_DIR)/libtool-2.4.6 -name aclocal.m4 -exec touch '{}' \;
	find $(BUILD_DIR)/libtool-2.4.6 -name config-h.in -exec touch '{}' \;
	find $(BUILD_DIR)/libtool-2.4.6 -name configure -exec touch '{}' \;
	find $(BUILD_DIR)/libtool-2.4.6 -name Makefile.in -exec touch '{}' \;
	( cd $(BUILD_DIR)/libtool-2.4.6 && \
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
	./configure \
	--prefix=$(TOOLS_DIR) \
	--enable-shared \
	--disable-static )
	PKG_CONFIG="$(TOOLS_DIR)/bin/pkg-config" \
	PKG_CONFIG_SYSROOT_DIR="/" \
	PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 \
	PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 \
	PKG_CONFIG_LIBDIR="$(TOOLS_DIR)/lib/pkgconfig:$(TOOLS_DIR)/share/pkgconfig" \
	$(MAKE_PARALLEL_JOBS) -C $(BUILD_DIR)/libtool-2.4.6
	PKG_CONFIG="$(TOOLS_DIR)/bin/pkg-config" \
	PKG_CONFIG_SYSROOT_DIR="/" \
	PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 \
	PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 \
	PKG_CONFIG_LIBDIR="$(TOOLS_DIR)/lib/pkgconfig:$(TOOLS_DIR)/share/pkgconfig" \
	$(MAKE_PARALLEL_JOBS) install -C $(BUILD_DIR)/libtool-2.4.6
	rm -rf $(BUILD_DIR)/libtool-2.4.6

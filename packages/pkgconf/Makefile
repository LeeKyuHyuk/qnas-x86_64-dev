toolchain:
	$(STEP) "Pkgconf 1.5.3"
	$(EXTRACT) $(SOURCES_DIR)/pkgconf-1.5.3.tar.gz $(BUILD_DIR)
	(cd $(BUILD_DIR)/pkgconf-1.5.3 && \
	PKG_CONFIG="$(TOOLS_DIR)/bin/pkg-config" \
	PKG_CONFIG_SYSROOT_DIR="/" \
	PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 \
	PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 \
	PKG_CONFIG_LIBDIR="$(TOOLS_DIR)/lib/pkgconfig:$(TOOLS_DIR)/share/pkgconfig" \
	CPPFLAGS="-I$(TOOLS_DIR)/include" \
	CFLAGS="-O2 -I$(TOOLS_DIR)/include" \
	CXXFLAGS="-O2 -I$(TOOLS_DIR)/include" \
	LDFLAGS="-L$(TOOLS_DIR)/lib -Wl,-rpath,$(TOOLS_DIR)/lib" \
	./configure \
	--prefix=$(TOOLS_DIR) \
	--enable-shared \
	--disable-static )
	PKG_CONFIG="$(TOOLS_DIR)/bin/pkg-config" \
	PKG_CONFIG_SYSROOT_DIR="/" \
	PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 \
	PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 \
	PKG_CONFIG_LIBDIR="$(TOOLS_DIR)/lib/pkgconfig:$(TOOLS_DIR)/share/pkgconfig" \
	$(MAKE_PARALLEL_JOBS) -C $(BUILD_DIR)/pkgconf-1.5.3
	PKG_CONFIG="$(TOOLS_DIR)/bin/pkg-config" \
	PKG_CONFIG_SYSROOT_DIR="/" \
	PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 \
	PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 \
	PKG_CONFIG_LIBDIR="$(TOOLS_DIR)/lib/pkgconfig:$(TOOLS_DIR)/share/pkgconfig" \
	$(MAKE_PARALLEL_JOBS) install -C $(BUILD_DIR)/pkgconf-1.5.3
	cp -v $(PACKAGES_DIR)/pkgconf/pkg-config $(TOOLS_DIR)/bin/pkg-config
	chmod -v 0755 $(TOOLS_DIR)/bin/pkg-config
	sed -i -e "s,@STAGING_SUBDIR@,$(CONFIG_TARGET)/sysroot,g" $(TOOLS_DIR)/bin/pkg-config
	sed -i -e 's,@STATIC@,,' $(TOOLS_DIR)/bin/pkg-config
	rm -rf $(BUILD_DIR)/pkgconf-1.5.3

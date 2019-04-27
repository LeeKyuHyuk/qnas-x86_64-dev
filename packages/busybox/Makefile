system:
	$(STEP) "busybox 1.29.3"
	$(EXTRACT) $(SOURCES_DIR)/busybox-1.29.3.tar.bz2 $(BUILD_DIR)
	$(MAKE_PARALLEL_JOBS) distclean -C $(BUILD_DIR)/busybox-1.29.3
	$(MAKE_PARALLEL_JOBS) ARCH="$(CONFIG_LINUX_ARCH)" defconfig -C $(BUILD_DIR)/busybox-1.29.3
	CFLAGS="-D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64 -Os" CFLAGS_busybox="" $(MAKE_PARALLEL_JOBS) CC="$(TOOLS_DIR)/bin/$(CONFIG_TARGET)-gcc" ARCH=x86_64 PREFIX="$(ROOTFS_DIR)" EXTRA_LDFLAGS="" CROSS_COMPILE="$(TOOLS_DIR)/bin/$(CONFIG_TARGET)-" CONFIG_PREFIX="$(ROOTFS_DIR)" SKIP_STRIP=y -C $(BUILD_DIR)/busybox-1.29.3
	CFLAGS="-D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64 -Os" CFLAGS_busybox="" $(MAKE_PARALLEL_JOBS) CC="$(TOOLS_DIR)/bin/$(CONFIG_TARGET)-gcc" ARCH=x86_64 PREFIX="$(ROOTFS_DIR)" EXTRA_LDFLAGS="" CROSS_COMPILE="$(TOOLS_DIR)/bin/$(CONFIG_TARGET)-" CONFIG_PREFIX="$(ROOTFS_DIR)" SKIP_STRIP=y -C $(BUILD_DIR)/busybox-1.29.3 install-noclobber
	# install -D -m 0644 $(PACKAGES_DIR)/skeleton/etc/inittab $(ROOTFS_DIR)/etc/inittab
	if grep -q CONFIG_UDHCPC=y $(BUILD_DIR)/busybox-1.29.3/.config; then \
	  install -m 0755 -D $(PACKAGES_DIR)/busybox/udhcpc.script $(ROOTFS_DIR)/usr/share/udhcpc/default.script; \
	  install -m 0755 -d $(ROOTFS_DIR)/usr/share/udhcpc/default.script.d; \
	fi
	if grep -q CONFIG_SYSLOGD=y $(BUILD_DIR)/busybox-1.29.3/.config; then \
	  install -m 0755 -D $(PACKAGES_DIR)/busybox/S01syslogd $(ROOTFS_DIR)/etc/init.d/S01syslogd; \
	fi
	if grep -q CONFIG_KLOGD=y $(BUILD_DIR)/busybox-1.29.3/.config; then \
	  install -m 0755 -D $(PACKAGES_DIR)/busybox/S02klogd $(ROOTFS_DIR)/etc/init.d/S02klogd; \
	fi
	if grep -q CONFIG_FEATURE_TELNETD_STANDALONE=y $(BUILD_DIR)/busybox-1.29.3/.config; then \
	  install -m 0755 -D $(PACKAGES_DIR)/busybox/S50telnet $(ROOTFS_DIR)/etc/init.d/S50telnet; \
	fi
	rm -rf $(BUILD_DIR)/busybox-1.29.3

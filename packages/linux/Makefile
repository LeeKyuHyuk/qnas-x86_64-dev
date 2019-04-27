sysroot:
	$(STEP) "linux-headers 4.19.16"
	$(EXTRACT) $(SOURCES_DIR)/linux-4.19.16.tar.xz $(BUILD_DIR)
	$(MAKE_PARALLEL_JOBS) ARCH=$(CONFIG_LINUX_ARCH) INSTALL_HDR_PATH=$(TOOLS_DIR)/$(CONFIG_TARGET)/sysroot/usr headers_install -C $(BUILD_DIR)/linux-4.19.16
	rm -rf $(BUILD_DIR)/linux-4.19.16

kernel:
	$(STEP) "linux-headers 4.19.16"
	$(EXTRACT) $(SOURCES_DIR)/linux-4.19.16.tar.xz $(BUILD_DIR)
	$(MAKE_PARALLEL_JOBS) ARCH=$(CONFIG_LINUX_ARCH) mrproper -C $(BUILD_DIR)/linux-4.19.16
	$(MAKE_PARALLEL_JOBS) ARCH=$(CONFIG_LINUX_ARCH) CROSS_COMPILE="$(TOOLS_DIR)/bin/$(CONFIG_TARGET)-" $(CONFIG_LINUX_KERNEL_DEFCONFIG) -C $(BUILD_DIR)/linux-4.19.16
	# $(STEP) 1 - disable all active kernel compression options (should be only one).
	sed -i "s/.*CONFIG_DEFAULT_HOSTNAME.*/CONFIG_DEFAULT_HOSTNAME=\""$(CONFIG_HOSTNAME)"\"/" $(BUILD_DIR)/linux-4.19.16/.config
	# $(STEP) 1 - disable all active kernel compression options (should be only one).
	sed -i "s/.*\\(CONFIG_KERNEL_.*\\)=y/\\#\\ \\1 is not set/" $(BUILD_DIR)/linux-4.19.16/.config
	# $(STEP) 2 - enable the 'xz' compression option.
	sed -i "s/.*CONFIG_KERNEL_XZ.*/CONFIG_KERNEL_XZ=y/" $(BUILD_DIR)/linux-4.19.16/.config
	# Enable the VESA framebuffer for graphics support.
	sed -i "s/.*CONFIG_FB_VESA.*/CONFIG_FB_VESA=y/" $(BUILD_DIR)/linux-4.19.16/.config
	# Disable debug symbols in kernel => smaller kernel binary.
	sed -i "s/^CONFIG_DEBUG_KERNEL.*/\\# CONFIG_DEBUG_KERNEL is not set/" $(BUILD_DIR)/linux-4.19.16/.config
	# Enable the EFI stub
	sed -i "s/.*CONFIG_EFI_STUB.*/CONFIG_EFI_STUB=y/" $(BUILD_DIR)/linux-4.19.16/.config
	# Request that the firmware clear the contents of RAM after reboot (4.14+).
	echo "CONFIG_RESET_ATTACK_MITIGATION=y" >> $(BUILD_DIR)/linux-4.19.16/.config
	# Disable Apple Properties (Useful for Macs but useless in general)
	echo "CONFIG_APPLE_PROPERTIES=n" >> $(BUILD_DIR)/linux-4.19.16/.config
	# Enable the mixed EFI mode when building 64-bit kernel.
	echo "CONFIG_EFI_MIXED=y" >> $(BUILD_DIR)/linux-4.19.16/.config
	$(MAKE_PARALLEL_JOBS) ARCH=$(CONFIG_LINUX_ARCH) CROSS_COMPILE="$(TOOLS_DIR)/bin/$(CONFIG_TARGET)-" -C $(BUILD_DIR)/linux-4.19.16 bzImage
	cp -v $(BUILD_DIR)/linux-4.19.16/arch/x86/boot/bzImage $(KERNEL_DIR)/bzImage
	rm -rf $(BUILD_DIR)/linux-4.19.16

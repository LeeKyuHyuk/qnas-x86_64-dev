include settings.mk

.PHONY: all toolchain system kernel image clean

help:
	@$(SCRIPTS_DIR)/help.sh

all:
	@make clean toolchain system kernel image

toolchain:
	rm -rf $(OUTPUT_DIR)
	mkdir -pv $(BUILD_DIR) $(TOOLS_DIR)
	make toolchain -C $(PACKAGES_DIR)/pkgconf
	make toolchain -C $(PACKAGES_DIR)/zlib
	make toolchain -C $(PACKAGES_DIR)/util-linux
	make toolchain -C $(PACKAGES_DIR)/e2fsprogs
	make toolchain -C $(PACKAGES_DIR)/fakeroot
	make toolchain -C $(PACKAGES_DIR)/makedevs
	make toolchain -C $(PACKAGES_DIR)/mkpasswd
	make toolchain -C $(PACKAGES_DIR)/m4
	make toolchain -C $(PACKAGES_DIR)/bison
	make toolchain -C $(PACKAGES_DIR)/gawk
	make toolchain -C $(PACKAGES_DIR)/binutils
	make toolchain -C $(PACKAGES_DIR)/gmp
	make toolchain -C $(PACKAGES_DIR)/mpfr
	make toolchain -C $(PACKAGES_DIR)/mpc
	make toolchain-initial -C $(PACKAGES_DIR)/gcc
	make sysroot -C $(PACKAGES_DIR)/skeleton
	make sysroot -C $(PACKAGES_DIR)/linux
	make sysroot -C $(PACKAGES_DIR)/glibc
	make toolchain-final -C $(PACKAGES_DIR)/gcc
	make toolchain -C $(PACKAGES_DIR)/libtool
	make toolchain -C $(PACKAGES_DIR)/autoconf
	make toolchain -C $(PACKAGES_DIR)/automake
	make toolchain -C $(PACKAGES_DIR)/flex
	make toolchain -C $(PACKAGES_DIR)/kmod

system:
	rm -rf $(BUILD_DIR) $(ROOTFS_DIR)
	mkdir -pv $(BUILD_DIR) $(ROOTFS_DIR)
	make system -C $(PACKAGES_DIR)/skeleton
	make system -C $(PACKAGES_DIR)/glibc
	make system -C $(PACKAGES_DIR)/busybox

kernel:
	rm -rf $(BUILD_DIR) $(KERNEL_DIR)
	mkdir -pv $(BUILD_DIR) $(KERNEL_DIR)
	make kernel -C $(PACKAGES_DIR)/linux

image:
	rm -rf $(BUILD_DIR) $(IMAGES_DIR)
	mkdir -pv $(BUILD_DIR) $(IMAGES_DIR)
	echo '#!/bin/sh' > $(BUILD_DIR)/_fakeroot.fs
	echo "set -e" >> $(BUILD_DIR)/_fakeroot.fs
	echo "chown -h -R 0:0 $(ROOTFS_DIR)" >> $(BUILD_DIR)/_fakeroot.fs
	cp -v $(PACKAGES_DIR)/makedevs/device_table.txt $(BUILD_DIR)/_device_table.txt
	if [ -d $(ROOTFS_DIR)/var/lib/sshd ] ; then \
	  echo "/var/lib/sshd	d	700	0	2	-	-	-	-	-" >> $(BUILD_DIR)/_device_table.txt ;\
	fi
	if [ -d $(ROOTFS_DIR)/home/ftp ] ; then \
	  echo "/home/ftp	d	755	45	45	-	-	-	-	-" >> $(BUILD_DIR)/_device_table.txt ;\
	fi
	echo "$(TOOLS_DIR)/bin/makedevs -d $(BUILD_DIR)/_device_table.txt $(ROOTFS_DIR)" >> $(BUILD_DIR)/_fakeroot.fs
	echo "$(TOOLS_DIR)/sbin/mkfs.ext2 -d $(ROOTFS_DIR) $(IMAGES_DIR)/rootfs.ext2 250M" >> $(BUILD_DIR)/_fakeroot.fs
	chmod a+x $(BUILD_DIR)/_fakeroot.fs
	fakeroot -- $(BUILD_DIR)/_fakeroot.fs

run:
	qemu-system-x86_64 -kernel $(KERNEL_DIR)/bzImage -drive file=$(IMAGES_DIR)/rootfs.ext2,format=raw -append "root=/dev/sda"

clean:
	@rm -rf out

flash:
	@sudo python2 $(SCRIPTS_DIR)/image-usb-stick $(IMAGES_DIR)/$(CONFIG_ISO_FILENAME) && sudo -k

download:
	@wget -c -i wget-list -P $(SOURCES_DIR)

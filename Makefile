include settings.mk

.PHONY: all toolchain system image clean

help:
	@$(SCRIPTS_DIR)/help.sh

all:
	@make clean toolchain system kernel image

toolchain:
	@$(SCRIPTS_DIR)/toolchain.sh

system:
	@$(SCRIPTS_DIR)/system.sh

kernel:
	@$(SCRIPTS_DIR)/kernel.sh

image:
	@$(SCRIPTS_DIR)/image.sh

run:
	@qemu-system-x86_64 --cdrom $(IMAGES_DIR)/$(CONFIG_ISO_FILENAME)

clean:
	@rm -rf out

flash:
	@sudo python2 $(SCRIPTS_DIR)/image-usb-stick $(IMAGES_DIR)/sdcard.img && sudo -k

download:
	@wget -c -i wget-list -P $(SOURCES_DIR)

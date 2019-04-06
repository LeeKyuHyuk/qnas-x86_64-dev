include settings.mk

.PHONY: all toolchain system kernel live-system live-kernel image clean

help:
	@$(SCRIPTS_DIR)/help.sh

all:
	@make clean toolchain system kernel live-system live-kernel image clean

toolchain:
	@$(SCRIPTS_DIR)/toolchain.sh

system:
	@$(SCRIPTS_DIR)/system.sh

kernel:
	@$(SCRIPTS_DIR)/kernel.sh

live-system:
	@$(SCRIPTS_DIR)/live-system.sh

live-kernel:
	@$(SCRIPTS_DIR)/live-kernel.sh

image:
	@$(SCRIPTS_DIR)/image.sh

run:
	@qemu-system-x86_64 --cdrom $(IMAGES_DIR)/$(CONFIG_ISO_FILENAME)

clean:
	@rm -rf out

flash:
	@sudo python2 $(SCRIPTS_DIR)/image-usb-stick $(IMAGES_DIR)/$(CONFIG_ISO_FILENAME) && sudo -k

download:
	@wget -c -i wget-list -P $(SOURCES_DIR)

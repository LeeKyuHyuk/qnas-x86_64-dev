-include config.mk

export PARALLEL_JOBS := $(shell cat /proc/cpuinfo | grep cores | wc -l)
export WORKSPACE_DIR := $(shell cd "$(dirname "$0")" && pwd)
export SOURCES_DIR := $(WORKSPACE_DIR)/sources
export PACKAGES_DIR := $(WORKSPACE_DIR)/packages
export SUPPORT_DIR := $(WORKSPACE_DIR)/support
export SCRIPTS_DIR := $(WORKSPACE_DIR)/scripts
export OUTPUT_DIR := $(WORKSPACE_DIR)/out
export BUILD_DIR := $(OUTPUT_DIR)/build
export TOOLS_DIR := $(OUTPUT_DIR)/tools
export SYSROOT_DIR := $(TOOLS_DIR)/$(CONFIG_TARGET)
export ROOTFS_DIR := $(OUTPUT_DIR)/rootfs
export LIVE_ROOTFS_DIR := $(OUTPUT_DIR)/live-rootfs
export IMAGES_DIR := $(OUTPUT_DIR)/images
export KERNEL_DIR := $(OUTPUT_DIR)/kernel
export PATH := "$(TOOLS_DIR)/bin:$(TOOLS_DIR)/sbin:$(TOOLS_DIR)/usr/bin:$(TOOLS_DIR)/usr/sbin:$(PATH)"
export CONFIG_SITE := /dev/null
export STEP := $(SCRIPTS_DIR)/step.sh
export EXTRACT := $(SCRIPTS_DIR)/extract.sh
export MAKE := PATH=$(PATH) make -j1
export MAKE_PARALLEL_JOBS := PATH=$(PATH) make -j$(PARALLEL_JOBS)
export HOST_PKG_CONFIG := PKG_CONFIG="$(TOOLS_DIR)/bin/pkg-config" PKG_CONFIG_SYSROOT_DIR="/" PKG_CONFIG_ALLOW_SYSTEM_CFLAGS=1 PKG_CONFIG_ALLOW_SYSTEM_LIBS=1 PKG_CONFIG_LIBDIR="$(TOOLS_DIR)/lib/pkgconfig:$(TOOLS_DIR)/share/pkgconfig"

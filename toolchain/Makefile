# 
# Copyright (C) 2007-2009 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#
# Main makefile for the toolchain
#
# Build the host LLVM wrappers, kernel headers, musl and target LLVM runtimes.

curdir:=toolchain

# subdirectories to descend into
$(curdir)/builddirs := llvm/initial kernel-headers musl llvm/final fortify-headers $(if $(CONFIG_NASM),nasm) $(if $(CONFIG_USE_MOLD),mold)

# builddir dependencies
$(curdir)/kernel-headers/compile:=$(curdir)/llvm/initial/compile
$(curdir)/musl/compile:=$(curdir)/kernel-headers/compile
$(curdir)/llvm/final/compile:=$(curdir)/musl/compile

ifndef DUMP_TARGET_DB
ifneq ($(ARCH),)
  $(TOOLCHAIN_DIR)/info.mk: .config
	@for dir in $(TOOLCHAIN_DIR); do ( \
		$(if $(QUIET),,set -x;) \
		mkdir -p "$$dir"; \
		cd "$$dir"; \
		ln -nsf lib lib64; \
		ln -nsf lib lib32; \
		mkdir -p stamp lib usr/include usr/lib ; \
	); done
	@grep LLVM_VERSION $@ >/dev/null 2>&1 || $(INSTALL_DATA) $(TOPDIR)/toolchain/info.mk $@
	@touch $@
endif
endif

ifdef CONFIG_BUILDBOT
ifneq ($(wildcard $(TOPDIR)/.git),)
  $(TOOLCHAIN_DIR)/stamp/.ver_check: $(TMP_DIR)/.build
	cd "$(TOPDIR)"; git log --no-show-signature --format=%h -1 toolchain > $(TMP_DIR)/.ver_check
	cmp -s $(TMP_DIR)/.ver_check $@ || { \
		rm -rf $(BUILD_DIR) $(STAGING_DIR) $(TOOLCHAIN_DIR) $(BUILD_DIR_TOOLCHAIN); \
		mkdir -p $(TOOLCHAIN_DIR)/stamp; \
		mv $(TMP_DIR)/.ver_check $@; \
	}

$(TOOLCHAIN_DIR)/info.mk $(STAGING_DIR)/.prepared: $(TOOLCHAIN_DIR)/stamp/.ver_check
endif
endif

# prerequisites for the individual targets
$(curdir)/ := .config prereq
$(curdir)//compile = $(STAGING_DIR)/.prepared $(TOOLCHAIN_DIR)/info.mk $(tools/stamp-compile)

ifndef DUMP_TARGET_DB
$(TOOLCHAIN_DIR)/stamp/.llvm_final_installed:
endif

$(curdir)/install: $(curdir)/compile

$(eval $(call stampfile,$(curdir),toolchain,compile,$(TOOLCHAIN_DIR)/stamp/.llvm_final_installed,,$(TOOLCHAIN_DIR)))
$(eval $(call stampfile,$(curdir),toolchain,check,$(TMP_DIR)/.build))
$(eval $(call subdir,$(curdir)))

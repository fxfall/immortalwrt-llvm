# SPDX-License-Identifier: GPL-2.0-only
include $(TOPDIR)/rules.mk
PKG_NAME:=llvm-initial
PKG_VERSION:=$(strip $(shell cat $(TOPDIR)/toolchain/llvm/version))
PKG_SOURCE:=llvm-project-$(PKG_VERSION).src.tar.xz
PKG_SOURCE_URL:=https://github.com/llvm/llvm-project/releases/download/llvmorg-$(PKG_VERSION)
PKG_HASH:=c98bbef08a2b4c2613cd50e9aa9ae7b69b1fe6c16b2c40373bc0ab6116fdf78a
include $(INCLUDE_DIR)/toolchain-build.mk

HOST_STAMP_INSTALLED:=$(TOOLCHAIN_DIR)/stamp/.llvm_initial_installed

define Host/Prepare
	mkdir -p $(HOST_BUILD_DIR)
endef
Host/Configure:=
Host/Compile:=

define Host/Install
	$(SCRIPT_DIR)/llvm/install-toolchain.sh "$(TOOLCHAIN_DIR)" "$(TARGET_CROSS)" "$(LLVM_BINDIR)"
	$(SED) 's,^LLVM_VERSION=.*,LLVM_VERSION=$(PKG_VERSION),' $(TOOLCHAIN_DIR)/info.mk
endef

$(eval $(call HostBuild))

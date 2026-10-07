# SPDX-License-Identifier: GPL-2.0-only
include $(TOPDIR)/rules.mk
PKG_NAME:=llvm-project
PKG_VERSION:=$(strip $(shell cat $(TOPDIR)/toolchain/llvm/version))
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).src.tar.xz
PKG_SOURCE_URL:=https://github.com/llvm/llvm-project/releases/download/llvmorg-$(PKG_VERSION)
PKG_HASH:=c98bbef08a2b4c2613cd50e9aa9ae7b69b1fe6c16b2c40373bc0ab6116fdf78a
HOST_BUILD_DIR:=$(BUILD_DIR_TOOLCHAIN)/$(PKG_NAME)-$(PKG_VERSION).src
include $(INCLUDE_DIR)/toolchain-build.mk
HOST_STAMP_INSTALLED:=$(TOOLCHAIN_DIR)/stamp/.llvm_final_installed
Host/Configure:=

define Host/Compile
	$(SCRIPT_DIR)/llvm/build-runtimes.sh "$(HOST_BUILD_DIR)" "$(TOOLCHAIN_DIR)" "$(LLVM_BINDIR)" "$(TARGET_CROSS)" "$(TARGET_OPTIMIZATION)"
endef
Host/Install:=
$(eval $(call HostBuild))

#
# Copyright (C) 2007-2014 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk
PKG_NAME:=toolchain
PKG_RELEASE:=5

PKG_MAINTAINER:=Felix Fietkau <nbd@nbd.name>
PKG_LICENSE:=Apache-2.0-with-LLVM-exception

PKG_FLAGS:=hold essential nonshared

include $(INCLUDE_DIR)/package.mk

ifneq ($(DUMP),1)
  LLVM_RUNTIME_VERSION:=$(LLVM_VERSION)
else
  LIBC_VERSION:=<LIBC_VERSION>
  LLVM_RUNTIME_VERSION:=<LLVM_VERSION>
endif

define Package/llvm/Default
  SECTION:=libs
  CATEGORY:=Base system
  URL:=https://llvm.org/
  LICENSE:=Apache-2.0-with-LLVM-exception
  VERSION:=$(LLVM_RUNTIME_VERSION)-r$(PKG_RELEASE)
endef

define Package/libgcc
$(call Package/llvm/Default)
  TITLE:=LLVM unwind runtime compatibility package
  ABI_VERSION:=1
endef


define Package/libatomic
$(call Package/llvm/Default)
  DEPENDS:=+libgcc
  TITLE:=Atomic support library
  ABI_VERSION:=1
endef




define Package/libstdcpp
$(call Package/llvm/Default)
  NAME:=libstdc++
  TITLE:=LLVM libc++ compatibility package
  ABI_VERSION:=6
endef















define Package/libc/Default
  SECTION:=libs
  CATEGORY:=Base system
  VERSION:=$(LIBC_VERSION)-r$(PKG_RELEASE)
  DEPENDS:=+libgcc
  URL:=$(LIBC_URL)
endef


define Package/libc
$(call Package/libc/Default)
  TITLE:=C library
endef



define Package/libpthread
$(call Package/libc/Default)
  TITLE:=POSIX thread library
endef



define Package/libthread-db
$(call Package/libc/Default)
  DEPENDS:=@!USE_MUSL
  TITLE:=POSIX thread library debugging support
endef


define Package/librt
$(call Package/libc/Default)
  TITLE:=POSIX.1b RealTime extension library
  DEPENDS:=+libpthread
endef








define Package/ldd
$(call Package/libc/Default)
  DEPENDS:=@!USE_MUSL
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=LDD trace utility
endef



define Package/ldconfig
$(call Package/libc/Default)
  DEPENDS:=@!USE_MUSL
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=Shared library path configuration
endef


define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
endef

define Build/Quilt
endef

define Build/Compile/Default
	$(call Build/Compile/$(LIBC))
endef
Build/Compile = $(Build/Compile/Default)

define Package/libgcc/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(TOOLCHAIN_DIR)/usr/lib/libunwind.so.* $(1)/usr/lib/
endef

define Package/libatomic/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(TOOLCHAIN_DIR)/usr/lib/libclang_rt.atomic-$(ARCH).so $(1)/usr/lib/
endef

define Package/libstdcpp/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(TOOLCHAIN_DIR)/usr/lib/libc++.so.* $(TOOLCHAIN_DIR)/usr/lib/libc++abi.so.* $(1)/usr/lib/
endef

define Package/glibc/install
endef

LD_MUSL_NAME = $(notdir $(firstword $(wildcard $(TOOLCHAIN_DIR)/lib/libc.so*)))

define Package/musl/install
	$(INSTALL_DIR) $(1)/lib $(1)/usr/bin
	$(CP) $(TOOLCHAIN_DIR)/lib/ld-musl-*.so* $(1)/lib/
	$(CP) $(TOOLCHAIN_DIR)/lib/libc.so* $(1)/lib/
	$(LN) ../../lib/$(LD_MUSL_NAME) $(1)/usr/bin/ldd
endef

define Package/libc/install
	echo $(LIBC_VERSION)-r$(PKG_RELEASE) > $(STAGING_DIR)/libc.version
	$(call Package/musl/install,$1)
endef

define Package/libc/install_lib
	$(CP) $(filter-out %/libdl_pic.a %/libpthread_pic.a %/libresolv_pic.a,$(wildcard $(TOOLCHAIN_DIR)/lib/lib*.a)) $(1)/lib/
	$(if $(wildcard $(TOOLCHAIN_DIR)/lib/libc_so.a),$(CP) $(TOOLCHAIN_DIR)/lib/libc_so.a $(1)/lib/libc_pic.a)
endef

define Package/libpthread/install
	$(INSTALL_DIR) $(1)/lib
endef

define Package/libthread-db/install
	$(INSTALL_DIR) $(1)/lib
endef

define Package/libpthread/install_lib
	$(if $(wildcard $(TOOLCHAIN_DIR)/lib/libpthread_so.a),$(CP) $(TOOLCHAIN_DIR)/lib/libpthread_so.a $(1)/lib/libpthread_pic.a)
endef

define Package/librt/install
	$(INSTALL_DIR) $(1)/lib
endef

define Package/ldd/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(CP) $(TOOLCHAIN_DIR)/bin/ldd $(1)/usr/bin/
	sed -i 's,^#!.*,#!/bin/sh,' $(1)/usr/bin/ldd
endef

define Package/ldconfig/install
	$(INSTALL_DIR) $(1)/sbin
	$(CP) $(TOOLCHAIN_DIR)/sbin/ldconfig $(1)/sbin/
endef

$(eval $(call BuildPackage,libgcc))
# libc depends on the LLVM runtime compatibility ABI, so it is evaluated first.
$(eval $(call BuildPackage,libc))
$(eval $(call BuildPackage,libatomic))
$(eval $(call BuildPackage,libstdcpp))
$(eval $(call BuildPackage,libpthread))
$(eval $(call BuildPackage,libthread-db))
$(eval $(call BuildPackage,librt))
$(eval $(call BuildPackage,ldd))
$(eval $(call BuildPackage,ldconfig))

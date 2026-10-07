PATH_PREFIX=.

include ./common.mk

HOST_STAMP_BUILT:=$(HOST_BUILD_DIR)/.built
HOST_STAMP_INSTALLED:=$(TOOLCHAIN_DIR)/stamp/.musl_installed

HOST_BUILD_PARALLEL:=1

MUSL_MAKEOPTS = -C $(HOST_BUILD_DIR) \
	DESTDIR="$(TOOLCHAIN_DIR)/" \
	PATH="$(TOOLCHAIN_DIR)/bin:$(PATH)" \
	LIBCC="$(TOOLCHAIN_DIR)/llvm-resource/lib/linux/libclang_rt.builtins-$(ARCH).a"

define Host/SetToolchainInfo
	$(SED) 's,^\(LIBC_TYPE\)=.*,\1=$(PKG_NAME),' $(TOOLCHAIN_DIR)/info.mk
	$(SED) 's,^\(LIBC_URL\)=.*,\1=http://www.musl-libc.org/,' $(TOOLCHAIN_DIR)/info.mk
	$(SED) 's,^\(LIBC_VERSION\)=.*,\1=$(PKG_VERSION),' $(TOOLCHAIN_DIR)/info.mk
	$(SED) 's,^\(LIBC_SO_VERSION\)=.*,\1=$(LIBC_SO_VERSION),' $(TOOLCHAIN_DIR)/info.mk
endef

define Host/Compile
	+$(MAKE) $(HOST_JOBS) $(MUSL_MAKEOPTS) install-headers
	$(SCRIPT_DIR)/llvm/build-bootstrap-builtins.sh "$(DL_DIR)/llvm-project-$(strip $(shell cat $(TOPDIR)/toolchain/llvm/version)).src.tar.xz" "$(BUILD_DIR_TOOLCHAIN)/llvm-bootstrap-$(strip $(shell cat $(TOPDIR)/toolchain/llvm/version))" "$(TOOLCHAIN_DIR)" "$(LLVM_BINDIR)" "$(TARGET_CROSS)" "$(TARGET_OPTIMIZATION)" "$(STAGING_DIR_HOST)/bin/cmake" "$(STAGING_DIR_HOST)/bin/ninja"
	+$(MAKE) $(HOST_JOBS) $(MUSL_MAKEOPTS) all
endef

define Host/Install
	$(call Host/SetToolchainInfo)
	+$(MAKE) $(HOST_JOBS) $(MUSL_MAKEOPTS) DESTDIR="$(TOOLCHAIN_DIR)/" install
	$(CP) ./include $(TOOLCHAIN_DIR)/
endef

$(eval $(call HostBuild))

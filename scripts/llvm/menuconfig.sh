#!/bin/bash
set -euo pipefail

root=$(cd "$(dirname "$0")/../.." && pwd)
cd "$root"
source scripts/llvm/setup-env.sh

fail() {
	printf 'LLVM menuconfig: %s\n' "$1" >&2
	exit 1
}

[ ! -L .config ] || fail 'refusing to replace a .config symlink'

had_config=0
backup=
if [ -f .config ]; then
	had_config=1
	backup=$(mktemp tmp/.config.menuconfig.XXXXXX)
	cp -p .config "$backup"
fi

restore_config() {
	status=$?
	trap - EXIT
	if [ "$status" -ne 0 ]; then
		if [ "$had_config" -eq 1 ]; then
			cp -p "$backup" .config
		else
			rm -f .config
		fi
		printf 'LLVM menuconfig: restored the previous config state\n' >&2
	fi
	[ -z "$backup" ] || rm -f "$backup"
	exit "$status"
}
trap restore_config EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# Generate package/target metadata and build Kconfig tools with Clang before
# opening the UI. The config helper intentionally does not depend on enter.sh.
env OPENWRT_BUILD= QUIET=0 HOSTCC="$HOSTCC" HOSTCXX="$HOSTCXX" \
	make --no-print-directory -r -j1 prepare-tmpinfo
HOSTCC="$HOSTCC" HOSTCXX="$HOSTCXX" \
	make --no-print-directory -B -C scripts/config conf mconf

if [ "$had_config" -eq 1 ]; then
	KCONFIG_CONFIG=.config scripts/config/conf --defconfig=.config Config.in
else
	KCONFIG_CONFIG=.config scripts/config/conf --defconfig=/dev/null Config.in
fi

# Establish LLVM defaults before opening the UI, so the configuration the
# user sees is already normalized for this branch.
python3 scripts/llvm/force-llvm-config.py .config
KCONFIG_CONFIG=.config scripts/config/conf --defconfig=.config Config.in

KCONFIG_CONFIG=.config scripts/config/mconf Config.in
python3 scripts/llvm/force-llvm-config.py .config
KCONFIG_CONFIG=.config scripts/config/conf --defconfig=.config Config.in

grep -Fxq 'CONFIG_USE_LLVM_TOOLCHAIN=y' .config || fail 'LLVM is not active in the saved config'
grep -Fxq 'CONFIG_USE_MUSL=y' .config || fail 'musl is not active in the saved config'
grep -Fxq 'CONFIG_BPF_TOOLCHAIN_HOST=y' .config || fail 'host LLVM is not active for BPF builds'

[ -z "$backup" ] || rm -f "$backup"
backup=
printf 'Saved LLVM-only configuration to .config\n'

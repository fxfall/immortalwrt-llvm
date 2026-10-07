#!/bin/bash
# Shared host setup for menuconfig and all LLVM build entry points.
set -euo pipefail

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
	echo 'Source this file from an LLVM entry script.' >&2
	exit 2
fi

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
cd "$root"

fail() {
	printf 'LLVM environment: %s\n' "$1" >&2
	exit 1
}

[ "$(uname -s)" = Linux ] || fail 'run inside Orb Debian trixie; macOS builds are unsupported'
if [ -r /etc/os-release ]; then
	. /etc/os-release
	[ "${ID:-}" = debian ] && [ "${VERSION_CODENAME:-}" = trixie ] || \
		fail 'the build environment must be Debian trixie'
else
	fail 'cannot verify the Debian trixie build environment'
fi

LLVM_VERSION=$(tr -d '\n' < toolchain/llvm/version)
LLVM_MAJOR=${LLVM_VERSION%%.*}
export LLVM_VERSION LLVM_MAJOR
export LLVM_BINDIR=${LLVM_BINDIR:-/usr/lib/llvm-${LLVM_MAJOR}/bin}
[ -x "$LLVM_BINDIR/clang" ] || fail "Clang $LLVM_VERSION is missing from $LLVM_BINDIR"
version=$("$LLVM_BINDIR/clang" -dumpversion)
[ "$version" = "$LLVM_VERSION" ] || fail "expected LLVM $LLVM_VERSION, found $version"

mkdir -p tmp/llvm-host/bin staging_dir/host/bin logs
export LLVM_AUDIT_LOG="$PWD/logs/llvm-commands.log"
for name in gcc cc clang cpp; do
	ln -sfn "$PWD/scripts/llvm/host-cc" "tmp/llvm-host/bin/$name"
	ln -sfn "$PWD/scripts/llvm/host-cc" "staging_dir/host/bin/$name"
done
for name in g++ c++ clang++; do
	ln -sfn "$PWD/scripts/llvm/host-cxx" "tmp/llvm-host/bin/$name"
	ln -sfn "$PWD/scripts/llvm/host-cxx" "staging_dir/host/bin/$name"
done
for name in ar ranlib nm objcopy objdump strip readelf size strings addr2line; do
	ln -sfn "$LLVM_BINDIR/llvm-$name" "tmp/llvm-host/bin/$name"
	ln -sfn "$LLVM_BINDIR/llvm-$name" "staging_dir/host/bin/$name"
done
ln -sfn "$LLVM_BINDIR/ld.lld" tmp/llvm-host/bin/ld
ln -sfn "$LLVM_BINDIR/ld.lld" staging_dir/host/bin/ld
export PATH="$PWD/tmp/llvm-host/bin:$LLVM_BINDIR:$PATH"
export CC="$PWD/scripts/llvm/host-cc"
export CXX="$PWD/scripts/llvm/host-cxx"
export HOSTCC="$CC" HOSTCXX="$CXX"
export AR=ar RANLIB=ranlib NM=nm LD=ld CPP=cpp
umask 022

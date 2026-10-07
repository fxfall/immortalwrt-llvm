#!/bin/sh
set -eu
root=$1
prefix=$2
llvm_bin=$3
scripts=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
resource=$("$llvm_bin/clang" -print-resource-dir)
target=${prefix%-}
arch=${target%%-*}
mkdir -p "$root/bin" "$root/lib" "$root/llvm-resource/lib/linux"
ln -sfn "$resource/include" "$root/llvm-resource/include"
# Compiler-rt builtins contain no libc dependencies. Bootstrap musl with the
# installed LLVM builtins, then rebuild them for this sysroot in llvm/final.
if [ -f "$resource/lib/linux/libclang_rt.builtins-$arch.a" ]; then
	cp "$resource/lib/linux/libclang_rt.builtins-$arch.a" "$root/llvm-resource/lib/linux/"
	for crt in "$resource"/lib/linux/clang_rt.crt*.o; do
		[ ! -f "$crt" ] || cp "$crt" "$root/llvm-resource/lib/linux/"
	done
fi
for cc in gcc g++ cc c++ clang clang++ cpp; do
    cp "$scripts/target-cc" "$root/bin/$prefix$cc"
done
for tool in ar ranlib nm objcopy objdump strip readelf size strings addr2line; do
    ln -sfn "$llvm_bin/llvm-$tool" "$root/bin/$prefix$tool"
done
for tool in ar ranlib nm; do
    ln -sfn "$prefix$tool" "$root/bin/${prefix}gcc-$tool"
done
for tool in ld ld.bfd ld.lld; do
    ln -sfn "$llvm_bin/ld.lld" "$root/bin/$prefix$tool"
done

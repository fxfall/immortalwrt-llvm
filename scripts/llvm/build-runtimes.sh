#!/bin/bash
set -euo pipefail

source_dir=$1
sysroot=$2
llvm_bin=$3
target=${4%-}
target_flags=${5:--Os}
arch=${target%%-*}
jobs=${LLVM_JOBS:-4}

case $arch in
    aarch64|x86_64|i386) ;;
    *) echo "unsupported LLVM runtime target: $target" >&2; exit 1 ;;
esac

cc=$sysroot/bin/${target}-clang
cxx=$sysroot/bin/${target}-clang++
builtin=libclang_rt.builtins-$arch.a
profile=libclang_rt.profile-$arch.a
atomic=libclang_rt.atomic-$arch.so
target_cxx_flags="$target_flags -nostdlib++"

common=( -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_SYSTEM_NAME=Linux
    -DCMAKE_SYSTEM_PROCESSOR="$arch" -DCMAKE_C_COMPILER="$cc"
    -DCMAKE_C_COMPILER_TARGET="$target"
    -DCMAKE_CXX_COMPILER_TARGET="$target"
    -DCMAKE_CXX_COMPILER="$cxx" -DCMAKE_ASM_COMPILER="$cc"
    -DCMAKE_AR="$llvm_bin/llvm-ar" -DCMAKE_RANLIB="$llvm_bin/llvm-ranlib"
    -DCMAKE_SYSROOT="$sysroot" -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY
    -DCMAKE_C_FLAGS="$target_flags" -DCMAKE_CXX_FLAGS="$target_flags"
    -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_INSTALL_LIBDIR=lib )

cmake -S "$source_dir/compiler-rt" -B "$source_dir/build-builtins" "${common[@]}" \
    -DCOMPILER_RT_DEFAULT_TARGET_ONLY=ON -UCOMPILER_RT_DEFAULT_TARGET_TRIPLE \
    -DCOMPILER_RT_BUILD_BUILTINS=ON -DCOMPILER_RT_BUILD_CRT=ON \
    -DCOMPILER_RT_BUILD_STANDALONE_LIBATOMIC=ON \
    -DCOMPILER_RT_LIBATOMIC_LINK_FLAGS=-nostartfiles \
    -DCOMPILER_RT_BUILD_SANITIZERS=OFF -DCOMPILER_RT_BUILD_XRAY=OFF \
    -DCOMPILER_RT_BUILD_LIBFUZZER=OFF -DCOMPILER_RT_BUILD_PROFILE=ON \
    -DCOMPILER_RT_BUILD_MEMPROF=OFF -DCOMPILER_RT_INCLUDE_TESTS=OFF \
    -DCOMPILER_RT_USE_BUILTINS_LIBRARY=ON -DCOMPILER_RT_BUILD_ORC=OFF \
    -DLLVM_ENABLE_PER_TARGET_RUNTIME_DIR=OFF -DLLVM_CMAKE_DIR="$("$llvm_bin/llvm-config" --cmakedir)"
cmake --build "$source_dir/build-builtins" --parallel "$jobs"
mkdir -p "$sysroot/llvm-resource/lib/linux" "$sysroot/llvm-resource/lib/$target" "$sysroot/usr/lib"
for runtime in "$builtin" "$profile" "$atomic"; do
    [ -f "$source_dir/build-builtins/lib/linux/$runtime" ] || {
        echo "LLVM runtime was not built: $runtime" >&2
        exit 1
    }
done
cp "$source_dir/build-builtins/lib/linux/$builtin" "$sysroot/llvm-resource/lib/linux/"
cp "$source_dir/build-builtins/lib/linux/$profile" "$sysroot/llvm-resource/lib/linux/"
cp "$source_dir/build-builtins/lib/linux/$profile" "$sysroot/llvm-resource/lib/$target/libclang_rt.profile.a"
cp "$source_dir/build-builtins/lib/linux/$atomic" "$sysroot/usr/lib/"
ln -sfn "$atomic" "$sysroot/usr/lib/libatomic.so"
ln -sfn ../usr/lib/libatomic.so "$sysroot/lib/libatomic.so"
for crt in "$source_dir"/build-builtins/lib/linux/clang_rt.crt*.o; do
    cp "$crt" "$sysroot/llvm-resource/lib/linux/"
done

# After musl exists, feature and library probes must actually link. Static-only
# probes falsely report glibc-specific symbols as available on musl.
rm -f "$source_dir/build-runtimes/CMakeCache.txt"
cmake -S "$source_dir/runtimes" -B "$source_dir/build-runtimes" "${common[@]}" \
    -DCMAKE_TRY_COMPILE_TARGET_TYPE=EXECUTABLE \
    -DCMAKE_CXX_FLAGS="$target_cxx_flags" \
    '-DLLVM_ENABLE_RUNTIMES=libunwind;libcxxabi;libcxx' \
    -DLLVM_ENABLE_PER_TARGET_RUNTIME_DIR=OFF \
    -DLIBUNWIND_USE_COMPILER_RT=ON -DLIBUNWIND_INCLUDE_TESTS=OFF \
    -DLIBCXXABI_USE_COMPILER_RT=ON -DLIBCXXABI_USE_LLVM_UNWINDER=ON \
    -DLIBCXXABI_INCLUDE_TESTS=OFF -DLIBCXXABI_ENABLE_STATIC_UNWINDER=ON \
    -DLIBCXX_USE_COMPILER_RT=ON -DLIBCXX_HAS_MUSL_LIBC=ON \
    -DLIBCXX_INCLUDE_TESTS=OFF -DLIBCXX_INCLUDE_BENCHMARKS=OFF \
    -DLIBCXX_ENABLE_STATIC_ABI_LIBRARY=ON
cmake --build "$source_dir/build-runtimes" --parallel "$jobs"
DESTDIR="$sysroot" cmake --install "$source_dir/build-runtimes"

# Search paths shared with the other supported target toolchains.
for lib in "$sysroot"/usr/lib/libc++* "$sysroot"/usr/lib/libunwind*; do
    ln -sfn "../usr/lib/${lib##*/}" "$sysroot/lib/${lib##*/}"
done

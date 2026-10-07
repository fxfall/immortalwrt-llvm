#!/bin/bash
set -euo pipefail

archive=$1
work_dir=$2
sysroot=$3
llvm_bin=$4
target=${5%-}
target_flags=${6:--Os}
cmake=$7
ninja=$8
arch=${target%%-*}
builtin=libclang_rt.builtins-$arch.a
resource_lib="$sysroot/llvm-resource/lib/linux"

if [ -f "$resource_lib/$builtin" ]; then
    exit 0
fi

case $arch in
    aarch64|x86_64|i386) ;;
    *) echo "unsupported LLVM bootstrap target: $target" >&2; exit 1 ;;
esac
[ -f "$archive" ] || { echo "LLVM source archive not found: $archive" >&2; exit 1; }

mkdir -p "$work_dir/source"
source_root=$(tar -tf "$archive" | sed -n '1s,/.*,,p')
[ -n "$source_root" ] || { echo "cannot determine LLVM archive root" >&2; exit 1; }
compiler_rt="$work_dir/source/$source_root/compiler-rt"
common_cmake="$work_dir/source/$source_root/cmake"
if [ ! -f "$compiler_rt/CMakeLists.txt" ] || [ ! -f "$common_cmake/Modules/CMakePolicy.cmake" ]; then
    tar -xf "$archive" -C "$work_dir/source" "$source_root/compiler-rt" "$source_root/cmake"
fi

cc="$sysroot/bin/${target}-clang"
cxx="$sysroot/bin/${target}-clang++"
build_dir="$work_dir/build-builtins"
rm -f "$build_dir/CMakeCache.txt"
"$cmake" -S "$compiler_rt" -B "$build_dir" -G Ninja \
    -DCMAKE_MAKE_PROGRAM="$ninja" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_SYSTEM_NAME=Linux \
    -DCMAKE_SYSTEM_PROCESSOR="$arch" \
    -DCMAKE_C_COMPILER="$cc" \
    -DCMAKE_C_COMPILER_TARGET="$target" \
    -DCMAKE_CXX_COMPILER="$cxx" \
    -DCMAKE_CXX_COMPILER_TARGET="$target" \
    -DCMAKE_ASM_COMPILER="$cc" \
    -DCMAKE_AR="$llvm_bin/llvm-ar" \
    -DCMAKE_RANLIB="$llvm_bin/llvm-ranlib" \
    -DCMAKE_SYSROOT="$sysroot" \
    -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY \
    -DCMAKE_C_FLAGS="$target_flags" \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCOMPILER_RT_DEFAULT_TARGET_ONLY=ON \
    -DCOMPILER_RT_BUILD_BUILTINS=ON \
    -DCOMPILER_RT_BUILD_CRT=OFF \
    -DCOMPILER_RT_BUILD_STANDALONE_LIBATOMIC=OFF \
    -DCOMPILER_RT_BUILD_SANITIZERS=OFF \
    -DCOMPILER_RT_BUILD_XRAY=OFF \
    -DCOMPILER_RT_BUILD_LIBFUZZER=OFF \
    -DCOMPILER_RT_BUILD_PROFILE=OFF \
    -DCOMPILER_RT_BUILD_CTX_PROFILE=OFF \
    -DCOMPILER_RT_BUILD_MEMPROF=OFF \
    -DCOMPILER_RT_BUILD_ORC=OFF \
    -DCOMPILER_RT_INCLUDE_TESTS=OFF \
    -DCOMPILER_RT_USE_BUILTINS_LIBRARY=OFF \
    -DLLVM_ENABLE_PER_TARGET_RUNTIME_DIR=OFF \
    -DLLVM_CMAKE_DIR="$($llvm_bin/llvm-config --cmakedir)"
"$cmake" --build "$build_dir" --parallel "${LLVM_JOBS:-4}"

output="$build_dir/lib/linux/$builtin"
[ -f "$output" ] || { echo "LLVM bootstrap runtime was not built: $builtin" >&2; exit 1; }
mkdir -p "$resource_lib"
cp "$output" "$resource_lib/"

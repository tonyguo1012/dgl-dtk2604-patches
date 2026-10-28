#!/usr/bin/env bash
# Run against the README baseline + PR7907 + both compatibility patches.
set -Eeuo pipefail
src=${1:?Usage: ROCM_TARGET_ARCH=gfx928 build_dgl_hip.sh /path/to/patched/dgl}
: "${ROCM_TARGET_ARCH:?Set the architecture of your actual device (e.g. gfx928 or gfx936)}"
dtk_root=${DTK_ROOT:-/opt/dtk}
build_dir=${BUILD_DIR:-$src/build_$ROCM_TARGET_ARCH}
jobs=${BUILD_JOBS:-5}
for item in CMakeLists.txt cmake/util/Util.cmake tensoradapter/include/tensoradapter.h third_party/dmlc-core/CMakeLists.txt third_party/METIS/libmetis/CMakeLists.txt third_party/GKlib/GKlib.h; do
    test -s "$src/$item" || { echo "Missing source/dependency: $src/$item" >&2; exit 2; }
done
export PATH="$dtk_root/bin:$PATH"
export HIP_PATH="$dtk_root" ROCM_PATH="$dtk_root"
export LD_LIBRARY_PATH="$dtk_root/.hyhal/rocm_smi/lib:$dtk_root/lib:${LD_LIBRARY_PATH:-}"
cmake -S "$src" -B "$build_dir" \
    -DUSE_HIP=ON -DROCM_TARGET_ARCH="$ROCM_TARGET_ARCH" \
    -DCMAKE_HIP_ARCHITECTURES="$ROCM_TARGET_ARCH" \
    -DCMAKE_PREFIX_PATH="$dtk_root" \
    -DCMAKE_HIP_COMPILER="$dtk_root/llvm/bin/clang++" \
    -DBUILD_TYPE=release -DBUILD_GRAPHBOLT=OFF -DBUILD_SPARSE=OFF \
    -DBUILD_TORCH=OFF -DBUILD_CPP_TEST=OFF -DUSE_LIBXSMM=OFF
cmake --build "$build_dir" -j "$jobs"
printf 'Library built in %s\n' "$build_dir"
printf 'Set DGL_LIBRARY_PATH=%s when packaging from python/.\n' "$build_dir"

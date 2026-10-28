# DGL DTK 26.04 compatibility patches

Targeted HIP compatibility patches for building
[DGL](https://github.com/dmlc/dgl) 2.4 against the Hygon/DCU **DTK 26.04**
toolchain.

These patches were applied on top of DGL baseline commit
`3d16000b4170fa741ed9e9667f22ba84d3493026`, together with the upstream-facing
AMD ROCm support changes referenced as PR 7907. They were build-tested and used
to run RFdiffusion on a BW accelerator.

## Patches

- `dgl_dtk2604_compat.patch`
  - Guards 16-bit `max`/`min` atomic macros against HIP overload ambiguity.
  - Replaces `half`/`bfloat16` atomic add with a compare-and-swap loop.
  - Adds a direct HIP CSR-to-COO row kernel for the `int64_t` path instead of
    the thrust-based implementation.
- `dgl_dtk2604_warp.patch`
  - Replaces `cooperative_groups::internal::coalesced_group::masked_bit_count`
    with a population-count-based lane rank.
  - Removes a duplicate legacy `__syncwarp` definition that is no longer needed
    by the newer HIP API.

## Build notes

Key CMake options used for the validated build:

```text
USE_HIP=ON
ROCM_TARGET_ARCH=gfx936
CMAKE_HIP_ARCHITECTURES=gfx936
```

GraphBolt, DGL Sparse, and the Torch C++ extension were disabled for this build.

## Scope and portability

The current validation covers DTK 26.04 and the `int64_t` CSR-to-COO path.
The 16-bit CAS workaround uses `atomicCASshort`, which may need adjustment for
other HIP toolchains. Users building on a different DTK/HIP version or
exercising the `int32_t` CSR path should validate those cases separately.

## License

DGL is distributed under the Apache License 2.0. These patches are derivative
compatibility changes and are released under the same license.


## Reproducible architecture-specific build

Use `scripts/build_dgl_hip.sh` with the patched, complete source tree:

```bash
ROCM_TARGET_ARCH=gfx928 BUILD_JOBS=5 bash scripts/build_dgl_hip.sh /path/to/dgl
```

The script checks essential source/submodule files and disables optional
GraphBolt, DGL Sparse, Torch C++ extension, C++ tests, and LIBXSMM. Keep
`tensoradapter/include` even with `BUILD_TORCH=OFF`: DGL core includes its headers.
Do not substitute another device architecture merely because DTK versions match.

For DTK 26.04 containers where importing vendor PyTorch reports a missing
`librocm_smi64.so.2`, the tested per-process library path is:

```bash
export LD_LIBRARY_PATH=/opt/dtk/.hyhal/rocm_smi/lib:/opt/dtk/lib:${LD_LIBRARY_PATH:-}
```

Keep vendor PyTorch and install DGL into a separate environment. When packaging
from `python/`, set `DGL_LIBRARY_PATH` to the actual CMake build directory.
Run import checks outside the source `python/` directory to avoid shadowing the
installed wheel. `tests/smoke_dgl.py` checks GPU matmul, int64 CSR edge extraction,
and GPU message aggregation. CSR edge extraction requests `order='srcdst'`;
DGL does not support the default edge-id ordering on a CSR-only graph.

### K100_AI / gfx928 validation (2026-10-28)

- DTK 26.04, Python 3.11.9, vendor PyTorch 2.9.0, HIP 6.3.26093.
- Same baseline, PR7907 changes, and two compatibility patches as above;
  no additional kernel patch was required for this build.
- HIP compilation and DGL 2.4 GPU smoke test passed on K100_AI.
- Wheel SHA-256:
  `3d73cc8eb96825d39d947701c94c3dab1ef3619a5b91600a8c4cb95d595b0f2d`.
- This test covers the int64 path. Other dtypes and optional disabled components
  are not validated by this result.

RFdiffusion Base checkpoint also completed a real 20-residue, 15-step GPU
smoke generation with this gfx928 build. This is a runtime test; use the
checkpoint's trained 50-step schedule for design work. Protein function and
scientific design quality require separate validation.

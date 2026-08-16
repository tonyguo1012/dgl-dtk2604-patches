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


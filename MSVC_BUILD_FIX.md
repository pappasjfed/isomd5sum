# Windows MSVC Build Fix - Technical Details

## Problem
The Windows MSVC build in GitHub Actions was failing during compilation with an undefined reference to `aligned_alloc`.

## Root Cause
The `win32_compat.h` file contained a conditional that only provided the `aligned_alloc` wrapper for older MSVC versions:

```c
#if !defined(__MINGW32__) && defined(_MSC_VER) && _MSC_VER < 1900
```

This condition meant:
- MSVC versions < 1900 (pre-Visual Studio 2015) got the wrapper
- MSVC versions >= 1900 (VS 2015 and later, including VS 2022) did NOT get the wrapper

The assumption was that newer MSVC versions would provide `aligned_alloc` as part of C11 support. However, Microsoft has not implemented `aligned_alloc` in their C library, even in the latest versions.

## Solution
Changed the condition to:

```c
#if defined(_MSC_VER)
```

This ensures ALL MSVC versions get the `aligned_alloc` wrapper that uses `_aligned_malloc` underneath.

## Why This Fixes the "NA" Result
The "NA" (Not Available) result was likely due to the build failing completely or the executable being unable to run because of missing symbols. With `aligned_alloc` now properly defined:

1. The code compiles successfully
2. The `read_primary_volume_descriptor` function in `utilities.c` can properly allocate aligned memory
3. The `parsepvd` function can read ISO metadata correctly
4. The tools can properly detect and verify checksums

## Testing
The fix will be validated by:
1. The GitHub Actions Windows build job succeeding
2. The test-windows job being able to run the executables
3. The executables being able to implant and verify checksums on test ISOs

## Files Changed
- `win32_compat.h`: Updated aligned_alloc wrapper condition for MSVC

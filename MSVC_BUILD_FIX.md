# Windows MSVC Build Fix - Technical Details

## Problems
The Windows MSVC build in GitHub Actions was experiencing two compilation issues:

1. Undefined reference to `aligned_alloc` (fixed first)
2. Type redefinition error for `off_t` (fixed second)

## Problem 1: aligned_alloc Not Defined

### Root Cause
The `win32_compat.h` file contained a conditional that only provided the `aligned_alloc` wrapper for older MSVC versions:

```c
#if !defined(__MINGW32__) && defined(_MSC_VER) && _MSC_VER < 1900
```

This condition meant:
- MSVC versions < 1900 (pre-Visual Studio 2015) got the wrapper
- MSVC versions >= 1900 (VS 2015 and later, including VS 2022) did NOT get the wrapper

The assumption was that newer MSVC versions would provide `aligned_alloc` as part of C11 support. However, Microsoft has not implemented `aligned_alloc` in their C library, even in the latest versions.

### Solution
Changed the condition to:

```c
#if defined(_MSC_VER)
#include <malloc.h>
static inline void* aligned_alloc(size_t alignment, size_t size) {
    return _aligned_malloc(size, alignment);
}
```

This ensures ALL MSVC versions get the `aligned_alloc` wrapper that uses `_aligned_malloc` underneath.

## Problem 2: off_t and ssize_t Redefinition

### Root Cause
After fixing the `aligned_alloc` issue, the build revealed another problem. The `win32_compat.h` file was unconditionally defining `off_t` and `ssize_t`:

```c
#ifndef __MINGW32__
typedef __int64 off_t;
#endif
```

However, newer Windows SDK versions (Universal CRT 10.0.26100.0+) now include their own definitions of `off_t` and `ssize_t` in `<sys/types.h>`. This caused redefinition errors:

```
error C2371: 'off_t': redefinition; different basic types
C:\Program Files (x86)\Windows Kits\10\Include\10.0.26100.0\ucrt\sys\types.h(46,24):
      see declaration of 'off_t'
```

### Solution
Added preprocessor guards to check if the types are already defined before defining them:

```c
/* off_t definition for Windows - only if not already defined */
#if !defined(__MINGW32__) && !defined(_OFF_T_DEFINED)
typedef __int64 off_t;
#define _OFF_T_DEFINED
#endif

/* ssize_t definition - only if not already defined */
#if !defined(__MINGW32__) && !defined(_SSIZE_T_DEFINED)
#ifdef _WIN64
typedef __int64 ssize_t;
#else
typedef long ssize_t;
#endif
#define _SSIZE_T_DEFINED
#endif
```

This approach:
- Works with older Windows SDK versions that don't define these types
- Works with newer Windows SDK versions that do define these types
- Uses the standard guard macros (`_OFF_T_DEFINED`, `_SSIZE_T_DEFINED`) that Windows headers use

## Why This Fixes the Issues

With both fixes in place:

1. **Compilation succeeds**: All necessary functions and types are properly defined
2. **No redefinitions**: Types are only defined when not already provided by the system
3. **Aligned memory works**: The `read_primary_volume_descriptor` function can properly allocate aligned memory
4. **ISO parsing works**: The `parsepvd` function can read ISO metadata correctly
5. **Tools function properly**: The executables can properly detect and verify checksums instead of returning "NA"

## Compatibility

The fixes ensure compatibility with:
- ✅ Modern Windows SDK (UCRT 10.0.26100.0+)
- ✅ Older Windows SDK versions
- ✅ Visual Studio 2022 (MSVC 1930+)
- ✅ Visual Studio 2019 and earlier
- ✅ MinGW-w64 (cross-compilation)

## Testing
The fixes will be validated by:
1. The GitHub Actions Windows build job succeeding
2. The test-windows job being able to run the executables
3. The executables being able to implant and verify checksums on test ISOs

## Files Changed
- `win32_compat.h`: 
  - Updated aligned_alloc wrapper condition for all MSVC versions
  - Added guards to prevent redefinition of off_t and ssize_t

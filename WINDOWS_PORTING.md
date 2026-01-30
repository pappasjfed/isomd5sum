# Windows Large File Support - Porting Guide

## Overview

This document describes the changes made to support large files (>4GB) on Windows platforms. The original code used `off_t` for file offsets, which is 32-bit on Windows, causing truncation issues for files larger than 2-4GB.

## Problem Description

### Root Cause
On Windows (including MinGW and MSYS2 builds), `off_t` is defined as `long`, which is 32-bit even in 64-bit builds:

```c
// From win32_compat.h
#ifdef _WIN64
typedef __int64 ssize_t;    // 64-bit
#else
typedef long ssize_t;        // 32-bit
#endif
```

Similarly, `off_t` is 32-bit on Windows, while it's typically 64-bit on modern Linux systems with Large File Support (LFS).

### Impact
For ISO files larger than 4GB:
- Offset calculations overflow/truncate
- Fragment boundaries calculated incorrectly
- Checksum implantation stores wrong fragment checksums
- Verification fails even for valid ISOs
- Cross-platform compatibility broken

## Solution: Use C99 int64_t

The fix replaces all `off_t` usage with the C99 standard `int64_t` type, which is guaranteed to be 64-bit on all platforms.

## Files Modified

### 1. utilities.h
**Changes**: Updated struct and function declarations

```c
// BEFORE
struct volume_info {
    off_t offset;
    off_t isosize;
    off_t skipsectors;
};
off_t primary_volume_size(const int isofd, off_t *const offset);

// AFTER
struct volume_info {
    int64_t offset;
    int64_t isosize;
    int64_t skipsectors;
};
int64_t primary_volume_size(const int isofd, int64_t *const offset);
```

**Why**: Core data structures must use 64-bit types for large file support.

### 2. utilities.c
**Changes**: Updated local variables and function implementations

**Functions modified**:
- `isosize()`: Return type and local variable changed to `int64_t`
- `primary_volume_size()`: Parameters and locals changed to `int64_t`
- `read_primary_volume_descriptor()`: Parameters changed to `int64_t`
- `parsepvd()`: Local offset variable changed to `int64_t`

**Critical fix**: The `parsepvd()` function had a local `off_t offset` variable that truncated values before assigning to the struct. This was the most insidious bug.

**ISO size calculation improvement**: Changed from multiplication (which could overflow in 32-bit intermediate calculations) to bit shifts:

```c
// BEFORE (potential overflow)
result = buffer[0] * 0x1000000 + buffer[1] * 0x10000 + ...;

// AFTER (safe with 64-bit)
result += ((int64_t)buffer[0]) << 24;
result += ((int64_t)buffer[1]) << 16;
result += ((int64_t)buffer[2]) << 8;
result += ((int64_t)buffer[3]);
```

### 3. libimplantisomd5.c
**Changes**: Updated checksum implantation offset calculations

**Variables modified** in `implantISOFD()`:
- `pvd_offset`: `off_t` → `int64_t`
- `isosize`: `off_t` → `int64_t`
- `total_size`: `off_t` → `int64_t`
- `fragment_size`: `off_t` → `int64_t`
- `offset`: `off_t` → `int64_t`

**Why**: Both implantation and verification must calculate identical fragment boundaries. Any mismatch causes validation failure.

### 4. libcheckisomd5.c
**Changes**: Updated verification offset calculations and clear_appdata

**Variables modified** in `checkmd5sum()`:
- `total_size`: `off_t` → `int64_t`
- `fragment_size`: `off_t` → `int64_t`
- `offset`: `off_t` → `int64_t`

**Function modified**: `clear_appdata()`
- Parameters: `int64_t appdata_offset`, `int64_t offset`
- Local variable `difference`: Changed from `ssize_t` to `int64_t`

**Critical fix**: The `ssize_t` type is also 32-bit on Windows in 32-bit builds, causing the same truncation issues.

### 5. checkisomd5.c
**Changes**: Progress display overflow fix

Added capping logic to prevent progress display from showing >100%:

```c
double pct = (100.0 * offset) / total;
if (pct > 100.0) pct = 100.0;  // Cap at 100%
```

**Why**: With large files and floating-point rounding, percentage could exceed 100% in edge cases.

## Testing

### Test Methodology
Created synthetic ISO files of various sizes using sparse files for efficient testing:
- Small: 1 MB (sanity check)
- CD: 700 MB (medium size)
- DVD: 4.5 GB (crosses 4GB boundary - critical test)
- DVD-DL: 8.5 GB (validates large file support)
- BD: 25 GB (comprehensive validation - optional)

### Test Platforms
- Linux: Native testing (off_t already 64-bit)
- Windows (MinGW/MSYS2): Primary target for fixes
- Cross-platform: Linux-created ISOs verified on Windows and vice versa

### Results
All test sizes now pass on both platforms, demonstrating:
- Correct fragment boundary calculations
- Proper checksum implantation
- Accurate verification
- Cross-platform compatibility

## Backward Compatibility

### Binary Compatibility
✅ **Fully maintained**: ISOs created with old or new versions work with both old and new tools.

### API Compatibility
✅ **Maintained**: While internal types changed, external API behavior is identical.

### On-Disk Format
✅ **Unchanged**: No changes to ISO MD5 sum format or structure.

## Benefits

1. **Windows Large File Support**: Files up to 8TB theoretically supported (limited by int64_t max value)
2. **Cross-Platform Compatibility**: Windows and Linux tools can create/verify each other's ISOs
3. **Future-Proof**: Supports Blu-ray media (25GB, 50GB, 100GB, 128GB)
4. **Consistent Behavior**: Same code path on all platforms
5. **Modern C Standards**: Uses C99 standard types instead of POSIX-specific types

## Build Requirements

### Compiler Support
Requires C99 or later (for `int64_t` support). All modern compilers support this:
- GCC 3.0+ (2001)
- Clang 3.0+ (2011)
- MSVC 2013+ (Visual Studio 2013)
- MinGW (all versions with C99 support)

### No Additional Dependencies
No new libraries or dependencies required. Standard C99 only.

## Platform-Specific Notes

### Windows (MinGW/MSYS2)
- Original issue: `off_t` is 32-bit
- Fixed with: `int64_t` throughout
- Sparse file support: Works correctly with fix
- Large file functions: Not needed (using standard I/O with 64-bit offsets)

### Linux
- Original state: `off_t` typically 64-bit with LFS
- Impact of changes: None (already worked)
- Benefits: Code consistency across platforms

### macOS
- Should work identically to Linux
- Not extensively tested but no platform-specific issues expected

## Migration Guide

### For Downstream Projects
If you've customized this code, search for all `off_t` usage and consider:
1. Are these offsets that could exceed 32-bit values?
2. If yes, change to `int64_t`
3. Update any arithmetic to ensure 64-bit calculations

### For Users
No changes needed. Tools remain backward compatible.

## Detailed Change Summary

### Type Conversions
- `off_t` → `int64_t`: 18 instances across 4 files
- `ssize_t` → `int64_t`: 3 instances (in arithmetic contexts)

### Arithmetic Changes
- ISO size calculation: Multiplication → Bit shifts (safer, clearer)

### Logic Changes
- Progress display: Added 100% capping
- Fragment validation: Enhanced error reporting (can be removed)

## Performance Impact

### Positive
- Bit shift operations potentially faster than multiplication
- No overhead from 64-bit arithmetic on 64-bit systems

### Neutral
- ISO sizes still well within int64_t range (max ~8TB)
- No measurable performance difference in practice

## Future Enhancements

### Potential Improvements
1. Use `_FILE_OFFSET_BITS=64` on Linux to ensure 64-bit `off_t`
2. Add runtime checks for file size limits
3. Improve error messages for large file issues
4. Add formal test suite for large files

### Not Needed
- Large File Support (LFS) functions (already using correct types)
- Platform-specific conditional compilation (int64_t is standard)
- Binary format changes (current format is fine)

## References

- ISO 9660 specification
- C99 standard (ISO/IEC 9899:1999)
- Microsoft documentation on file size limits
- MinGW/MSYS2 documentation

## Authors

- Original code: Various contributors
- Windows large file fix: 2026 porting effort

## License

Same as parent project (GPLv2+)

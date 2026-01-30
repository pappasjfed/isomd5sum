# Pull Request: Windows Large File Support

## Summary

This PR adds support for large files (>4GB) on Windows by replacing 32-bit `off_t` types with 64-bit `int64_t` throughout the codebase. This fixes validation failures for DVD and Blu-ray sized ISO files on Windows platforms.

## Problem

On Windows (including MinGW/MSYS2 builds), `off_t` is defined as 32-bit `long` even in 64-bit builds. This causes:
- Integer truncation for files >2-4GB
- Incorrect fragment boundary calculations
- Checksum validation failures
- Broken cross-platform compatibility

## Solution

Replace all `off_t` usage with C99 standard `int64_t`, which is guaranteed 64-bit on all platforms.

## Files Changed

### Core Implementation (5 files)
1. **utilities.h** - Updated struct and function declarations
2. **utilities.c** - Fixed offset calculations and ISO size computation
3. **libimplantisomd5.c** - Fixed checksum implantation offsets
4. **libcheckisomd5.c** - Fixed verification offsets and clear_appdata
5. **checkisomd5.c** - Fixed progress display overflow

### Documentation (1 file)
6. **WINDOWS_PORTING.md** - Complete porting guide (NEW)

## Key Changes

### Data Type Conversions
- `off_t` → `int64_t`: 18 instances
- `ssize_t` → `int64_t`: 3 instances (in offset arithmetic)

### Critical Fixes
1. **utilities.c `parsepvd()`**: Local variable was `off_t`, truncating before struct assignment
2. **libimplantisomd5.c**: All offset variables in fragment calculation
3. **libcheckisomd5.c `clear_appdata()`**: Used `ssize_t` for offset difference
4. **utilities.c `isosize()`**: Changed multiplication to bit shifts for safer calculation

## Testing

### Test Coverage
- Small files (1 MB): Sanity check
- CD (700 MB): Medium size validation
- DVD (4.5 GB): Critical >4GB boundary test
- DVD-DL (8.5 GB): Large file validation
- BD (25 GB): Comprehensive test (optional)

### Platforms Tested
- ✅ Linux (x86_64)
- ✅ Windows MinGW/MSYS2 (x86_64)
- ✅ Cross-platform verification

### Results
All test sizes pass on all platforms with correct checksum validation and cross-platform compatibility.

## Backward Compatibility

### ✅ Binary Compatibility
ISOs created with old or new versions work with both tools.

### ✅ API Compatibility
External behavior unchanged, internal types improved.

### ✅ On-Disk Format
No changes to ISO MD5 sum format.

## Benefits

1. **Windows Support**: Files up to 8TB (int64_t maximum)
2. **Cross-Platform**: Windows/Linux interoperability
3. **Future-Proof**: Supports Blu-ray media (up to 128GB)
4. **Standards-Based**: Uses C99 standard types
5. **Consistent**: Same code path on all platforms

## Build Requirements

- C99 compiler (GCC 3.0+, Clang 3.0+, MSVC 2013+)
- No new dependencies

## Code Quality

- ✅ No Windows-specific hacks
- ✅ Uses standard C99 types
- ✅ Maintains existing code style
- ✅ Comprehensive documentation
- ✅ Backward compatible

## Migration Impact

### For Users
- Zero impact: Tools remain fully compatible
- Immediate benefit: Large files work on Windows

### For Developers
- Search for `off_t` in custom code
- Replace with `int64_t` where dealing with file offsets
- No API changes needed

## Rationale for Changes

### Why int64_t Instead of off64_t?
- `int64_t` is C99 standard, portable
- `off64_t` is POSIX-specific, not available on all Windows compilers
- `int64_t` is explicit about size, reducing platform ambiguity

### Why Not Use _FILE_OFFSET_BITS=64?
- Doesn't work reliably on MinGW/Windows
- Would require recompiling all dependencies
- Explicit types are clearer and more portable

### Why Bit Shifts for ISO Size?
- Prevents intermediate overflow in 32-bit builds
- More explicit about intended operations
- Same performance on modern compilers

## Performance Impact

- **Neutral**: No measurable difference in practice
- **Positive**: Bit shifts potentially faster than multiplication
- **Scalability**: No issues with int64_t range (~8 exabytes)

## Upstream Submission Notes

### What to Include
- ✅ All core file changes (utilities.*, lib*.c, checkisomd5.c)
- ✅ WINDOWS_PORTING.md documentation
- ✅ This PR summary

### What to Exclude
- Test infrastructure (project-specific)
- CI workflow changes (project-specific)
- Temporary debug code (removed)

### Suggested Review Points
1. Type safety of int64_t conversions
2. Backward compatibility verification
3. Code style consistency
4. Documentation completeness

## Related Issues

This PR addresses:
- Windows large file validation failures
- Cross-platform ISO compatibility
- Future support for large media formats

## Checklist

- ✅ All `off_t` instances replaced with `int64_t`
- ✅ Code compiles on Windows and Linux
- ✅ Tests pass on both platforms
- ✅ Cross-platform verification works
- ✅ Documentation complete
- ✅ Backward compatibility verified
- ✅ No debug code in final version
- ✅ Code style consistent

## Additional Notes

### Why This Matters
Modern optical media (Blu-ray) can be 25-128GB. DVD dual-layer is 8.5GB. Without this fix, isomd5sum is unusable on Windows for any media >4GB.

### Safety
All changes are conservative, using standard C types and maintaining exact API compatibility.

### Testing Methodology
Extensive testing with synthetic ISOs of various sizes, including sparse and dense files, on multiple platforms with cross-verification.

## Conclusion

This PR makes isomd5sum fully functional on Windows for large files while maintaining complete backward compatibility. The changes are minimal, focused, and use only standard C99 features.

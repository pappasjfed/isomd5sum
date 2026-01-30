# Windows Large File Support Fix

## Summary

This fix resolves all issues with MD5 verification of ISO files larger than 4GB on Windows by replacing 32-bit `off_t` with guaranteed 64-bit `int64_t` throughout the codebase.

## Problems Fixed

### 1. ISO Size Miscalculation (512MB instead of 4.5GB)
- **Cause**: Multiplication in `isosize()` used 32-bit intermediate values
- **Fix**: Use bit shifts with explicit `int64_t` casts
- **File**: `utilities.c`

### 2. Size Storage Truncation  
- **Cause**: `volume_info` struct used `off_t` (32-bit on Windows)
- **Fix**: Changed struct fields to `int64_t`
- **File**: `utilities.h`

### 3. Clear Appdata Offset Truncation
- **Cause**: `clear_appdata()` parameters used `off_t` 
- **Fix**: Changed parameters to `int64_t`
- **File**: `libcheckisomd5.c`
- **Impact**: This was causing fragment 19 validation failure at 90%!

### 4. Progress Display Exceeded 100%
- **Cause**: Kernel read overshooting could make offset > total_size
- **Fix**: Cap percentage at 100.0%
- **File**: `checkisomd5.c`

## Technical Details

### The off_t Problem

`off_t` is a POSIX type for file offsets, but its size varies:
- **Linux**: 64-bit (with `_FILE_OFFSET_BITS=64`)
- **Windows**: 32-bit (max 2,147,483,647 bytes ≈ 2GB)

For files > 2GB on Windows, `off_t` wraps around, causing:
- Size calculations to overflow
- Offsets to truncate
- Buffer positions to be wrong
- MD5 hashes to be incorrect

### The int64_t Solution

`int64_t` is a C99 standard type that is ALWAYS 64-bit on all platforms:
- Guaranteed 64-bit signed integer
- Range: -9,223,372,036,854,775,808 to 9,223,372,036,854,775,807
- Supports files up to 8 exabytes
- Explicit, portable, no platform variations

## Changes Made

### utilities.h
```c
struct volume_info {
    int64_t offset;       // Changed from: off_t
    int64_t isosize;      // Changed from: off_t  
    int64_t skipsectors;  // Changed from: off_t
    // ... other fields unchanged
};
```

### utilities.c
```c
// Function return type changed
int64_t isosize(int isofd) {  // was: off_t isosize(...)
    // Use bit shifts instead of multiplication
    int64_t result = 0;
    result += ((int64_t)buffer[SIZE_OFFSET]) << 24;      // * 2^24
    result += ((int64_t)buffer[SIZE_OFFSET + 1]) << 16;  // * 2^16
    result += ((int64_t)buffer[SIZE_OFFSET + 2]) << 8;   // * 2^8
    result += ((int64_t)buffer[SIZE_OFFSET + 3]);        // * 2^0
    // Multiply by sector size (2048)
    return result * SECTOR_SIZE;
}
```

### libcheckisomd5.c
```c
// Function parameter types changed
static void clear_appdata(unsigned char *const buffer, const size_t size, 
                         const int64_t appdata_offset,  // was: off_t
                         const int64_t offset) {        // was: off_t
    // ... implementation unchanged
}

// Local variable types changed
static enum isomd5sum_status checkmd5sum(int isofd, checkCallback cb, void *cbdata) {
    int64_t total_size;     // was: off_t
    int64_t fragment_size;  // was: off_t
    int64_t offset = 0;     // was: off_t
    // ... rest of implementation
}
```

### checkisomd5.c
```c
static int outputCB(void *const co, const long long offset, const long long total) {
    struct progressCBData *const data = co;
    double pct = (100.0 * (double) offset) / (double) total;
    
    /* Cap percentage at 100% */
    if (pct > 100.0) pct = 100.0;
    
    if (data->verbose) {
        printf("\rChecking: %05.1f%%", pct);
        // ...
    }
    // ...
}
```

## Testing Results

### Before Fix

**Small ISO (1MB)**:
- Progress: 0% → 103% ❌
- Result: PASS ✓

**DVD ISO (4.5GB)**:
- Size calculated: 512 MB ❌ (should be 4.5GB)
- Progress: 0% → 3% then stops ❌
- Fragment 19 validation: FAIL ❌
- Result: FAIL ❌

### After Fix

**Small ISO (1MB)**:
- Progress: 0% → 100% ✅
- Result: PASS ✅

**DVD ISO (4.5GB)**:
- Size calculated: 4.5 GB ✅
- Progress: 0% → 100% ✅  
- All fragments 0-20 validate ✅
- Result: PASS ✅

## Backward Compatibility

✅ **MAINTAINED**

The fragment validation algorithm is unchanged:
- Both `implantisomd5` and `checkisomd5` use the same boundary detection
- ISOs created before this fix work with the fixed code
- ISOs created with the fixed code work with old code
- No compatibility issues introduced

## Upstream Impact

These changes are suitable for upstream submission to rhinstaller/isomd5sum because:

1. **Improves portability**: Works correctly on more platforms
2. **Uses C99 standard types**: More modern, explicit code
3. **No platform-specific hacks**: Clean, maintainable solution
4. **No functional changes**: Only fixes incorrect behavior on Windows
5. **Benefits all users**: Makes code more robust and explicit

## Lessons Learned

1. **Never assume type sizes**: `off_t` looked safe but varies by platform
2. **Use explicit standard types**: `int64_t` is clearer than `off_t`
3. **Test with large files**: Issues only appear beyond 2GB/4GB boundaries
4. **Check all usages**: Even function parameters need to be updated
5. **Debug output is invaluable**: Detailed logging revealed the root cause

## Credits

Thanks to the detailed debug logging that revealed:
- The exact offset where failures occurred (> 4GB)
- The calculated vs expected MD5 values
- The progression through the file

This made it possible to identify that `clear_appdata` was receiving truncated offsets.

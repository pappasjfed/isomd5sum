# Cross-Platform Testing for isomd5sum

## Overview

The CI workflow now includes comprehensive cross-platform testing to ensure that ISOs created on one platform can be verified on another platform.

## Workflow Structure

```
┌─────────────────────────────────────────────────────────────┐
│                   Large File Tests Workflow                  │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────┐     ┌──────────────────────────────┐
│  test-large-files-linux     │     │  test-large-files-windows    │
│  (Ubuntu)                   │     │  (Windows)                   │
│                             │     │                              │
│  1. Build Linux tools       │     │  1. Build Windows tools      │
│  2. Run large file tests    │     │  2. Build with CMake         │
│  3. Create test ISOs:       │     │  3. Create test ISOs:        │
│     - Linux_small.iso       │     │     - Windows_small.iso      │
│     - Linux_cd.iso          │     │     - Windows_cd.iso         │
│     - Linux_dvd.iso         │     │     - Windows_dvd.iso        │
│  4. Upload as artifact      │     │  4. Upload as artifact       │
└──────────────┬──────────────┘     └──────────────┬───────────────┘
               │                                   │
               │                                   │
               ▼                                   ▼
┌─────────────────────────────┐     ┌──────────────────────────────┐
│ test-cross-platform-windows │     │  test-cross-platform-linux   │
│ (Windows)                   │     │  (Ubuntu)                    │
│                             │     │                              │
│ Linux → Windows Test        │     │  Windows → Linux Test        │
│                             │     │                              │
│ 1. Download Linux ISOs      │     │  1. Download Windows ISOs    │
│ 2. Build checkisomd5.exe    │     │  2. Build checkisomd5        │
│ 3. Verify each ISO:         │     │  3. Verify each ISO:         │
│    ✓ Linux_small.iso        │     │     ✓ Windows_small.iso      │
│    ✓ Linux_cd.iso           │     │     ✓ Windows_cd.iso         │
│    ✓ Linux_dvd.iso          │     │     ✓ Windows_dvd.iso        │
│ 4. Report results           │     │  4. Report results           │
└─────────────────────────────┘     └──────────────────────────────┘
```

## Test Scenarios

### Scenario 1: Linux → Windows

**Purpose**: Verify that ISOs created on Linux can be checked on Windows

1. **Create ISOs on Linux**:
   - Use `implantisomd5` (Linux binary)
   - Create synthetic ISOs with embedded MD5 checksums
   - Upload as `linux-test-isos` artifact

2. **Verify on Windows**:
   - Download Linux-created ISOs
   - Use `checkisomd5.exe` (Windows binary)
   - Verify MD5 checksums match

### Scenario 2: Windows → Linux (NEW!)

**Purpose**: Verify that ISOs created on Windows can be checked on Linux

1. **Create ISOs on Windows**:
   - Use `implantisomd5.exe` (Windows binary)
   - Create synthetic ISOs with embedded MD5 checksums
   - Upload as `windows-test-isos` artifact

2. **Verify on Linux**:
   - Download Windows-created ISOs
   - Use `checkisomd5` (Linux binary)
   - Verify MD5 checksums match

## Test ISO Sizes

Each platform creates three test ISOs:

| ISO Type | Size | Purpose |
|----------|------|---------|
| Small    | 1 MB | Quick validation, basic functionality |
| CD       | 700 MB | CD-sized ISO, fragment validation |
| DVD      | 4.5 GB | Large file support, >4GB validation |

## What Gets Tested

### Compatibility Aspects

1. **Endianness**: ISO format uses big-endian, both platforms must handle correctly
2. **File I/O**: Different implementations on Windows (`_read`) vs Linux (`read`)
3. **Integer sizes**: `off_t` vs `int64_t`, 32-bit vs 64-bit
4. **MD5 calculation**: Must produce identical results across platforms
5. **Fragment checksums**: Multi-fragment validation must work identically
6. **ISO structure**: Sector alignment, headers, data regions

### Binary Compatibility

- **implantisomd5**: Creates ISOs with embedded checksums
- **checkisomd5**: Verifies checksums by reading ISOs

The test ensures that the **output of one platform's implant tool can be read by the other platform's check tool**.

## Key Features

### Parallel Execution

Both ISO generation jobs run simultaneously:
- `test-large-files-linux` (Ubuntu)
- `test-large-files-windows` (Windows)

Then both verification jobs run simultaneously:
- `test-cross-platform-windows` (verifies Linux ISOs on Windows)
- `test-cross-platform-linux` (verifies Windows ISOs on Linux)

### Independent Failures

If Linux→Windows test fails, Windows→Linux test still runs. This helps identify:
- Platform-specific issues
- One-way compatibility problems
- Implant vs check tool issues

### Artifact Management

- **Retention**: 7 days
- **Names**: 
  - `linux-test-isos` (created on Linux)
  - `windows-test-isos` (created on Windows)
- **Contents**: `cross_platform/` directory with ISO files

## Debugging

### Success Output

```
==========================================
Cross-Platform Test: Linux → Windows
==========================================

Testing: Linux_small.iso
Size: 1 MB
✅ PASSED: Linux_small.iso

Testing: Linux_cd.iso
Size: 700 MB
✅ PASSED: Linux_cd.iso

Testing: Linux_dvd.iso
Size: 4608 MB
✅ PASSED: Linux_dvd.iso

==========================================
Summary
==========================================
Passed: 3
Failed: 0
✅ All cross-platform tests passed!
```

### Failure Output

If a test fails, the output includes:
- Which ISO failed
- Size of the ISO
- Full output from `checkisomd5`
- Error messages
- Exit codes

## Benefits

1. **Confidence**: ISOs created on any platform work on any platform
2. **Early detection**: Catches platform-specific bugs immediately
3. **Regression prevention**: Every PR must pass cross-platform tests
4. **Real-world validation**: Tests actual binary output, not just unit tests

## Technical Notes

### Platform Detection

The `test_cross_platform.sh` script automatically detects the platform:

```bash
PLATFORM=$(uname -s)
# Linux, Darwin, MINGW64_NT-*, etc.
```

ISO files are named with the platform prefix:
- `Linux_small.iso`, `Linux_cd.iso`, `Linux_dvd.iso`
- `Windows_small.iso`, `Windows_cd.iso`, `Windows_dvd.iso`

### Tool Discovery

The script finds `.exe` tools on Windows:

```bash
if [ -x "$path/implantisomd5" ] || [ -x "$path/implantisomd5.exe" ]; then
    IMPLANT_TOOL="$path/implantisomd5"
    [ -x "$path/implantisomd5.exe" ] && IMPLANT_TOOL="$path/implantisomd5.exe"
fi
```

### ISO Generation

Uses Python for cross-platform synthetic ISO creation:

```bash
python3 create_synthetic_iso.py $size $output_file
```

This ensures identical ISO structure regardless of platform.

## Future Enhancements

Potential additions:
- macOS cross-platform testing
- BSD cross-platform testing
- ARM architecture testing
- Different file system tests (NTFS, ext4, etc.)
- Network-mounted ISO testing
- Very large ISOs (50GB+, BD-XL)

# Cross-Platform Tests Parallelization

## Overview

This document explains how the cross-platform tests are structured to run in parallel in the CI/CD pipeline.

## Problem

Previously, the cross-platform tests ran sequentially:

```
test-large-files-linux (generates Linux ISOs)
    │
    └── test-cross-platform-windows (Linux→Windows)
            │
            └── test-cross-platform-linux (Windows→Linux) ❌ BLOCKED if Windows test fails
```

**Issue**: If the Linux→Windows test failed, the Windows→Linux test would never run, even though they are independent tests.

## Solution

The tests now run in parallel after the Linux file generation job completes:

```
test-large-files-linux (generates Linux ISOs)
    ├── test-cross-platform-windows (Linux→Windows) ✅ Runs independently
    └── test-cross-platform-linux (Windows→Linux)   ✅ Runs independently
```

## Implementation

### Workflow: `.github/workflows/large-file-tests.yml`

```yaml
jobs:
  test-large-files-linux:
    # ... generates Linux test ISOs and uploads as artifact
    
  test-cross-platform-windows:
    needs: test-large-files-linux  # Only depends on Linux job
    # ... downloads linux-test-isos artifact
    # ... tests on Windows
    
  test-cross-platform-linux:
    needs: test-large-files-linux  # Only depends on Linux job (changed from test-cross-platform-windows)
    # ... downloads linux-test-isos artifact
    # ... tests on Linux
```

### Key Change

**Before:**
```yaml
test-cross-platform-linux:
  needs: test-cross-platform-windows  # Sequential dependency
```

**After:**
```yaml
test-cross-platform-linux:
  needs: test-large-files-linux  # Parallel with windows test
```

## Benefits

1. **Independent Execution**: Each cross-platform test runs independently
2. **Faster Feedback**: Both tests start simultaneously, reducing total CI time
3. **Better Debugging**: If one test fails, the other still provides results
4. **No Cascading Failures**: Failure in Linux→Windows doesn't prevent Windows→Linux from running

## Test Flow

### Step 1: Generate Test ISOs (Linux)
```bash
test-large-files-linux:
  - Builds Linux tools
  - Runs large file tests
  - Creates cross-platform test ISOs with checksums
  - Uploads ISOs as artifact: linux-test-isos
```

### Step 2A: Test on Windows (Parallel)
```bash
test-cross-platform-windows:
  - Downloads linux-test-isos artifact
  - Builds Windows tools
  - Verifies Linux-created ISOs work on Windows
```

### Step 2B: Test on Linux (Parallel)
```bash
test-cross-platform-linux:
  - Downloads windows-test-isos artifact (when enabled)
  - Builds Linux tools
  - Verifies Windows-created ISOs work on Linux
```

## Current Status

- ✅ **Linux→Windows**: Enabled and running in parallel
- ⚠️ **Windows→Linux**: Currently disabled (`if: false`)
  - Reason: Requires Windows ISOs to be created first
  - Will run in parallel when enabled

## Future Enhancements

To fully enable bidirectional testing:

1. Create a job to generate Windows test ISOs
2. Upload Windows ISOs as artifact
3. Enable `test-cross-platform-linux` job
4. All three jobs would run in parallel:
   - Linux ISO generation → Windows testing
   - Windows ISO generation → Linux testing
   - Both independent of each other

## Related Files

- `.github/workflows/large-file-tests.yml` - Main workflow file
- `test/test_cross_platform.sh` - Cross-platform test script
- `test/create_synthetic_iso.py` - ISO generation utility

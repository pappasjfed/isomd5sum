# CI Workflow Changes Summary

## What Changed

The Linux test workflow was refactored to separate build and test jobs, matching the pattern already used in the Windows workflow.

## Before (test.yml)

```
┌──────────────────────────────┐
│ test-linux                   │
│ (Build AND Test in one job)  │
│                              │
│ 1. Install all dependencies  │
│ 2. Build with make           │
│ 3. Run tests immediately     │
└──────────────────────────────┘

┌──────────────────────────────┐
│ build-linux-cmake            │
│ (Build with minimal test)    │
│                              │
│ 1. Install dependencies      │
│ 2. Build with CMake          │
│ 3. Quick --help test         │
└──────────────────────────────┘
```

## After (test.yml)

```
┌──────────────────────────┐
│ build-linux-makefile     │
│                          │
│ 1. Install build deps    │
│ 2. Build with make       │
│ 3. Prepare artifacts     │
│ 4. Upload artifacts ⬆️    │
└──────────────────────────┘
            │
            │ Artifact: isomd5sum-linux-makefile
            ▼
┌──────────────────────────┐
│ test-linux-makefile      │
│                          │
│ 1. Download artifacts ⬇️  │
│ 2. Install runtime deps  │
│ 3. Test executables      │
│ 4. Run Python tests      │
└──────────────────────────┘


┌──────────────────────────┐
│ build-linux-cmake        │
│                          │
│ 1. Install build deps    │
│ 2. Build with CMake      │
│ 3. Prepare artifacts     │
│ 4. Upload artifacts ⬆️    │
└──────────────────────────┘
            │
            │ Artifact: isomd5sum-linux-cmake
            ▼
┌──────────────────────────┐
│ test-linux-cmake         │
│                          │
│ 1. Download artifacts ⬇️  │
│ 2. Install runtime deps  │
│ 3. Test executables      │
│ 4. Create & test ISO     │
└──────────────────────────┘
```

## Benefits of New Architecture

### 1. Artifact Validation ✅
**Before:** Tests run in same environment as build  
**After:** Tests run in clean environment with only runtime dependencies

This ensures:
- Executables don't rely on build-time tools
- All runtime dependencies are properly identified
- Artifacts are truly portable

### 2. Clear Separation ✅
**Before:** Build and test mixed together  
**After:** Build jobs focus on compilation, test jobs focus on verification

Makes it easier to:
- Debug failures (build vs runtime issues)
- Understand what each job does
- Maintain and update workflows

### 3. Artifact Reusability ✅
**Before:** No artifacts, can't download builds  
**After:** Artifacts available for 30 days

Enables:
- Manual testing without rebuilding
- Investigation of specific builds
- Future release automation

### 4. Consistency Across Platforms ✅
**Before:** Windows had artifacts, Linux didn't  
**After:** All platforms follow same pattern

- Windows: build-windows → test-windows
- Linux Make: build-linux-makefile → test-linux-makefile
- Linux CMake: build-linux-cmake → test-linux-cmake
- Windows MinGW: build-mingw (uploads artifacts)

## Test Coverage Improvements

### Linux Makefile Tests (Enhanced)
- ✅ Executable existence checks
- ✅ Help output verification
- ✅ Python module compilation
- ✅ Full Python test suite

### Linux CMake Tests (New!)
- ✅ Executable existence checks
- ✅ Help output verification
- ✅ ISO creation with xorriso
- ✅ Checksum implanting
- ✅ Checksum verification
- ✅ Complete workflow validation

## Workflow Execution

### Parallel Execution
Jobs can run in parallel:
```
build-linux-makefile  ║  build-linux-cmake  ║  build-windows
         ║            ║          ║           ║       ║
         ▼            ║          ▼           ║       ▼
test-linux-makefile   ║  test-linux-cmake   ║  test-windows
```

### Sequential Dependency
Each test job depends on its corresponding build job:
```
build-linux-makefile
         │
         │ needs: build-linux-makefile
         ▼
test-linux-makefile
```

## Files Modified

- `.github/workflows/test.yml` - Complete refactoring
  - Lines changed: +124, -6
  - Jobs changed: 2 → 4
  - Artifacts added: 2 new artifacts

## Artifacts Produced

All workflows now produce downloadable artifacts:

| Artifact Name                    | Platform | Build System | Retention |
|----------------------------------|----------|--------------|-----------|
| isomd5sum-windows-x64            | Windows  | MSVC         | 30 days   |
| isomd5sum-windows-x64-mingw      | Windows  | MinGW        | 30 days   |
| isomd5sum-linux-makefile         | Linux    | Make         | 30 days   |
| isomd5sum-linux-cmake            | Linux    | CMake        | 30 days   |

## Impact

✅ **No breaking changes** - All tests still run  
✅ **Better test coverage** - More comprehensive validation  
✅ **Improved reliability** - Tests in clean environment  
✅ **Better debugging** - Clear separation of concerns  
✅ **Artifact availability** - Builds available for download

## Next Steps

The CI pipeline is now ready for:
1. ✅ Pull request validation
2. ✅ Manual artifact download and testing
3. ✅ Future release automation
4. ✅ Integration with downstream projects

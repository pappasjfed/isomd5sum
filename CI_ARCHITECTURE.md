# CI Workflow Architecture - Build/Test Separation

## Overview

All CI workflows now follow a consistent pattern where build jobs create and upload artifacts, and separate test jobs download and verify those artifacts work correctly.

## Architecture Pattern

```
┌─────────────┐
│ Build Job   │
│             │
│ 1. Checkout │
│ 2. Install  │
│    build    │
│    deps     │
│ 3. Build    │
│ 4. Upload   │
│    artifacts│
└─────────────┘
       │
       │ Artifacts
       │ (uploaded to GitHub)
       ▼
┌─────────────┐
│ Test Job    │
│             │
│ 1. Checkout │
│ 2. Download │
│    artifacts│
│ 3. Install  │
│    runtime  │
│    deps     │
│ 4. Run tests│
└─────────────┘
```

## Workflows

### 1. Windows Build (windows-build.yml)

**Build Job: `build-windows`**
- Platform: Windows with MSVC
- Builds: checkisomd5.exe, implantisomd5.exe
- Artifact: `isomd5sum-windows-x64`

**Test Job: `test-windows`**
- Downloads: `isomd5sum-windows-x64`
- Tests: Help output, ISO operations

**Build Job: `build-mingw`**
- Platform: Linux with MinGW cross-compiler
- Builds: checkisomd5.exe, implantisomd5.exe
- Artifact: `isomd5sum-windows-x64-mingw`

### 2. Linux Tests (test.yml)

**Build Job: `build-linux-makefile`**
- Platform: Fedora 39 container
- Build System: GNU Make
- Builds: checkisomd5, implantisomd5
- Artifact: `isomd5sum-linux-makefile`

**Test Job: `test-linux-makefile`**
- Downloads: `isomd5sum-linux-makefile`
- Tests: Help output, Python module tests

**Build Job: `build-linux-cmake`**
- Platform: Ubuntu latest
- Build System: CMake
- Builds: checkisomd5, implantisomd5
- Artifact: `isomd5sum-linux-cmake`

**Test Job: `test-linux-cmake`**
- Downloads: `isomd5sum-linux-cmake`
- Tests: Help output, ISO operations

## Benefits

### 1. Artifact Validation
Artifacts are tested in a clean environment, ensuring they work independently of the build environment. This catches issues like:
- Missing runtime dependencies
- Incorrect binary permissions
- Platform-specific problems

### 2. Build/Test Separation
Clear separation of concerns:
- Build jobs focus on compilation
- Test jobs focus on verification
- Easier to debug which stage fails

### 3. Artifact Reusability
Artifacts are available for:
- Manual download during retention period (30 days)
- Use in release workflows
- Investigation of issues

### 4. Consistency
All platforms follow the same pattern:
- Easier to understand and maintain
- Predictable behavior
- Common troubleshooting approach

### 5. Parallel Execution
Jobs can run in parallel where appropriate:
- Different build systems (Makefile vs CMake)
- Different platforms (Windows vs Linux)
- Tests run only after their specific build completes

## Artifact Contents

Each artifact includes:
- Compiled executables
- LICENSE.txt (COPYING file)
- README.txt
- Platform-specific docs (e.g., WINDOWS_BUILD.txt)

## Retention

All artifacts are retained for **30 days** after the workflow run completes.

## Testing Coverage

### Windows Tests
- ✓ Executables exist
- ✓ Help commands run
- ✓ ISO creation
- ✓ Checksum implanting
- ✓ Checksum verification

### Linux Makefile Tests
- ✓ Executables exist
- ✓ Help commands run
- ✓ Python module builds
- ✓ Python tests pass

### Linux CMake Tests
- ✓ Executables exist
- ✓ Help commands run
- ✓ ISO creation with xorriso
- ✓ Checksum implanting
- ✓ Checksum verification

## Dependencies

### Build Dependencies
Required only in build jobs:
- Compilers (gcc, MSVC, MinGW)
- Build tools (make, CMake)
- Development headers (popt-devel, python-devel)

### Runtime Dependencies
Required in test jobs:
- Runtime libraries (libpopt0)
- Test tools (xorriso for ISO creation)
- Python interpreter (for Python tests)

## Workflow Files

- `.github/workflows/windows-build.yml` - Windows builds and tests
- `.github/workflows/test.yml` - Linux builds and tests

## Future Enhancements

Possible improvements:
1. Matrix strategy for multiple platforms/versions
2. Code coverage reporting
3. Performance benchmarking
4. Integration tests
5. Automated release creation from artifacts

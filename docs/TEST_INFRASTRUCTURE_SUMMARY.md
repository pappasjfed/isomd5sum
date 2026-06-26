# Test Infrastructure Summary

This document describes the test infrastructure for both MD5 and SHA-256 tools.

## Test Files

### MD5 Tests
- **testpyisomd5sum_md5.py** - Tests MD5 functionality using Python bindings
  - Uses `pyisomd5sum.implantisomd5sum()` and `pyisomd5sum.checkisomd5sum()`
  - Tests: implant, force flag, verify, callbacks, abort

### SHA-256 Tests
- **testpyisomd5sum_sha.py** - Tests SHA-256 functionality using CLI tools
  - Uses `implantisosha` and `checkisosha` command-line tools
  - Tests: implant, force flag, info display, backward compatibility
  - Note: Python bindings for SHA not yet implemented

### Combined/Generic Tests
- **testpyisomd5sum.py** - Original test (kept for backward compatibility)
  - Currently tests MD5 only via Python bindings

## Makefile Targets

```bash
# Run all tests (MD5 + SHA)
make test

# Run MD5 tests only
make test-md5

# Run SHA tests only
make test-sha
```

## GitHub Actions

### Linux Tests
- **build-linux-makefile** - Build with Makefile, includes MD5 and SHA tools
- **test-linux-makefile-md5** - Test MD5 tools on Linux
- **test-linux-makefile-sha** - Test SHA-256 tools on Linux
- **build-linux-cmake** - Build with CMake
- **test-linux-cmake** - Test both MD5 and SHA tools (CMake build)

### Windows Tests
- **build-windows-cmake** - Build with CMake on Windows
- **test-windows-cmake-md5** - Test MD5 tools on Windows
- **test-windows-cmake-sha** - Test SHA-256 tools on Windows

## Tool Matrix

| Tool           | Format | Function |
|----------------|--------|----------|
| implantisomd5  | MD5    | Write MD5 checksum to ISO |
| checkisomd5    | Both   | Verify MD5 or SHA-256 ISOs |
| implantisosha  | SHA-256| Write SHA-256 checksum to ISO |
| checkisosha    | Both   | Verify MD5 or SHA-256 ISOs |

## Backward Compatibility

Both `checkisomd5` and `checkisosha` can read and verify ISOs with either MD5 or SHA-256 checksums. This ensures:
- Old MD5 ISOs can be verified with new tools
- SHA-256 ISOs can be created and verified
- No breaking changes for existing users

## Running Tests Locally

### Prerequisites
```bash
# Install dependencies
sudo apt-get install libpopt-dev genisoimage  # Linux
# or
dnf install popt-devel xorriso  # Fedora

# Build tools
make
```

### Run Tests
```bash
# All tests
make test

# MD5 only
python3 testpyisomd5sum_md5.py

# SHA only
python3 testpyisomd5sum_sha.py
```

## Test Coverage

### What's Tested
- ✅ Implanting checksums (MD5 and SHA-256)
- ✅ Force flag behavior
- ✅ Checksum verification
- ✅ Display checksum info
- ✅ Callback functionality (MD5)
- ✅ Abort callback (MD5)
- ✅ Backward compatibility (both tools read both formats)
- ✅ Cross-platform (Linux and Windows)

### What's Not Yet Tested
- ❌ Python bindings for SHA tools (not implemented)
- ❌ Large file tests for SHA tools (in separate workflow)
- ❌ Fragment checksum validation for SHA
- ❌ All callback features for SHA (needs Python bindings)

## Future Improvements

1. Implement Python bindings for SHA-256 tools
2. Add SHA-256 support to large file tests
3. Add SHA-256 tests to cross-platform validation
4. Consolidate test code to reduce duplication
5. Add performance comparison tests (MD5 vs SHA-256)

# GitHub Copilot Instructions for isomd5sum

## Project Overview

isomd5sum is a cross-platform utility for implanting and verifying MD5 checksums in ISO 9660 images. The checksum is stored in the ISO's application data area, allowing verification with only the ISO file itself.

**Key Features:**
- Implant MD5 checksums into ISO images
- Verify MD5 checksums from ISO images or physical media
- Cross-platform support (Linux/Unix and Windows)
- Python bindings for programmatic access
- Support for large files (>4GB) on all platforms

## Architecture

### Core Components

1. **Libraries** (static):
   - `libimplantisomd5.c/h` - Core implanting functionality
   - `libcheckisomd5.c/h` - Core verification functionality
   - `md5.c/h` - MD5 hash implementation
   - `utilities.c/h` - Platform-agnostic utility functions

2. **Command-Line Tools**:
   - `implantisomd5.c` - CLI for implanting checksums
   - `checkisomd5.c` - CLI for verifying checksums

3. **Python Bindings**:
   - `pyisomd5sum.c` - Python module exposing core functionality

4. **Platform Compatibility**:
   - `win32_compat.h` - Windows compatibility layer
   - `simple_popt.h` - Minimal popt implementation for Windows

## Build Systems

### Makefile (Linux/Unix primary)

```bash
make                    # Build all targets
make install           # Install to system
make clean             # Clean build artifacts
make test              # Run Python tests
```

**Key Variables:**
- `PYTHON` - Python interpreter (default: python3)
- `LIBDIR` - Library directory (lib or lib64, auto-detected)
- `DESTDIR` - Installation prefix

### CMake (Cross-platform)

```bash
mkdir build && cd build
cmake ..               # Configure
make                   # Build
make install          # Install
```

**Platform-specific:**
- Linux: Uses system popt library
- Windows: Uses simple_popt.h fallback

## Cross-Platform Considerations

### File Handling
- **Large file support (>4GB)**: Always use 64-bit file operations
  - Linux: `off_t`, `lseek64`, `stat64`
  - Windows: `_fseeki64`, `_ftelli64`, `_stat64`
- **Defines required**: `_FILE_OFFSET_BITS=64`, `_LARGEFILE_SOURCE=1`, `_LARGEFILE64_SOURCE=1`

### Platform-Specific Code
- Use `#ifdef _WIN32` for Windows-specific code
- Use `#ifndef _WIN32` for Unix-specific code
- Keep platform differences isolated in `win32_compat.h` and `utilities.c`

### Byte Order
- ISO 9660 uses **little-endian** byte order
- Use `isonum_721()` and `isonum_733()` macros for ISO field access
- Checksums are stored in hexadecimal ASCII format (portable across architectures)

## Code Style and Conventions

### C Standard
- **C11** (`-std=gnu11` on Linux, `/std:c11` on MSVC)
- Use standard library functions where possible
- Avoid GNU-specific extensions in cross-platform code

### Formatting
- Follow `.clang-format` configuration
- 4-space indentation (configured in `.editorconfig`)
- Opening braces on same line for functions
- Use descriptive variable names

### Error Handling
- Return 0 for success, non-zero for errors
- Use `perror()` or custom error messages for diagnostics
- Always check return values from file operations

### Memory Management
- Use `malloc/free` consistently
- Check for NULL after allocation
- Free resources in reverse order of allocation
- Use `calloc` when zero-initialization is needed

## Testing

### Test Infrastructure

1. **Python Tests** (`testpyisomd5sum.py`):
   - Tests Python bindings
   - Run with: `make test`

2. **Cross-Platform Tests** (`test/test_cross_platform.sh`):
   - Tests executables on Linux
   - Creates test ISOs, implants checksums, verifies

3. **Large File Tests** (`test/test_large_files.sh`):
   - Tests files >4GB
   - Requires sparse file support

4. **Windows Tests**:
   - See `test/` directory for Windows-specific scripts
   - Tests large file handling on Windows

### Running Tests

```bash
# Linux (Makefile)
make test

# Cross-platform (CMake)
cd build && ctest

# Manual testing
./implantisomd5 test.iso
./checkisomd5 --md5sumonly test.iso
```

## CI/CD Workflows

### GitHub Actions

1. **`test.yml`**:
   - Builds on Linux with both Makefile and CMake
   - Tests executables
   - Creates test ISOs and verifies functionality
   - Runs on all PRs and pushes to master

2. **`windows-build.yml`**:
   - Builds native Windows executables with CMake + MSVC
   - Tests on Windows Server
   - Uploads Windows artifacts

3. **`large-file-tests.yml`**:
   - Tests large file support (>4GB)
   - Runs on Linux with sparse file support

## Important Guidelines for Code Changes

### When Modifying Core Libraries

1. **Maintain API Compatibility**:
   - Don't change function signatures in public headers
   - Preserve existing behavior for backward compatibility

2. **Test on Both Platforms**:
   - Verify Linux build with Makefile
   - Verify cross-platform build with CMake
   - Test on Windows if modifying platform-specific code

3. **Update Documentation**:
   - Update man pages if CLI behavior changes
   - Update README for user-visible changes
   - Document breaking changes in PR description

### When Adding Dependencies

- **Linux**: Use system libraries where available (popt, Python)
- **Windows**: Bundle or implement minimal fallbacks
- Avoid external dependencies unless absolutely necessary
- Document new dependencies in build instructions

### Security Considerations

- **Always validate input parameters** (buffer sizes, file offsets)
- **Check for integer overflow** in size calculations
- **Verify file operations** don't write beyond intended boundaries
- Use safe string functions (`strncpy`, `snprintf`)

## File Structure

```
isomd5sum/
├── .github/
│   ├── workflows/          # CI/CD configurations
│   └── copilot-instructions.md  # This file
├── test/                   # Test scripts and data
├── cmake/                  # CMake modules
├── *.c, *.h               # Source and header files
├── *.1                    # Man pages
├── Makefile               # Linux/Unix build
├── CMakeLists.txt         # Cross-platform build
├── README                 # User documentation
└── *.md                   # Developer documentation
```

## Common Tasks

### Adding a New Feature

1. Implement in library (`libimplantisomd5.c` or `libcheckisomd5.c`)
2. Update public header if adding new API
3. Add command-line option if needed
4. Update man page with new options
5. Add tests in `testpyisomd5sum.py` or `test/`
6. Verify on both Linux and Windows

### Fixing a Bug

1. Write a test that reproduces the bug
2. Fix the bug in the appropriate module
3. Verify test passes
4. Check for similar issues in related code
5. Update documentation if behavior changes

### Performance Optimization

1. Profile to identify bottleneck
2. Optimize hot paths (MD5 calculation, I/O)
3. Maintain correctness (run all tests)
4. Verify performance improvement
5. Document trade-offs in comments

## Development Tools

- **Compiler**: GCC 7+, Clang 10+, or MSVC 2019+
- **Build**: Make 4.0+, CMake 3.12+
- **Python**: Python 3.6+ for bindings and tests
- **Formatting**: clang-format (see `.clang-format`)
- **ISO Creation**: xorriso or mkisofs (for testing)

## Resources

- **Repository**: https://github.com/rhinstaller/isomd5sum
- **Issues**: GitHub Issues tracker
- **Mailing List**: anaconda-devel-list@redhat.com (for questions, patches, and general discussion)
- **Documentation**: README, man pages, and *.md files in repo

## Quick Reference

### Key Macros and Functions

- `isonum_721(buf)` - Read 16-bit little-endian value from ISO
- `isonum_733(buf)` - Read 32-bit both-endian value from ISO
- `checkmd5sum()` - Verify checksum (libcheckisomd5)
- `implantmd5sum()` - Implant checksum (libimplantisomd5)

### Platform Detection

```c
#ifdef _WIN32
    // Windows-specific code
#else
    // Unix/Linux code
#endif
```

### Large File Operations

```c
// Linux (file descriptors)
off_t offset = lseek64(fd, 0, SEEK_END);

// Windows (file descriptors)
__int64 offset = _lseeki64(_fileno(fp), 0, SEEK_END);

// Windows (FILE* streams)
_fseeki64(fp, 0, SEEK_END);
__int64 offset = _ftelli64(fp);
```

## Notes

- This is a low-level system utility - prioritize correctness and reliability
- Maintain backward compatibility with existing ISO images
- ISO 9660 format is standardized - follow specifications carefully
- Test with real-world ISO images when possible

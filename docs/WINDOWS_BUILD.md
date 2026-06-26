# Building isomd5sum for Windows

This document describes how to build the isomd5sum tools for Windows.

## Pre-built Binaries and Installer

Pre-built Windows executables and installers are available from the GitHub Releases page:
https://github.com/pappasjfed/isomd5sum/releases

### Windows Installer (Recommended)
- `isomd5sum-*-win64.exe` - Windows installer that automatically installs executables and adds them to PATH

For detailed installer information, see [WINDOWS_INSTALLER.md](WINDOWS_INSTALLER.md).

### Portable Executables
Download the appropriate zip file:
- `isomd5sum-*-windows-x64-msvc.zip` - Built with Visual Studio (recommended)
- `isomd5sum-*-windows-x64-mingw.zip` - Built with MinGW-w64 (alternative)

Extract the zip file and the executables are ready to use.

## Prerequisites

### Windows Build Requirements

To build on Windows, you'll need:

1. **CMake** (3.12 or later) - https://cmake.org/download/
2. **Visual Studio** (2015 or later) or **MinGW-w64**
3. **Git for Windows** (optional, for cloning the repository)

### Visual Studio Build

1. Install Visual Studio with C++ development tools
2. Open a "Developer Command Prompt for VS"
3. Navigate to the repository directory
4. Create a build directory and run CMake:

```cmd
mkdir build
cd build
cmake ..
cmake --build . --config Release
```

The executables will be in `build\Release\`:
- `checkisomd5.exe` - Check MD5 checksums embedded in ISO images
- `implantisomd5.exe` - Implant MD5 checksums into ISO images

### MinGW-w64 Build

1. Install MinGW-w64 and add it to your PATH
2. Open a command prompt
3. Navigate to the repository directory
4. Create a build directory and run CMake:

```cmd
mkdir build
cd build
cmake -G "MinGW Makefiles" ..
mingw32-make
```

The executables will be in the `build` directory.

### Building the Windows Installer

To build a Windows installer (.exe) that automatically installs the executables and adds them to PATH:

1. Install **NSIS** (Nullsoft Scriptable Install System) from https://nsis.sourceforge.io/Download
2. Follow the build steps above for either Visual Studio or MinGW
3. After building, create the installer:

```cmd
cd build
cpack -C Release
```

The installer will be created as `isomd5sum-<version>-win64.exe` in the build directory.

For detailed information about the installer, see [WINDOWS_INSTALLER.md](WINDOWS_INSTALLER.md).

## Cross-Compilation from Linux

You can cross-compile for Windows from Linux using MinGW:

```bash
# Install MinGW cross-compiler
sudo apt-get install mingw-w64

# Create build directory
mkdir build-windows
cd build-windows

# Configure for Windows
cmake -DCMAKE_TOOLCHAIN_FILE=../cmake/mingw-w64.cmake ..

# Build
make
```

## Usage on Windows

### Checking an ISO Image

```cmd
checkisomd5.exe --verbose myiso.iso
```

### Checking a Physical CD/DVD Drive

On Windows, you can check physical media by using the device path:

```cmd
checkisomd5.exe --verbose \\.\D:
```

Where `D:` is your CD/DVD drive letter.

### Implanting a Checksum

```cmd
implantisomd5.exe myiso.iso
```

To overwrite an existing checksum:

```cmd
implantisomd5.exe --force myiso.iso
```

## Platform Differences

The Windows port includes the following platform-specific adaptations:

1. **File I/O**: Uses Windows-specific `_open`, `_read`, `_write`, `_lseek` functions
2. **Device Access**: Supports Windows device paths (`\\.\X:`) for physical media
3. **Command Line Parsing**: Uses a minimal popt-compatible implementation
4. **Keyboard Input**: Uses `_kbhit()` and `_getch()` instead of termios for ESC key detection
5. **Memory Alignment**: Uses `_aligned_malloc` on older MSVC versions

## Limitations

- Python bindings (`pyisomd5sum.so`) are not built on Windows by default
- Man pages are not installed on Windows

## Troubleshooting

### Build Errors

If you encounter errors about missing headers:
- Ensure you have the C++ development tools installed in Visual Studio
- Make sure CMake is using the correct compiler

### Runtime Errors

If the tools crash or produce errors:
- Ensure you're running with appropriate permissions (Administrator) when accessing physical devices
- Verify that the ISO file or device is accessible

## Additional Resources

- Original repository: https://github.com/rhinstaller/isomd5sum
- CMake documentation: https://cmake.org/documentation/

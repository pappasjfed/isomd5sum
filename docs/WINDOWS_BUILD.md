# Building isomd5sum

This document covers building isomd5sum on all supported platforms.

## Pre-built Binaries (Windows)

Pre-built Windows executables and an installer are available from the GitHub
Releases page:

https://github.com/pappasjfed/isomd5sum/releases

- `isomd5sum-*-win64.exe` — Windows installer (recommended); installs executables and adds them to PATH
- `isomd5sum-*-windows-x64-msvc.zip` — Portable executables built with Visual Studio
- `isomd5sum-*-windows-x64-mingw.zip` — Portable executables built with MinGW-w64

For installer usage and options, see [WINDOWS_INSTALLER.md](../WINDOWS_INSTALLER.md).

---

## Linux / Unix

### Prerequisites

- GCC or Clang
- GNU Make
- popt library and development headers (`libpopt-dev` on Debian/Ubuntu, `popt-devel` on Fedora/RHEL)
- Python 3 development headers (optional, for Python bindings)

### Build with Make

```bash
make
make install
```

### Build with CMake

```bash
mkdir build && cd build
cmake ..
make
make install
```

---

## Windows

### Prerequisites

1. **CMake** (3.12 or later) — https://cmake.org/download/
2. **Visual Studio** (2019 or later) with C++ development tools, **or** **MinGW-w64**
3. **Git for Windows** (optional, for cloning the repository)

### Visual Studio Build

1. Open a **Developer Command Prompt for VS**.
2. Navigate to the repository directory.
3. Configure and build:

```cmd
mkdir build
cd build
cmake ..
cmake --build . --config Release
```

Executables are placed in `build\Release\`:
- `checkisomd5.exe`
- `implantisomd5.exe`
- `checkisosha.exe`
- `implantisosha.exe`

### MinGW-w64 Build

1. Add MinGW-w64 to your PATH.
2. Open a command prompt and navigate to the repository directory.
3. Configure and build:

```cmd
mkdir build
cd build
cmake -G "MinGW Makefiles" ..
mingw32-make
```

Executables are placed in the `build` directory.

### Building the Windows Installer

1. Install **NSIS** from https://nsis.sourceforge.io/Download
2. Build the project with either Visual Studio or MinGW (see above).
3. Create the installer:

```cmd
cd build
cpack -C Release
```

The installer is created as `isomd5sum-<version>-win64.exe` in the build directory.

For detailed installer information, see [WINDOWS_INSTALLER.md](../WINDOWS_INSTALLER.md).

---

## Cross-Compilation (Linux → Windows)

You can cross-compile Windows binaries from Linux using MinGW-w64:

```bash
# Install MinGW cross-compiler
sudo apt-get install mingw-w64

mkdir build-windows
cd build-windows
cmake -DCMAKE_TOOLCHAIN_FILE=../cmake/mingw-w64.cmake ..
make
```

---

## Platform Notes

### Windows-specific adaptations

1. **File I/O**: Uses Windows `_open`, `_read`, `_write`, `_lseek` functions
2. **Device Access**: Supports Win32 device paths (`\\.\X:`) for physical media — see [README](../README)
3. **Command-line parsing**: Uses a minimal popt-compatible implementation (`simple_popt.h`)
4. **Keyboard input**: Uses `_kbhit()` / `_getch()` instead of termios for ESC key detection
5. **Memory alignment**: Uses `_aligned_malloc` on older MSVC versions

### Limitations on Windows

- Python bindings (`pyisomd5sum`) are not built on Windows by default
- Man pages are not installed on Windows

---

## Troubleshooting

### Build errors (missing headers)

- Verify C++ development tools are installed in Visual Studio.
- Confirm CMake is targeting the correct compiler.

### Runtime errors (device access)

- Run the tool with Administrator privileges when accessing physical devices.
- Verify the ISO file or device path is correct and accessible.

### "Cannot find VCRUNTIME140.dll"

Install the Visual C++ Redistributable:
https://aka.ms/vs/17/release/vc_redist.x64.exe

---

## Additional Resources

- Project repository: https://github.com/rhinstaller/isomd5sum
- CMake documentation: https://cmake.org/documentation/
- NSIS documentation: https://nsis.sourceforge.io/Docs/

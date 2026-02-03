# Windows Installer Guide

This guide explains how to build and use the Windows installer for isomd5sum.

## About the Installer

The Windows installer is built using CPack with the NSIS (Nullsoft Scriptable Install System) generator. It provides:

- Easy installation of executables (`checkisomd5.exe` and `implantisomd5.exe`)
- Automatic addition of installation directory to PATH environment variable
- Support for both user-level and administrator-level installations
- Start Menu shortcuts
- Clean uninstallation

## Prerequisites for Building the Installer

To build the Windows installer, you need:

1. **CMake** (3.12 or later) - https://cmake.org/download/
2. **Visual Studio** (2015 or later) or **MinGW-w64**
3. **NSIS** (3.0 or later) - https://nsis.sourceforge.io/Download

### Installing NSIS

Download and install NSIS from https://nsis.sourceforge.io/Download

After installation, make sure NSIS is in your PATH or CMake can find it automatically.

## Building the Installer

### Using Visual Studio

1. Open a "Developer Command Prompt for VS"
2. Navigate to the repository directory
3. Create and configure the build:

```cmd
mkdir build
cd build
cmake -G "Visual Studio 17 2022" -A x64 ..
```

4. Build the project:

```cmd
cmake --build . --config Release
```

5. Create the installer:

```cmd
cpack -C Release
```

The installer will be created as `isomd5sum-<version>-win64.exe` in the build directory.

### Using MinGW

1. Open a command prompt with MinGW in PATH
2. Navigate to the repository directory
3. Create and configure the build:

```cmd
mkdir build
cd build
cmake -G "MinGW Makefiles" ..
```

4. Build the project:

```cmd
mingw32-make
```

5. Create the installer:

```cmd
cpack
```

## Using the Installer

### Installation

1. **Download** the installer executable (`isomd5sum-<version>-win64.exe`)

2. **Run the installer**:
   - **User-level install**: Double-click the installer and proceed without administrator privileges. The tools will be installed in your user directory and added to your user PATH.
   - **System-level install**: Right-click the installer and select "Run as administrator". The tools will be installed in Program Files and added to the system PATH.

3. **Follow the installation wizard**:
   - Accept the license agreement
   - Choose the installation directory (default is recommended)
   - Select components to install (all are recommended)
   - Confirm installation

4. **PATH Configuration**:
   - The installer automatically adds the installation directory to your PATH
   - For user-level installs: Added to user PATH
   - For system-level installs: Added to system PATH
   - You may need to restart your command prompt or applications to use the updated PATH

### Verifying Installation

After installation, open a new command prompt and test:

```cmd
checkisomd5 --help
implantisomd5 --help
```

If the commands are not found, you may need to:
1. Close and reopen your command prompt
2. Log out and log back in (for user-level installs)
3. Restart your computer (rarely necessary)

### Using the Installed Tools

The tools are now available from any command prompt:

```cmd
# Check an ISO image
checkisomd5 --verbose myiso.iso

# Check a physical CD/DVD drive
checkisomd5 --verbose \\.\D:

# Implant a checksum into an ISO
implantisomd5 myiso.iso
```

### Start Menu

The installer creates a program group in the Start Menu with:
- Links to the executables (command prompt will open)
- Links to documentation
- Link to the project website
- Uninstall shortcut

### Uninstallation

To uninstall:

1. **From Control Panel**:
   - Go to Settings > Apps > Apps & features
   - Find "isomd5sum" in the list
   - Click Uninstall

2. **From Start Menu**:
   - Find "isomd5sum" in the Start Menu
   - Click on the "Uninstall" shortcut

3. **From the installation directory**:
   - Navigate to the installation directory
   - Run `uninstall.exe`

The uninstaller will:
- Remove all installed files
- Remove the PATH entries
- Remove Start Menu shortcuts
- Remove registry entries

## Installer Options

### Silent Installation

For automated deployments, you can install silently:

```cmd
# User-level silent install
isomd5sum-<version>-win64.exe /S

# System-level silent install (requires admin)
isomd5sum-<version>-win64.exe /S /AllUsers
```

### Custom Installation Directory

```cmd
isomd5sum-<version>-win64.exe /D=C:\MyCustomPath\isomd5sum
```

### Silent Uninstallation

```cmd
# From the installation directory
uninstall.exe /S
```

## CI/CD Integration

The Windows installer can be built automatically in CI/CD pipelines. See the GitHub Actions workflow (`.github/workflows/windows-build.yml`) for an example of building the installer in an automated environment.

## Troubleshooting

### Installer Won't Run

- Make sure you have the required permissions
- Check if your antivirus is blocking the installer
- Verify the installer file is not corrupted

### PATH Not Updated

- Restart your command prompt or terminal
- Log out and log back in
- Check Environment Variables:
  - Press Win+R, type `sysdm.cpl`, press Enter
  - Go to "Advanced" tab
  - Click "Environment Variables"
  - Check if the installation path is in PATH

### NSIS Not Found During Build

If CPack can't find NSIS:

1. Install NSIS from https://nsis.sourceforge.io/Download
2. Add NSIS to your PATH, or
3. Set the CMake variable: `cmake -DCPACK_NSIS_EXECUTABLE="C:\Program Files (x86)\NSIS\makensis.exe" ..`

### "Cannot find VCRUNTIME140.dll"

If you get this error when running the tools:
- Install Visual C++ Redistributable for Visual Studio
- Download from: https://aka.ms/vs/17/release/vc_redist.x64.exe

## Additional Resources

- Main README: See `README` file
- Windows Build Guide: See `WINDOWS_BUILD.md`
- Project Repository: https://github.com/rhinstaller/isomd5sum
- NSIS Documentation: https://nsis.sourceforge.io/Docs/

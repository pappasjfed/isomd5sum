# isomd5sum for Windows - Quick Start Guide

## Installation

1. Download the latest release from: https://github.com/pappasjfed/isomd5sum/releases
2. Extract the ZIP file to a folder (e.g., `C:\isomd5sum`)
3. Optionally, add the folder to your PATH for easy access

## Tools Included

- **checkisomd5.exe** - Verify MD5 checksums embedded in ISO images
- **implantisomd5.exe** - Add MD5 checksums to ISO images

## Basic Usage

### Checking an ISO Image

Open Command Prompt or PowerShell and run:

```cmd
checkisomd5.exe --verbose myimage.iso
```

This will verify the embedded checksum in the ISO file.

### Checking Physical Media

To check a CD/DVD in drive D:

```cmd
checkisomd5.exe --verbose \\.\D:
```

**Note:** You may need to run as Administrator to access physical drives.

### Adding a Checksum to an ISO

```cmd
implantisomd5.exe myimage.iso
```

This will embed an MD5 checksum in the ISO's application data area.

### Force Overwrite Existing Checksum

```cmd
implantisomd5.exe --force myimage.iso
```

## Command-Line Options

### checkisomd5

- `--verbose` or `-v` - Show progress during checking
- `--md5sumonly` or `-o` - Only print the checksum, don't verify
- `--gauge` or `-g` - Output progress as percentage (for scripts)
- `--help` or `-h` - Show help message

### implantisomd5

- `--force` or `-f` - Overwrite existing checksum
- `--supported-iso` or `-S` - Mark ISO as "supported"
- `--help` or `-h` - Show help message

## Examples

### Example 1: Verify a Downloaded ISO

```cmd
checkisomd5.exe --verbose ubuntu-22.04-desktop-amd64.iso
```

### Example 2: Add Checksum to Your Custom ISO

```cmd
implantisomd5.exe my-custom-installer.iso
```

### Example 3: Verify CD/DVD Media

```cmd
REM Check disc in drive E:
checkisomd5.exe --verbose \\.\E:
```

### Example 4: Script Integration

PowerShell example to check multiple ISOs:

```powershell
$isos = Get-ChildItem *.iso
foreach ($iso in $isos) {
    Write-Host "Checking $($iso.Name)..."
    & checkisomd5.exe --verbose $iso.FullName
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ $($iso.Name) - PASSED" -ForegroundColor Green
    } else {
        Write-Host "✗ $($iso.Name) - FAILED" -ForegroundColor Red
    }
}
```

## Exit Codes

### checkisomd5 Exit Codes

- `0` - Checksum verification passed
- `1` - Checksum verification failed or checksum not found
- `2` - Verification aborted by user (ESC key)

### implantisomd5 Exit Codes

- `0` - Checksum successfully implanted
- `1` - Error occurred (file not found, no space, etc.)

## Troubleshooting

### "Access Denied" when checking physical media

Run the command prompt as Administrator:
1. Right-click on Command Prompt or PowerShell
2. Select "Run as administrator"
3. Try the command again

### ISO file is modified after implanting

This is expected! The checksum is written to the ISO's application data area.
The ISO remains bootable and functional.

### "File not found" error

- Check the file path is correct
- Use quotes around paths with spaces: `checkisomd5.exe "C:\My ISOs\file.iso"`
- Ensure the ISO file exists and is accessible

### Very small ISOs fail verification

ISOs smaller than about 10MB may fail verification due to rounding in fragment calculations.
This is a limitation of the fragment-based verification system.

## Additional Information

- Source code: https://github.com/rhinstaller/isomd5sum
- Windows port: https://github.com/pappasjfed/isomd5sum
- Full documentation: See `WINDOWS_BUILD.txt` for build instructions

## How It Works

isomd5sum uses the ISO 9660 Application Data area (512 bytes at offset 883 in the Primary Volume Descriptor) to store:
- MD5 checksum of the ISO content
- Fragment checksums for early detection of errors
- Metadata about the verification process

This allows the ISO to be self-verifying without external checksum files.

## Support

For issues, questions, or contributions, please visit:
https://github.com/pappasjfed/isomd5sum/issues

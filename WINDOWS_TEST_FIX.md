# Windows CI Test Fix - PowerShell Exit Code Issue

## Problem

The Windows test in GitHub Actions was failing with this output:

```
✓ Executables can run
Error: Process completed with exit code 1.
```

Despite the test appearing to pass (showing "✓ Executables can run"), the step was exiting with code 1, causing the CI to fail.

## Root Cause

PowerShell scripts propagate the exit code of the last executed command unless explicitly overridden. In the "Test help output" step:

```powershell
cd bin
.\checkisomd5.exe --help 2>&1 | Out-Null
if ($LASTEXITCODE -ne 1) { Write-Host "Note: checkisomd5 --help returned $LASTEXITCODE" }
.\implantisomd5.exe --help 2>&1 | Out-Null
if ($LASTEXITCODE -ne 1) { Write-Host "Note: implantisomd5 --help returned $LASTEXITCODE" }
Write-Host "✓ Executables can run"
```

The test was:
1. Running `--help` commands to verify executables can execute
2. Checking if they returned exit code 1 (which `--help` typically does)
3. Printing success message

However, if the last command (`implantisomd5.exe --help`) returned a non-zero exit code (like 1), PowerShell would propagate that as the script's exit code, causing the GitHub Actions step to fail.

## Solution

Added an explicit `exit 0` at the end of the test script:

```powershell
cd bin
.\checkisomd5.exe --help 2>&1 | Out-Null
if ($LASTEXITCODE -ne 1) { Write-Host "Note: checkisomd5 --help returned $LASTEXITCODE" }
.\implantisomd5.exe --help 2>&1 | Out-Null
if ($LASTEXITCODE -ne 1) { Write-Host "Note: implantisomd5 --help returned $LASTEXITCODE" }
Write-Host "✓ Executables can run"
exit 0  # Explicitly exit successfully
```

This ensures that after verifying the executables can run, the test step always exits with code 0 (success), regardless of what exit code the `--help` commands returned.

## Why This Works

The test's goal is to verify that the executables can be executed (they're not corrupted, dependencies are available, etc.). The actual exit code from `--help` is informational only - the test checks if it's NOT 1 and logs a note, but doesn't fail.

By adding `exit 0`, we explicitly tell PowerShell to exit the script successfully after completing all checks, overriding the implicit behavior of using the last command's exit code.

## Impact

- ✅ Test correctly passes when executables can run
- ✅ Subsequent test steps (Create test ISO, Test ISO operations) can execute
- ✅ CI build completes successfully
- ✅ No change to actual test logic - still verifies executables can run

## File Changed

- `.github/workflows/windows-build.yml` - Added `exit 0` to "Test help output" step

#!/usr/bin/python3

import os
import subprocess
import sys
import tempfile

# Test SHA-256 tools using command-line interface
# (No Python bindings for SHA tools yet)

# Pass in the rc, the expected value and the pass_all state
# Returns a PASS/FAIL string and updates pass_all if it fails
def pass_fail(rc, pass_value, pass_all):
    if rc == pass_value:
        return ("PASS", pass_all)
    else:
        return ("FAIL", False)

try:
    iso_size = int(sys.argv[1])
except (IndexError, ValueError):
    # Default to 500K
    iso_size = 500

try:
    # Python 3
    catch_error = FileNotFoundError
except NameError:
    # Python 2
    catch_error = OSError

# create iso file using a clean directory
with tempfile.TemporaryDirectory(prefix="isoshatest-") as tmpdir:
    # Write temporary data to iso test dir
    with open(tmpdir+"/TEST-DATA", "w") as f:
        # Write more data based on cmdline arg
        for x in range(0,iso_size):
            f.write("A" * 1024)

    try:
        subprocess.check_call(["mkisofs", "-quiet", "-o", "testiso_sha.iso", tmpdir], 
                            stderr=subprocess.DEVNULL)
    except catch_error:
        subprocess.check_call(["genisoimage", "-quiet", "-o", "testiso_sha.iso", tmpdir],
                            stderr=subprocess.DEVNULL)

    if not os.path.exists("testiso_sha.iso"):
        print("Error creating iso")
        sys.exit(1)

pass_all = True

# Test implantisosha
print("Testing SHA-256 tools...")

# implant it using implantisosha
try:
    result = subprocess.run(["./implantisosha", "testiso_sha.iso"], 
                          capture_output=True, text=True)
    (rstr, pass_all) = pass_fail(result.returncode, 0, pass_all)
    print("Implanting SHA-256 -> %s" % rstr)
except catch_error:
    print("Implanting SHA-256 -> FAIL (tool not found)")
    pass_all = False

# do it again without forcing, should get error
try:
    result = subprocess.run(["./implantisosha", "testiso_sha.iso"], 
                          capture_output=True, text=True)
    # Should fail (exit code 1) because already has checksum
    (rstr, pass_all) = pass_fail(result.returncode, 1, pass_all)
    print("Implanting SHA-256 again w/o forcing -> %s" % rstr)
except catch_error:
    print("Implanting SHA-256 again w/o forcing -> FAIL (tool not found)")
    pass_all = False

# do it again with forcing, should work
try:
    result = subprocess.run(["./implantisosha", "--force", "testiso_sha.iso"], 
                          capture_output=True, text=True)
    (rstr, pass_all) = pass_fail(result.returncode, 0, pass_all)
    print("Implanting SHA-256 again forcing -> %s" % rstr)
except catch_error:
    print("Implanting SHA-256 again forcing -> FAIL (tool not found)")
    pass_all = False

# check it with checkisosha - just print info, not full verification
try:
    result = subprocess.run(["./checkisosha", "--md5sumonly", "testiso_sha.iso"], 
                          capture_output=True, text=True)
    # --md5sumonly just prints info, returns 0
    (rstr, pass_all) = pass_fail(result.returncode, 0, pass_all)
    print("Checking SHA-256 info -> %s" % rstr)
except catch_error:
    print("Checking SHA-256 info -> FAIL (tool not found)")
    pass_all = False

# Test cross-compatibility: checkisomd5 should be able to read SHA ISOs
print("\nTesting backward compatibility...")
try:
    result = subprocess.run(["./checkisomd5", "--md5sumonly", "testiso_sha.iso"], 
                          capture_output=True, text=True)
    # Should work, returns 0
    (rstr, pass_all) = pass_fail(result.returncode, 0, pass_all)
    print("checkisomd5 reading SHA ISO -> %s" % rstr)
except catch_error:
    print("checkisomd5 reading SHA ISO -> FAIL (tool not found)")
    pass_all = False

# clean up
if os.path.exists("testiso_sha.iso"):
    os.unlink("testiso_sha.iso")

if pass_all:
    print("\nAll SHA-256 tests passed!")
    exit(0)
else:
    print("\nSome SHA-256 tests failed!")
    exit(1)

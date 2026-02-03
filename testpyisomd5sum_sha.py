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
        subprocess.check_call(["mkisofs", "-o", "testiso_sha.iso", tmpdir])
    except catch_error:
        subprocess.check_call(["genisoimage", "-o", "testiso_sha.iso", tmpdir])

    if not os.path.exists("testiso_sha.iso"):
        print("Error creating iso")
        sys.exit(1)

pass_all = True

# Test implantisosha
print("Testing SHA-256 tools...")

# implant it using implantisosha
try:
    rc = subprocess.call(["./implantisosha", "testiso_sha.iso"])
    (rstr, pass_all) = pass_fail(rc, 0, pass_all)
    print("Implanting SHA-256 -> %s" % rstr)
except catch_error:
    print("Implanting SHA-256 -> FAIL (tool not found)")
    pass_all = False

# do it again without forcing, should get error
try:
    rc = subprocess.call(["./implantisosha", "testiso_sha.iso"])
    (rstr, pass_all) = pass_fail(rc, 1, pass_all)  # Should fail (already has checksum)
    print("Implanting SHA-256 again w/o forcing -> %s" % rstr)
except catch_error:
    print("Implanting SHA-256 again w/o forcing -> FAIL (tool not found)")
    pass_all = False

# do it again with forcing, should work
try:
    rc = subprocess.call(["./implantisosha", "--force", "testiso_sha.iso"])
    (rstr, pass_all) = pass_fail(rc, 0, pass_all)
    print("Implanting SHA-256 again forcing -> %s" % rstr)
except catch_error:
    print("Implanting SHA-256 again forcing -> FAIL (tool not found)")
    pass_all = False

# check it with checkisosha
try:
    result = subprocess.run(["./checkisosha", "testiso_sha.iso"], 
                          capture_output=True, text=True)
    # Check if PASS is in output
    if "PASS" in result.stderr or result.returncode == 0:
        (rstr, pass_all) = pass_fail(0, 0, pass_all)
    else:
        (rstr, pass_all) = pass_fail(1, 0, pass_all)
    print("Checking SHA-256 -> %s" % rstr)
except catch_error:
    print("Checking SHA-256 -> FAIL (tool not found)")
    pass_all = False

# Test cross-compatibility: checkisomd5 should be able to read SHA ISOs
print("\nTesting backward compatibility (checkisomd5 reading SHA ISO)...")
try:
    result = subprocess.run(["./checkisomd5", "testiso_sha.iso"], 
                          capture_output=True, text=True)
    if "PASS" in result.stderr or result.returncode == 0:
        (rstr, pass_all) = pass_fail(0, 0, pass_all)
    else:
        (rstr, pass_all) = pass_fail(1, 0, pass_all)
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

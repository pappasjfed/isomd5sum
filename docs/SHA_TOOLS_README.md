# SHA-256 Tools

This repository now includes separate tools for SHA-256 checksums alongside the original MD5 tools.

## Available Tools

### MD5 Tools (Original)
- **implantisomd5** - Embeds MD5 checksum into ISO image
- **checkisomd5** - Verifies MD5 or SHA-256 checksums (backward compatible)

### SHA-256 Tools (New)
- **implantisosha** - Embeds SHA-256 checksum into ISO image
- **checkisosha** - Verifies SHA-256 or MD5 checksums (backward compatible)

## Usage

### Embedding Checksums

```bash
# Embed MD5 checksum
implantisomd5 [--force] [--supported-iso] myimage.iso

# Embed SHA-256 checksum
implantisosha [--force] [--supported-iso] myimage.iso
```

### Verifying Checksums

Both check tools can verify both MD5 and SHA-256 checksums:

```bash
# Check any ISO (auto-detects hash type)
checkisomd5 myimage.iso
checkisosha myimage.iso

# Print checksum without verification
checkisomd5 --md5sumonly myimage.iso
checkisosha --md5sumonly myimage.iso
```

## Key Points

1. **Only ONE hash per ISO**: Each implant tool writes only its designated hash type
2. **Backward compatibility**: Both check tools can read and verify both MD5 and SHA-256 ISOs
3. **Naming convention**: Following the pattern of existing tools with "sha" suffix
4. **No breaking changes**: Existing MD5 tools continue to work as before

## Why SHA-256?

SHA-256 provides significantly better collision resistance than MD5:
- MD5: 128-bit hash (vulnerable to collision attacks)
- SHA-256: 256-bit hash (currently considered secure)

This reduces the possibility of hash collisions while maintaining backward compatibility.

## Building

```bash
# Using Make
make

# Using CMake
mkdir build && cd build
cmake ..
make
```

Both build systems will create all four tools: implantisomd5, implantisosha, checkisomd5, and checkisosha.

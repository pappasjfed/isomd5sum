#!/usr/bin/env python3
"""
Create synthetic ISO files for testing large file support.
This creates minimal but valid ISO9660 images with sparse files to save disk space.
"""

import os
import sys
import struct

# ISO 9660 constants
SECTOR_SIZE = 2048
SYSTEM_AREA_SECTORS = 16
PVD_SECTOR = 16

# Test sizes (in bytes)
TEST_SIZES = {
    'tiny': 1024 * 512,           # 512 KB - Small test
    'small': 1024 * 1024,         # 1 MB - Minimum viable
    'cd': 700 * 1024 * 1024,      # 700 MB - CD-ROM
    'dvd': int(4.5 * 1024 * 1024 * 1024),   # 4.5 GB - DVD
    'dvd_dl': int(8.5 * 1024 * 1024 * 1024), # 8.5 GB - DVD Dual Layer
    'bd': 25 * 1024 * 1024 * 1024,  # 25 GB - Blu-ray
}


def create_primary_volume_descriptor(size_in_sectors):
    """
    Create a minimal but valid Primary Volume Descriptor.
    ECMA-119 / ISO 9660 format.
    """
    pvd = bytearray(SECTOR_SIZE)
    
    # Volume Descriptor Type (1 = Primary Volume Descriptor)
    pvd[0] = 1
    
    # Standard Identifier "CD001"
    pvd[1:6] = b'CD001'
    
    # Volume Descriptor Version
    pvd[6] = 1
    
    # System Identifier (32 bytes, padded with spaces)
    system_id = b'LINUX'
    pvd[8:8+len(system_id)] = system_id
    pvd[8+len(system_id):40] = b' ' * (32 - len(system_id))
    
    # Volume Identifier (32 bytes, padded with spaces)
    volume_id = b'SYNTHETIC_TEST_ISO'
    pvd[40:40+len(volume_id)] = volume_id
    pvd[40+len(volume_id):72] = b' ' * (32 - len(volume_id))
    
    # Volume Space Size (Both-byte order) at offset 80-87
    # Little-endian at 80-83, Big-endian at 84-87
    pvd[80:84] = struct.pack('<I', size_in_sectors)
    pvd[84:88] = struct.pack('>I', size_in_sectors)
    
    # Volume Set Size (Both-byte order) - 1 volume
    pvd[120:122] = struct.pack('<H', 1)
    pvd[124:126] = struct.pack('>H', 1)
    
    # Volume Sequence Number (Both-byte order) - 1
    pvd[124:126] = struct.pack('<H', 1)
    pvd[128:130] = struct.pack('>H', 1)
    
    # Logical Block Size (Both-byte order) - 2048 bytes
    pvd[128:130] = struct.pack('<H', SECTOR_SIZE)
    pvd[130:132] = struct.pack('>H', SECTOR_SIZE)
    
    # Application Use area starts at offset 883 (512 bytes)
    # This is where isomd5sum stores its data
    # Initialize with spaces
    pvd[883:883+512] = b' ' * 512
    
    return bytes(pvd)


def create_volume_set_terminator():
    """
    Create a Volume Descriptor Set Terminator.
    """
    vdst = bytearray(SECTOR_SIZE)
    
    # Volume Descriptor Type (255 = Terminator)
    vdst[0] = 255
    
    # Standard Identifier "CD001"
    vdst[1:6] = b'CD001'
    
    # Volume Descriptor Version
    vdst[6] = 1
    
    return bytes(vdst)


def create_synthetic_iso(filename, size_bytes, sparse=True):
    """
    Create a synthetic ISO file with the given size.
    
    Args:
        filename: Output filename
        size_bytes: Total size of the ISO in bytes
        sparse: If True, create a sparse file (saves disk space)
    """
    # Round up to sector boundary
    size_in_sectors = (size_bytes + SECTOR_SIZE - 1) // SECTOR_SIZE
    actual_size = size_in_sectors * SECTOR_SIZE
    
    print(f"Creating {filename}...")
    print(f"  Requested size: {size_bytes:,} bytes ({size_bytes / (1024**3):.2f} GB)")
    print(f"  Actual size: {actual_size:,} bytes ({size_in_sectors:,} sectors)")
    print(f"  Sparse: {sparse}")
    
    with open(filename, 'wb') as f:
        # Write system area (16 sectors of zeros)
        system_area = b'\x00' * (SYSTEM_AREA_SECTORS * SECTOR_SIZE)
        f.write(system_area)
        
        # Write Primary Volume Descriptor at sector 16
        pvd = create_primary_volume_descriptor(size_in_sectors)
        f.write(pvd)
        
        # Write Volume Descriptor Set Terminator at sector 17
        vdst = create_volume_set_terminator()
        f.write(vdst)
        
        # Calculate remaining size
        written = (SYSTEM_AREA_SECTORS + 2) * SECTOR_SIZE
        remaining = actual_size - written
        
        if sparse and remaining > 0:
            # For sparse files, write periodically to maintain structure
            # but mostly seek to create holes (saves disk space)
            if size_bytes < 100 * 1024 * 1024:  # Files < 100MB: write all zeros
                f.write(b'\x00' * remaining)
            else:
                # For large files: write zeros every ~10MB to maintain structure
                chunk_size = 10 * 1024 * 1024  # 10 MB
                position = f.tell()
                while remaining > 0:
                    # Write a small chunk
                    to_write = min(4096, remaining)  # Write 4KB
                    f.write(b'\x00' * to_write)
                    remaining -= to_write
                    position += to_write
                    
                    if remaining > chunk_size:
                        # Seek forward (creates hole)
                        to_skip = min(chunk_size, remaining)
                        f.seek(position + to_skip)
                        remaining -= to_skip
                        position += to_skip
        else:
            # Write actual zeros (for testing or non-sparse filesystems)
            chunk_size = 1024 * 1024  # 1 MB chunks
            written_chunks = 0
            while remaining > 0:
                chunk = min(chunk_size, remaining)
                f.write(b'\x00' * chunk)
                remaining -= chunk
                written_chunks += 1
                if written_chunks % 100 == 0:
                    print(f"  Written {written_chunks} MB...")
    
    # Verify file size
    actual_file_size = os.path.getsize(filename)
    print(f"  Created: {actual_file_size:,} bytes")
    
    if sparse:
        # Check if sparse (on Linux)
        if hasattr(os, 'stat') and hasattr(os.stat(filename), 'st_blocks'):
            stat_info = os.stat(filename)
            allocated_bytes = stat_info.st_blocks * 512
            print(f"  Disk usage: {allocated_bytes:,} bytes (sparse file)")
    
    return actual_file_size


def main():
    """Main function to create test ISOs."""
    if len(sys.argv) < 2:
        print("Usage: create_synthetic_iso.py <size_name> [output_file] [--no-sparse]")
        print(f"\nAvailable sizes: {', '.join(TEST_SIZES.keys())}")
        print("\nExample: create_synthetic_iso.py dvd test_dvd.iso")
        sys.exit(1)
    
    size_name = sys.argv[1]
    if size_name not in TEST_SIZES:
        print(f"Error: Unknown size '{size_name}'")
        print(f"Available sizes: {', '.join(TEST_SIZES.keys())}")
        sys.exit(1)
    
    # Determine output filename
    if len(sys.argv) >= 3 and not sys.argv[2].startswith('--'):
        output_file = sys.argv[2]
    else:
        output_file = f"test_{size_name}.iso"
    
    # Check for --no-sparse flag
    sparse = '--no-sparse' not in sys.argv
    
    size_bytes = TEST_SIZES[size_name]
    
    try:
        actual_size = create_synthetic_iso(output_file, size_bytes, sparse)
        print(f"\n[OK] Successfully created {output_file}")
        return 0
    except Exception as e:
        print(f"\n[ERROR] Error creating ISO: {e}")
        import traceback
        traceback.print_exc()
        return 1


if __name__ == '__main__':
    sys.exit(main())

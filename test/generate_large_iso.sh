#!/bin/bash
#
# Convenience script to generate and test large ISO files
# This script makes it easy to work with multi-GB ISOs
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

usage() {
    cat << EOF
Usage: $0 [SIZE] [OUTPUT_FILE]

Generate a large synthetic ISO file for testing.

SIZE options:
    dvd       - 4.5 GB (DVD)
    dvd_dl    - 8.5 GB (DVD Dual Layer)
    bd        - 25 GB (Blu-ray)

If OUTPUT_FILE is not specified, defaults to test_[SIZE].iso

Examples:
    $0 dvd                    # Creates test_dvd.iso (4.5 GB)
    $0 dvd_dl my_large.iso    # Creates my_large.iso (8.5 GB)
    $0 bd                     # Creates test_bd.iso (25 GB)

The generated ISOs use sparse files, so they take minimal disk space
while appearing to be full-sized.

EOF
}

# Parse arguments
SIZE="${1:-}"
OUTPUT_FILE="${2:-}"

if [ -z "$SIZE" ] || [ "$SIZE" = "-h" ] || [ "$SIZE" = "--help" ]; then
    usage
    exit 0
fi

# Validate size
case "$SIZE" in
    dvd|dvd_dl|bd)
        ;;
    *)
        echo "Error: Unknown size '$SIZE'"
        echo "Valid sizes: dvd, dvd_dl, bd"
        exit 1
        ;;
esac

# Set default output file
if [ -z "$OUTPUT_FILE" ]; then
    OUTPUT_FILE="test_${SIZE}.iso"
fi

# Generate the ISO
echo -e "${BLUE}Generating ${SIZE} ISO file...${NC}"
python3 "${SCRIPT_DIR}/create_synthetic_iso.py" "$SIZE" "$OUTPUT_FILE"

# Get file info
if [ -f "$OUTPUT_FILE" ]; then
    APPARENT_SIZE=$(ls -lh "$OUTPUT_FILE" | awk '{print $5}')
    ACTUAL_SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)
    
    echo ""
    echo -e "${GREEN}✅ ISO generated successfully!${NC}"
    echo ""
    echo "File: $OUTPUT_FILE"
    echo "Apparent size: $APPARENT_SIZE"
    echo "Disk usage: $ACTUAL_SIZE (sparse file)"
    echo ""
    echo "Next steps:"
    echo "  1. Implant checksum: ../implantisomd5 -f $OUTPUT_FILE"
    echo "  2. Verify checksum:  ../checkisomd5 $OUTPUT_FILE"
    echo ""
fi

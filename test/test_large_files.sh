#!/bin/bash
#
# Test isomd5sum tools with various sized ISO files
# This script creates synthetic ISOs, implants checksums, and verifies them
#

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_SIZES=("small" "cd")  # Default: quick tests
FULL_TEST_SIZES=("small" "cd" "dvd" "dvd_dl" "bd")
USE_SPARSE=true
VERBOSE=false
CLEANUP=true

# Tool paths (will be detected)
IMPLANT_TOOL=""
CHECK_TOOL=""

# Statistics
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Usage function
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Test isomd5sum tools with synthetic ISO files of various sizes.

Options:
    -h, --help          Show this help message
    -f, --full          Run full test suite (includes DVD, DVD-DL, BD sizes)
    -q, --quick         Run quick tests only (small, cd) [default]
    -s, --size SIZE     Test specific size (tiny|small|cd|dvd|dvd_dl|bd)
    -v, --verbose       Verbose output
    --no-sparse         Don't use sparse files (slower, uses more disk)
    --no-cleanup        Don't cleanup test files after completion
    --tools-dir DIR     Directory containing implantisomd5 and checkisomd5

Examples:
    $0                  # Quick test with default sizes
    $0 --full           # Full test with all sizes
    $0 --size dvd       # Test only DVD size
    $0 --verbose --full # Full test with verbose output

EOF
}

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $*"
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

# Find tools
find_tools() {
    log_info "Locating isomd5sum tools..."
    
    # Try common locations
    local search_paths=(
        "${SCRIPT_DIR}/.."
        "/usr/local/bin"
        "/usr/bin"
        "$(pwd)"
    )
    
    if [ -n "$TOOLS_DIR" ]; then
        search_paths=("$TOOLS_DIR" "${search_paths[@]}")
    fi
    
    for path in "${search_paths[@]}"; do
        if [ -x "$path/implantisomd5" ]; then
            IMPLANT_TOOL="$path/implantisomd5"
        fi
        if [ -x "$path/checkisomd5" ]; then
            CHECK_TOOL="$path/checkisomd5"
        fi
    done
    
    # Check in PATH
    if [ -z "$IMPLANT_TOOL" ] && command -v implantisomd5 &> /dev/null; then
        IMPLANT_TOOL="$(command -v implantisomd5)"
    fi
    if [ -z "$CHECK_TOOL" ] && command -v checkisomd5 &> /dev/null; then
        CHECK_TOOL="$(command -v checkisomd5)"
    fi
    
    if [ -z "$IMPLANT_TOOL" ] || [ -z "$CHECK_TOOL" ]; then
        log_error "Could not find isomd5sum tools"
        log_error "Please build them first or specify --tools-dir"
        log_error "  implantisomd5: ${IMPLANT_TOOL:-NOT FOUND}"
        log_error "  checkisomd5: ${CHECK_TOOL:-NOT FOUND}"
        exit 1
    fi
    
    log_info "Found tools:"
    log_info "  implantisomd5: $IMPLANT_TOOL"
    log_info "  checkisomd5: $CHECK_TOOL"
}

# Create synthetic ISO
create_iso() {
    local size_name=$1
    local output_file=$2
    
    log_info "Creating synthetic ISO: $size_name"
    
    local sparse_flag=""
    if [ "$USE_SPARSE" = false ]; then
        sparse_flag="--no-sparse"
    fi
    
    if [ "$VERBOSE" = true ]; then
        python3 "${SCRIPT_DIR}/create_synthetic_iso.py" "$size_name" "$output_file" $sparse_flag
    else
        python3 "${SCRIPT_DIR}/create_synthetic_iso.py" "$size_name" "$output_file" $sparse_flag > /dev/null
    fi
    
    if [ ! -f "$output_file" ]; then
        log_error "Failed to create $output_file"
        return 1
    fi
    
    return 0
}

# Test a single ISO file
test_iso() {
    local size_name=$1
    local iso_file="${SCRIPT_DIR}/test_${size_name}.iso"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    echo ""
    log_info "=========================================="
    log_info "Testing: $size_name"
    log_info "=========================================="
    
    # Create ISO
    if ! create_iso "$size_name" "$iso_file"; then
        log_error "Failed to create ISO for $size_name"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
    
    local iso_size=$(stat -f%z "$iso_file" 2>/dev/null || stat -c%s "$iso_file" 2>/dev/null || echo "unknown")
    log_info "ISO size: $iso_size bytes ($(numfmt --to=iec-i --suffix=B $iso_size 2>/dev/null || echo "$iso_size"))"
    
    # Implant checksum
    log_info "Implanting MD5 checksum..."
    if [ "$VERBOSE" = true ]; then
        "$IMPLANT_TOOL" -f "$iso_file"
    else
        "$IMPLANT_TOOL" -f "$iso_file" > /dev/null 2>&1
    fi
    
    if [ $? -ne 0 ]; then
        log_error "Failed to implant checksum for $size_name"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
    
    # Verify checksum
    log_info "Verifying MD5 checksum..."
    local check_output
    if [ "$VERBOSE" = true ]; then
        check_output=$("$CHECK_TOOL" --verbose "$iso_file" 2>&1)
        echo "$check_output"
    else
        check_output=$("$CHECK_TOOL" "$iso_file" 2>&1)
    fi
    
    local check_result=$?
    
    # Check result
    if [ $check_result -eq 0 ]; then
        if echo "$check_output" | grep -q "PASS"; then
            log_success "✅ $size_name: PASSED"
            TESTS_PASSED=$((TESTS_PASSED + 1))
            return 0
        else
            log_error "❌ $size_name: Unexpected output"
            echo "$check_output"
            TESTS_FAILED=$((TESTS_FAILED + 1))
            return 1
        fi
    else
        log_error "❌ $size_name: FAILED (exit code: $check_result)"
        echo "$check_output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Cleanup test files
cleanup_files() {
    if [ "$CLEANUP" = true ]; then
        log_info "Cleaning up test files..."
        rm -f "${SCRIPT_DIR}"/test_*.iso
    else
        log_info "Keeping test files (--no-cleanup specified)"
    fi
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -f|--full)
                TEST_SIZES=("${FULL_TEST_SIZES[@]}")
                shift
                ;;
            -q|--quick)
                TEST_SIZES=("small" "cd")
                shift
                ;;
            -s|--size)
                TEST_SIZES=("$2")
                shift 2
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            --no-sparse)
                USE_SPARSE=false
                shift
                ;;
            --no-cleanup)
                CLEANUP=false
                shift
                ;;
            --tools-dir)
                TOOLS_DIR="$2"
                shift 2
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
}

# Main function
main() {
    parse_args "$@"
    
    echo ""
    log_info "=========================================="
    log_info "ISO MD5SUM Large File Test Suite"
    log_info "=========================================="
    log_info "Test sizes: ${TEST_SIZES[*]}"
    log_info "Sparse files: $USE_SPARSE"
    log_info "Verbose: $VERBOSE"
    echo ""
    
    # Find tools
    find_tools
    
    # Run tests
    for size in "${TEST_SIZES[@]}"; do
        test_iso "$size" || true  # Continue even if test fails
    done
    
    # Cleanup
    cleanup_files
    
    # Summary
    echo ""
    log_info "=========================================="
    log_info "Test Summary"
    log_info "=========================================="
    log_info "Tests run:    $TESTS_RUN"
    log_success "Tests passed: $TESTS_PASSED"
    if [ $TESTS_FAILED -gt 0 ]; then
        log_error "Tests failed: $TESTS_FAILED"
    else
        log_info "Tests failed: $TESTS_FAILED"
    fi
    echo ""
    
    if [ $TESTS_FAILED -eq 0 ]; then
        log_success "🎉 All tests passed!"
        return 0
    else
        log_error "💔 Some tests failed"
        return 1
    fi
}

# Run main function
main "$@"

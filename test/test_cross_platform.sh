#!/bin/bash
#
# Cross-platform validation test for isomd5sum
# Tests that ISOs implanted on one platform can be verified on another
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Detect platform and normalize name for consistent ISO naming
case "$(uname -s)" in
    Linux*)              PLATFORM="Linux" ;;
    MINGW*|MSYS*|CYGWIN*) PLATFORM="Windows" ;;
    Darwin*)             PLATFORM="macOS" ;;
    *)                   PLATFORM=$(uname -s) ;;
esac

CROSS_PLATFORM_DIR="${SCRIPT_DIR}/cross_platform"
VERBOSE=false

# Test sizes - configurable
TEST_SIZES=("small" "cd")  # Default
QUICK_SIZES=("small" "cd")
MEDIUM_SIZES=("small" "cd" "dvd")
LARGE_SIZES=("small" "cd" "dvd" "bd")
FULL_SIZES=("small" "cd" "dvd" "dvd_dl" "bd")

# Tools
IMPLANT_TOOL=""
CHECK_TOOL=""

# Statistics
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
VALIDATION_FAILED=0  # Track validation failures during creation

# Logging
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $*"
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $*"
}

# Usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Cross-platform validation test for isomd5sum.
Tests that ISOs implanted on one platform can be verified on another.

Options:
    -h, --help          Show this help message
    -v, --verbose       Verbose output
    --create            Create test ISOs for cross-platform testing
    --verify            Verify cross-platform ISOs
    --both              Both create and verify (default)
    --tools-dir DIR     Directory containing tools
    --quick             Use quick test sizes (small, cd) [default]
    --medium            Use medium test sizes (small, cd, dvd 4.5GB)
    --large             Use large test sizes (small, cd, dvd, dvd_dl 8.5GB)
    --full              Use full test sizes (all including bd 25GB)
    --sizes SIZE...     Specify custom sizes (tiny|small|cd|dvd|dvd_dl|bd)

Workflow:
    1. Run with --create on Linux to generate ISOs with checksums
    2. Transfer ISOs to Windows (or vice versa)
    3. Run with --verify on Windows to check Linux-created ISOs

Examples:
    $0 --create --medium              # Create small, cd, and DVD ISOs
    $0 --verify --verbose             # Verify with verbose output
    $0 --sizes small dvd              # Custom size selection
    
EOF
}

# Find tools
find_tools() {
    log_info "Locating isomd5sum tools on $PLATFORM..."
    
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
        if [ -x "$path/implantisomd5" ] || [ -x "$path/implantisomd5.exe" ]; then
            IMPLANT_TOOL="$path/implantisomd5"
            [ -x "$path/implantisomd5.exe" ] && IMPLANT_TOOL="$path/implantisomd5.exe"
        fi
        if [ -x "$path/checkisomd5" ] || [ -x "$path/checkisomd5.exe" ]; then
            CHECK_TOOL="$path/checkisomd5"
            [ -x "$path/checkisomd5.exe" ] && CHECK_TOOL="$path/checkisomd5.exe"
        fi
    done
    
    if [ -z "$IMPLANT_TOOL" ] || [ -z "$CHECK_TOOL" ]; then
        log_error "Could not find isomd5sum tools"
        exit 1
    fi
    
    log_info "Found: $IMPLANT_TOOL"
    log_info "Found: $CHECK_TOOL"
}

# Create test ISOs with checksums
create_test_isos() {
    log_info "=========================================="
    log_info "Creating test ISOs on $PLATFORM"
    log_info "=========================================="
    
    mkdir -p "$CROSS_PLATFORM_DIR"
    
    log_info "Test sizes: ${TEST_SIZES[*]}"
    
    # Create test ISOs of various sizes
    for size in "${TEST_SIZES[@]}"; do
        local iso_file="${CROSS_PLATFORM_DIR}/${PLATFORM}_${size}.iso"
        local manifest="${CROSS_PLATFORM_DIR}/${PLATFORM}_manifest.txt"
        
        log_info "Creating $size ISO..."
        
        # Generate synthetic ISO
        if [ "$VERBOSE" = true ]; then
            python3 "${SCRIPT_DIR}/create_synthetic_iso.py" "$size" "$iso_file"
        else
            python3 "${SCRIPT_DIR}/create_synthetic_iso.py" "$size" "$iso_file" > /dev/null 2>&1
        fi
        
        if [ ! -f "$iso_file" ]; then
            log_error "Failed to create $iso_file"
            continue
        fi
        
        # Implant checksum
        log_info "Implanting checksum..."
        if [ "$VERBOSE" = true ]; then
            "$IMPLANT_TOOL" -f "$iso_file"
        else
            "$IMPLANT_TOOL" -f "$iso_file" > /dev/null 2>&1
        fi
        
        # Verify on same platform
        log_info "Verifying on $PLATFORM..."
        if "$CHECK_TOOL" "$iso_file" > /dev/null 2>&1; then
            log_success "✅ $size: Created and verified on $PLATFORM"
            
            # Record in manifest
            local md5sum=$(md5sum "$iso_file" 2>/dev/null || md5 -q "$iso_file" 2>/dev/null || echo "unknown")
            echo "$size|$md5sum|$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$manifest"
        else
            log_error "❌ $size: Failed verification on $PLATFORM"
            VALIDATION_FAILED=1
        fi
    done
    
    log_info "Test ISOs created in: $CROSS_PLATFORM_DIR"
    log_info "Transfer this directory to another platform for verification"
}

# Verify cross-platform ISOs
verify_cross_platform() {
    log_info "=========================================="
    log_info "Verifying cross-platform ISOs on $PLATFORM"
    log_info "=========================================="
    
    if [ ! -d "$CROSS_PLATFORM_DIR" ]; then
        log_error "Cross-platform directory not found: $CROSS_PLATFORM_DIR"
        log_error "Please run with --create on another platform first"
        exit 1
    fi
    
    # Find ISOs from other platforms
    local other_isos=$(find "$CROSS_PLATFORM_DIR" -name "*.iso" ! -name "${PLATFORM}_*.iso" 2>/dev/null)
    
    if [ -z "$other_isos" ]; then
        log_error "No cross-platform ISOs found in $CROSS_PLATFORM_DIR"
        log_error "Expected ISOs from other platforms (not starting with ${PLATFORM}_)"
        exit 1
    fi
    
    # Verify each ISO
    while IFS= read -r iso_file; do
        TESTS_RUN=$((TESTS_RUN + 1))
        
        local basename=$(basename "$iso_file")
        local source_platform=$(echo "$basename" | cut -d_ -f1)
        local size=$(echo "$basename" | cut -d_ -f2 | sed 's/.iso$//')
        
        log_info "Testing: $basename (created on $source_platform)"
        
        # Verify checksum
        local check_output
        if [ "$VERBOSE" = true ]; then
            check_output=$("$CHECK_TOOL" --verbose "$iso_file" 2>&1)
            echo "$check_output"
        else
            check_output=$("$CHECK_TOOL" "$iso_file" 2>&1)
        fi
        
        if [ $? -eq 0 ] && echo "$check_output" | grep -q "PASS"; then
            log_success "✅ $source_platform → $PLATFORM: $size PASSED"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            log_error "❌ $source_platform → $PLATFORM: $size FAILED"
            TESTS_FAILED=$((TESTS_FAILED + 1))
            [ "$VERBOSE" = true ] || echo "$check_output"
        fi
    done <<< "$other_isos"
}

# Main function
main() {
    local mode="both"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            --create)
                mode="create"
                shift
                ;;
            --verify)
                mode="verify"
                shift
                ;;
            --both)
                mode="both"
                shift
                ;;
            --tools-dir)
                TOOLS_DIR="$2"
                shift 2
                ;;
            --quick)
                TEST_SIZES=("${QUICK_SIZES[@]}")
                shift
                ;;
            --medium)
                TEST_SIZES=("${MEDIUM_SIZES[@]}")
                shift
                ;;
            --large)
                TEST_SIZES=("${LARGE_SIZES[@]}")
                shift
                ;;
            --full)
                TEST_SIZES=("${FULL_SIZES[@]}")
                shift
                ;;
            --sizes)
                TEST_SIZES=()
                shift
                while [[ $# -gt 0 ]] && [[ ! "$1" =~ ^-- ]]; do
                    TEST_SIZES+=("$1")
                    shift
                done
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
    
    echo ""
    log_info "=========================================="
    log_info "Cross-Platform Validation Test"
    log_info "=========================================="
    log_info "Platform: $PLATFORM"
    log_info "Mode: $mode"
    echo ""
    
    find_tools
    
    case $mode in
        create)
            create_test_isos
            ;;
        verify)
            verify_cross_platform
            ;;
        both)
            create_test_isos
            echo ""
            verify_cross_platform
            ;;
    esac
    
    # Summary
    if [ "$mode" = "verify" ] || [ "$mode" = "both" ]; then
        echo ""
        log_info "=========================================="
        log_info "Cross-Platform Test Summary"
        log_info "=========================================="
        log_info "Tests run:    $TESTS_RUN"
        log_success "Tests passed: $TESTS_PASSED"
        if [ $TESTS_FAILED -gt 0 ]; then
            log_error "Tests failed: $TESTS_FAILED"
        else
            log_info "Tests failed: $TESTS_FAILED"
        fi
        echo ""
        
        if [ $TESTS_FAILED -eq 0 ] && [ $TESTS_RUN -gt 0 ]; then
            log_success "🎉 All cross-platform tests passed!"
            return 0
        elif [ $TESTS_RUN -eq 0 ]; then
            log_info "ℹ️  No cross-platform tests run (create mode only)"
            return 0
        else
            log_error "💔 Some cross-platform tests failed"
            return 1
        fi
    fi
    
    # Check for validation failures in create mode
    if [ "$mode" = "create" ] && [ $VALIDATION_FAILED -eq 1 ]; then
        echo ""
        log_error "=========================================="
        log_error "ISO Creation Failed"
        log_error "=========================================="
        log_error "One or more ISOs failed validation after creation"
        log_error "Please check the output above for details"
        echo ""
        return 1
    fi
    
    return 0
}

main "$@"

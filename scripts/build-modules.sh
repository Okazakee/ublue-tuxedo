#!/bin/bash
# Build Tuxedo modules in writable location (PR pattern)
# Fixes immutable filesystem issues by copying sources to /tmp

set -euo pipefail

BUILD_DIR="/tmp/tuxedo-drivers-build"
KERNEL_VERSION=$(uname -r)

log_info() {
    echo "[INFO] $1"
}

log_success() {
    echo "[SUCCESS] $1"
}

log_warning() {
    echo "[WARNING] $1"
}

log_error() {
    echo "[ERROR] $1"
}

build_modules() {
    log_info "Building Tuxedo modules for kernel $KERNEL_VERSION"
    
    # Create writable build directory
    mkdir -p "$BUILD_DIR"
    
    # Copy DKMS sources to writable location if they exist
    if [ -d "/usr/src/tuxedo-drivers" ]; then
        log_info "Copying DKMS sources to writable location"
        cp -r /usr/src/tuxedo-drivers "$BUILD_DIR/"
    else
        log_warning "DKMS sources not found in /usr/src/tuxedo-drivers"
    fi
    
    # Try DKMS autoinstall first
    log_info "Running DKMS autoinstall"
    if dkms autoinstall; then
        log_success "DKMS autoinstall completed"
    else
        log_warning "DKMS autoinstall failed, trying manual build"
    fi
    
    # Manual build in writable location if sources exist
    if [ -d "$BUILD_DIR/tuxedo-drivers" ]; then
        log_info "Building modules manually in writable location"
        cd "$BUILD_DIR/tuxedo-drivers"
        
        # Build modules
        if make; then
            log_success "Module compilation successful"
        else
            log_error "Module compilation failed"
            return 1
        fi
        
        # Install modules
        if make modules_install; then
            log_success "Module installation successful"
        else
            log_error "Module installation failed"
            return 1
        fi
    else
        log_warning "No manual build sources found"
    fi
    
    # Update module dependencies
    log_info "Updating module dependencies"
    if depmod -a; then
        log_success "Module dependencies updated"
    else
        log_warning "Failed to update module dependencies"
    fi
    
    # Verify modules are installed
    if [ -d "/lib/modules/$KERNEL_VERSION/updates" ]; then
        log_info "Checking installed modules:"
        ls -la "/lib/modules/$KERNEL_VERSION/updates/" | grep tuxedo || log_warning "No Tuxedo modules found in updates directory"
    fi
}

cleanup() {
    log_info "Cleaning up build directory"
    rm -rf "$BUILD_DIR"
}

main() {
    log_info "Tuxedo Module Build Script"
    log_info "=========================="
    
    # Check if running as root
    if [ "$EUID" -ne 0 ]; then
        log_error "This script must be run as root"
        exit 1
    fi
    
    # Check if required packages are installed
    if ! command -v dkms >/dev/null 2>&1; then
        log_error "DKMS is not installed"
        exit 1
    fi
    
    if ! command -v make >/dev/null 2>&1; then
        log_error "Make is not installed"
        exit 1
    fi
    
    # Build modules
    if build_modules; then
        log_success "Module build completed successfully"
    else
        log_error "Module build failed"
        exit 1
    fi
    
    # Cleanup
    cleanup
    
    log_success "All done!"
}

# Show usage if help requested
if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
    cat << EOF
Tuxedo Module Build Script

This script builds Tuxedo kernel modules using the PR pattern:
1. Copies DKMS sources to writable /tmp location
2. Runs DKMS autoinstall
3. Falls back to manual build if needed
4. Installs modules to /lib/modules/\$KERNEL_VERSION/updates
5. Updates module dependencies

Usage: $0 [--help]

The script must be run as root and requires:
- DKMS
- Make
- Kernel development headers
- Tuxedo driver sources

EOF
    exit 0
fi

main "$@"

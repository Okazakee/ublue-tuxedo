#!/bin/bash
# Sign Tuxedo kernel modules with MOK key
# This script can be run at runtime to sign modules after MOK enrollment
# or after kernel updates when modules are rebuilt

set -euo pipefail

MOK_DIR="/usr/share/aurora-tuxedo/mok"
KEY="${MOK_DIR}/MOK.key"
CRT="${MOK_DIR}/MOK.crt"
DER="${MOK_DIR}/MOK.der"

log_info() {
    echo "[INFO] $1"
}

log_error() {
    echo "[ERROR] $1" >&2
}

sign_modules() {
    local kernel_version="${1:-}"
    
    if [ -z "$kernel_version" ]; then
        # Get current running kernel version
        kernel_version=$(uname -r)
    fi
    
    log_info "Signing modules for kernel: ${kernel_version}"
    
    # Check if MOK keys exist
    if [ ! -f "$KEY" ] || [ ! -f "$DER" ]; then
        log_error "MOK keys not found in ${MOK_DIR}"
        log_error "Module signing requires MOK keys to be present"
        return 1
    fi
    
    # Find and sign all tuxedo modules
    local modules_dir="/lib/modules/${kernel_version}"
    if [ ! -d "$modules_dir" ]; then
        log_error "Kernel modules directory not found: ${modules_dir}"
        return 1
    fi
    
    local signed_count=0
    local failed_count=0
    
    # Sign uncompressed modules
    while IFS= read -r -d '' mod; do
        if command -v kmodsign >/dev/null 2>&1; then
            if kmodsign sha256 "$KEY" "$DER" "$mod" 2>/dev/null; then
                ((signed_count++))
                log_info "Signed: $(basename "$mod")"
            else
                ((failed_count++))
                log_error "Failed to sign: $(basename "$mod")"
            fi
        elif [ -x "/usr/src/kernels/${kernel_version}/scripts/sign-file" ]; then
            if "/usr/src/kernels/${kernel_version}/scripts/sign-file" sha256 "$KEY" "$CRT" "$mod" 2>/dev/null; then
                ((signed_count++))
                log_info "Signed: $(basename "$mod")"
            else
                ((failed_count++))
                log_error "Failed to sign: $(basename "$mod")"
            fi
        else
            log_error "No signing tool available (kmodsign or sign-file)"
            return 1
        fi
    done < <(find "$modules_dir" -type f \( -name 'tuxedo*.ko' -o -name 'tuxedo*.ko.xz' \) -print0 2>/dev/null || true)
    
    if [ $signed_count -gt 0 ]; then
        log_info "Successfully signed ${signed_count} module(s)"
        # Update module dependencies
        depmod -a "${kernel_version}" 2>/dev/null || true
    fi
    
    if [ $failed_count -gt 0 ]; then
        log_error "Failed to sign ${failed_count} module(s)"
        return 1
    fi
    
    return 0
}

# Main execution
if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
    cat << EOF
Sign Tuxedo Kernel Modules for Secure Boot

Usage: $0 [kernel_version]

If kernel_version is not provided, uses the currently running kernel.

This script signs all Tuxedo kernel modules with the MOK key so they
can be loaded when Secure Boot is enabled.

EOF
    exit 0
fi

# Sign modules for specified kernel or current kernel
sign_modules "${1:-}"


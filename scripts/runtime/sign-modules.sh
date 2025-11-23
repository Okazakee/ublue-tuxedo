#!/bin/bash
# Sign Tuxedo kernel modules with MOK key for Secure Boot
# Supports both compressed (.ko.xz) and uncompressed (.ko) modules

set -euo pipefail

# MOK directory (configurable via environment variable)
MOK_DIR="${TUXEDO_MOK_DIR:-/usr/share/tuxedo/mok}"
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
    local kernel_version="${1:-$(uname -r)}"
    
    log_info "Signing modules for kernel: ${kernel_version}"
    
    # Check if MOK keys exist
    if [ ! -f "$KEY" ] || [ ! -f "$DER" ]; then
        log_error "MOK keys not found in ${MOK_DIR}"
        log_error "Module signing requires MOK keys to be present"
        return 1
    fi
    
    # Find signing tool
    local SIGN_TOOL=""
    if command -v kmodsign >/dev/null 2>&1; then
        SIGN_TOOL="kmodsign"
    elif [ -x "/usr/src/kernels/${kernel_version}/scripts/sign-file" ]; then
        SIGN_TOOL="/usr/src/kernels/${kernel_version}/scripts/sign-file"
    else
        log_error "No signing tool available (kmodsign or sign-file)"
        return 1
    fi
    
    local modules_dir="/lib/modules/${kernel_version}"
    if [ ! -d "$modules_dir" ]; then
        log_error "Kernel modules directory not found: ${modules_dir}"
        return 1
    fi
    
    local signed_count=0
    local failed_count=0
    
    # Function to sign a single module (handles compressed modules)
    sign_single_module() {
        local mod="$1"
        local temp_dir=""
        
        # Handle compressed modules
        if [[ "$mod" == *.ko.xz ]]; then
            temp_dir=$(mktemp -d)
            local mod_base="${mod%.ko.xz}"
            local temp_ko="${temp_dir}/$(basename "$mod_base").ko"
            
            # Decompress
            if ! xzcat "$mod" > "$temp_ko" 2>/dev/null; then
                rm -rf "$temp_dir"
                return 1
            fi
            
            # Sign
            if [ "$SIGN_TOOL" = "kmodsign" ]; then
                if ! kmodsign sha256 "$KEY" "$DER" "$temp_ko" 2>/dev/null; then
                    rm -rf "$temp_dir"
                    return 1
                fi
            else
                if ! "$SIGN_TOOL" sha256 "$KEY" "$CRT" "$temp_ko" 2>/dev/null; then
                    rm -rf "$temp_dir"
                    return 1
                fi
            fi
            
            # Recompress if writable
            if [ -w "$(dirname "$mod")" ]; then
                xz -f "$temp_ko" 2>/dev/null && mv "${temp_ko}.xz" "$mod" 2>/dev/null || true
            fi
            
            rm -rf "$temp_dir"
        else
            # Uncompressed module - sign directly if writable
            if [ -w "$mod" ]; then
                if [ "$SIGN_TOOL" = "kmodsign" ]; then
                    kmodsign sha256 "$KEY" "$DER" "$mod" 2>/dev/null || return 1
                else
                    "$SIGN_TOOL" sha256 "$KEY" "$CRT" "$mod" 2>/dev/null || return 1
                fi
            fi
        fi
    }
    
    # Find and sign all tuxedo modules
    while IFS= read -r -d '' mod; do
        if sign_single_module "$mod"; then
            ((signed_count++))
            log_info "Signed: $(basename "$mod")"
        else
            ((failed_count++))
            log_error "Failed to sign: $(basename "$mod")"
        fi
    done < <(find "$modules_dir" -type f \( -name 'tuxedo*.ko' -o -name 'tuxedo*.ko.xz' \) -print0 2>/dev/null || true)
    
    if [ $signed_count -gt 0 ]; then
        log_info "Successfully signed ${signed_count} module(s)"
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

Environment variables:
  TUXEDO_MOK_DIR - Directory containing MOK keys (default: /usr/share/tuxedo/mok)

EOF
    exit 0
fi

# Sign modules for specified kernel or current kernel
sign_modules "${1:-}"


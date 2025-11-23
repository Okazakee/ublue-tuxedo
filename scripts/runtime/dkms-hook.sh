#!/bin/bash
# DKMS post-install hook to automatically sign modules after DKMS builds them
# This ensures modules are signed whenever DKMS rebuilds them (e.g., after kernel updates)
# Handles compressed (.ko.xz) modules by decompressing, signing, and recompressing

set -euo pipefail

MOK_DIR="${TUXEDO_MOK_DIR:-/usr/share/tuxedo/mok}"
KEY="${MOK_DIR}/MOK.key"
DER="${MOK_DIR}/MOK.der"
CRT="${MOK_DIR}/MOK.crt"

# Only proceed if MOK keys exist
if [ ! -f "$KEY" ] || [ ! -f "$DER" ] || [ ! -f "$CRT" ]; then
    exit 0
fi

# Get kernel version from DKMS environment
KERNEL_VERSION="${kernelver:-$(uname -r)}"

# Find sign-file tool
SIGN_FILE=""
if [ -x "/usr/src/kernels/${KERNEL_VERSION}/scripts/sign-file" ]; then
    SIGN_FILE="/usr/src/kernels/${KERNEL_VERSION}/scripts/sign-file"
elif command -v kmodsign >/dev/null 2>&1; then
    SIGN_FILE="kmodsign"
else
    exit 0
fi

# Function to sign a module (handles compressed modules)
sign_module() {
    local mod=$1
    local temp_dir=$(mktemp -d)
    
    # If it's compressed, decompress first
    if [[ "$mod" == *.ko.xz ]]; then
        local mod_base="${mod%.ko.xz}"
        local temp_ko="${temp_dir}/$(basename "$mod_base").ko"
        
        # Decompress
        if ! xzcat "$mod" > "$temp_ko" 2>/dev/null; then
            rm -rf "$temp_dir"
            return 1
        fi
        
        # Sign
        if [ "$SIGN_FILE" = "kmodsign" ]; then
            if ! kmodsign sha256 "$KEY" "$DER" "$temp_ko" 2>/dev/null; then
                rm -rf "$temp_dir"
                return 1
            fi
        else
            if ! "$SIGN_FILE" sha256 "$KEY" "$CRT" "$temp_ko" 2>/dev/null; then
                rm -rf "$temp_dir"
                return 1
            fi
        fi
        
        # Recompress (only if we can write to the location)
        if [ -w "$(dirname "$mod")" ]; then
            xz -f "$temp_ko" 2>/dev/null && mv "${temp_ko}.xz" "$mod" 2>/dev/null || true
        fi
        
        rm -rf "$temp_dir"
    else
        # Uncompressed module - sign directly (if writable)
        if [ -w "$mod" ]; then
            if [ "$SIGN_FILE" = "kmodsign" ]; then
                kmodsign sha256 "$KEY" "$DER" "$mod" 2>/dev/null || return 1
            else
                "$SIGN_FILE" sha256 "$KEY" "$CRT" "$mod" 2>/dev/null || return 1
            fi
        fi
    fi
}

# Find and sign tuxedo modules that were just built
find "/lib/modules/${KERNEL_VERSION}" -type f \( -name 'tuxedo*.ko' -o -name 'tuxedo*.ko.xz' \) -print0 2>/dev/null | while IFS= read -r -d '' mod; do
    sign_module "$mod" || true
done

exit 0


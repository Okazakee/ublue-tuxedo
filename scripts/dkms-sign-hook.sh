#!/bin/bash
# DKMS post-install hook to automatically sign modules after DKMS builds them
# This ensures modules are signed whenever DKMS rebuilds them (e.g., after kernel updates)

MOK_DIR="/usr/share/aurora-tuxedo/mok"
KEY="${MOK_DIR}/MOK.key"
DER="${MOK_DIR}/MOK.der"

# Only proceed if MOK keys exist
if [ ! -f "$KEY" ] || [ ! -f "$DER" ]; then
    exit 0
fi

# Get kernel version from DKMS environment
KERNEL_VERSION="${kernelver:-$(uname -r)}"

# Find and sign tuxedo modules that were just built
if command -v kmodsign >/dev/null 2>&1; then
    find "/lib/modules/${KERNEL_VERSION}" -type f \( -name 'tuxedo*.ko' -o -name 'tuxedo*.ko.xz' \) -print0 2>/dev/null | while IFS= read -r -d '' mod; do
        # Only sign if module is not already signed or if it's newer than last signing attempt
        kmodsign sha256 "$KEY" "$DER" "$mod" 2>/dev/null || true
    done
elif [ -x "/usr/src/kernels/${KERNEL_VERSION}/scripts/sign-file" ]; then
    CRT="${MOK_DIR}/MOK.crt"
    find "/lib/modules/${KERNEL_VERSION}" -type f -name 'tuxedo*.ko' -print0 2>/dev/null | while IFS= read -r -d '' mod; do
        "/usr/src/kernels/${KERNEL_VERSION}/scripts/sign-file" sha256 "$KEY" "$CRT" "$mod" 2>/dev/null || true
    done
fi

exit 0


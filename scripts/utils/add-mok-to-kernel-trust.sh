#!/bin/bash
# Add MOK certificate to kernel's system keyring for module signing
# This ensures the kernel trusts modules signed with our MOK certificate
#
# Note: The kernel loads certificates from MOK enrollment at boot.
# This script ensures the certificate is in locations where the kernel can find it.

set -euo pipefail

# MOK directory (configurable via environment variable)
MOK_DIR="${TUXEDO_MOK_DIR:-/usr/share/tuxedo/mok}"
DER="${MOK_DIR}/MOK.der"
CRT="${MOK_DIR}/MOK.crt"

if [ ! -f "$DER" ] && [ ! -f "$CRT" ]; then
    echo "ERROR: MOK certificate not found in ${MOK_DIR}"
    exit 1
fi

# Convert DER to PEM if needed
if [ -f "$DER" ] && [ ! -f "$CRT" ]; then
    openssl x509 -inform DER -in "$DER" -out "$CRT" 2>/dev/null || true
fi

# Add certificate to /etc/keys directory for kernel to load at boot
# Some kernels read from here if CONFIG_SYSTEM_TRUSTED_KEYS is set
if [ -f "$CRT" ]; then
    mkdir -p /etc/keys
    cp "$CRT" /etc/keys/tuxedo-module-signing.pem 2>/dev/null || true
fi

# Ensure certificate is in overlay location for runtime access
# The kernel will load this via MOK enrollment done at boot
if [ -f "$DER" ]; then
    # Certificate is already in overlay, kernel will load it from MOK
    echo "MOK certificate is in place for kernel trust"
fi

# Note: The actual kernel trust comes from MOK enrollment at boot.
# This script ensures the certificate files are present in the image.
# Users must run setup-secureboot.sh after first boot to enroll the certificate.

echo "MOK certificate prepared for kernel trust"


#!/bin/bash
# Generate MOK certificate/key pair for Tuxedo module signing
# This creates a new certificate that can be used in GitHub secrets

set -euo pipefail

OUTPUT_DIR="${1:-./mok-keys}"
CN="${2:-Tuxedo Module Signing Key}"

echo "Generating MOK certificate/key pair..."
echo "Output directory: ${OUTPUT_DIR}"
echo "Certificate CN: ${CN}"

mkdir -p "${OUTPUT_DIR}"

# Generate private key
openssl genrsa -out "${OUTPUT_DIR}/MOK.key" 4096

# Generate certificate signing request
openssl req -new -x509 -key "${OUTPUT_DIR}/MOK.key" \
    -out "${OUTPUT_DIR}/MOK.crt" \
    -days 3650 \
    -subj "/CN=${CN}/O=Tuxedo Computer/OU=Kernel Modules/ST=Germany/C=DE"

# Convert to DER format
openssl x509 -inform PEM -in "${OUTPUT_DIR}/MOK.crt" \
    -outform DER -out "${OUTPUT_DIR}/MOK.der"

echo ""
echo "✓ Generated MOK certificate/key pair:"
echo "  - Private key: ${OUTPUT_DIR}/MOK.key"
echo "  - Certificate (PEM): ${OUTPUT_DIR}/MOK.crt"
echo "  - Certificate (DER): ${OUTPUT_DIR}/MOK.der"
echo ""
echo "Certificate fingerprint (SHA1):"
openssl x509 -inform DER -in "${OUTPUT_DIR}/MOK.der" -noout -fingerprint -sha1 | cut -d= -f2
echo ""
echo "To use in GitHub secrets:"
echo "1. MOK_PRIVATE_KEY: $(cat ${OUTPUT_DIR}/MOK.key)"
echo "2. MOK_CERTIFICATE_PEM: $(cat ${OUTPUT_DIR}/MOK.crt)"
echo "3. MOK_CERTIFICATE_DER: $(base64 < ${OUTPUT_DIR}/MOK.der)"
echo ""
echo "WARNING: After updating GitHub secrets, you'll need to:"
echo "1. Rebuild the image"
echo "2. Re-enroll the MOK certificate at boot (password: tuxedo)"
echo "3. Rebuild DKMS modules so they're signed with the new certificate"


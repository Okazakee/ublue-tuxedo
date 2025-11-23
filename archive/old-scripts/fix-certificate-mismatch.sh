#!/bin/bash
# Fix certificate mismatch and re-enroll new MOK certificate
# This script re-enrolls the new MOK certificate and re-signs modules

set -euo pipefail

MOK_DIR="/usr/share/aurora-tuxedo/mok"
KEY="${MOK_DIR}/MOK.key"
DER="${MOK_DIR}/MOK.der"
CRT="${MOK_DIR}/MOK.crt"
KVER=$(uname -r)
MODDIR="/usr/local/lib/modules/${KVER}/extra"
DKMS_MODULE_DIR="/var/lib/dkms/tuxedo-drivers/4.17.0/${KVER}/x86_64/module"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    log_error "This script must be run as root"
    echo "Please run with sudo: sudo $0"
    exit 1
fi

log_info "Tuxedo Secure Boot Certificate Fix"
log_info "==================================="
echo ""

# Check if MOK keys exist
if [ ! -f "$KEY" ] || [ ! -f "$DER" ] || [ ! -f "$CRT" ]; then
    log_error "MOK keys not found in ${MOK_DIR}"
    exit 1
fi

# Get certificate fingerprint
CERT_FP=$(openssl x509 -inform DER -in "$DER" -noout -fingerprint -sha1 | cut -d= -f2 | tr -d ':')
log_info "New certificate fingerprint: ${CERT_FP}"

# Check if certificate is already enrolled
if mokutil --list-enrolled 2>/dev/null | grep -qi "${CERT_FP,,}"; then
    log_success "New certificate already enrolled"
else
    log_warning "New certificate NOT enrolled yet"
    log_info "Enrolling new MOK certificate..."
    
    # Import the certificate
    if echo -e 'tuxedo\ntuxedo' | mokutil --import "$DER" 2>/dev/null; then
        log_success "MOK certificate imported successfully"
        log_warning "YOU MUST REBOOT NOW to complete enrollment!"
        log_info "During reboot, select 'Enroll MOK' and enter password: tuxedo"
        log_info ""
        log_info "After reboot, run this script again to re-sign modules"
        exit 0
    else
        log_error "Failed to import MOK certificate"
        exit 1
    fi
fi

# Re-sign modules with the new certificate
log_info "Re-signing modules with new certificate..."

# Find sign-file tool
SIGN_FILE=""
if [ -x "/usr/src/kernels/${KVER}/scripts/sign-file" ]; then
    SIGN_FILE="/usr/src/kernels/${KVER}/scripts/sign-file"
else
    log_error "sign-file not found"
    exit 1
fi

# Function to sign a module
sign_module_file() {
    local mod_path="$1"
    local mod_name=$(basename "$mod_path")
    
    # Decompress if needed
    if [[ "$mod_path" == *.ko.xz ]]; then
        local temp_ko="${MODDIR}/${mod_name%.ko.xz}.ko"
        xzcat "$mod_path" > "$temp_ko" 2>/dev/null || return 1
        "$SIGN_FILE" sha256 "$KEY" "$CRT" "$temp_ko" 2>/dev/null || return 1
        rm -f "$mod_path"
        log_info "  Signed: ${mod_name}"
    elif [[ "$mod_path" == *.ko ]]; then
        "$SIGN_FILE" sha256 "$KEY" "$CRT" "$mod_path" 2>/dev/null || return 1
        log_info "  Signed: ${mod_name}"
    fi
    return 0
}

# Re-sign modules in writable location
if [ -d "$MODDIR" ]; then
    log_info "Re-signing modules in ${MODDIR}..."
    for mod in "$MODDIR"/tuxedo*.ko*; do
        [ -f "$mod" ] && sign_module_file "$mod" || true
    done
fi

# Re-sign DKMS modules
if [ -d "$DKMS_MODULE_DIR" ]; then
    log_info "Re-signing DKMS modules..."
    for mod in "$DKMS_MODULE_DIR"/tuxedo*.ko.xz; do
        if [ -f "$mod" ]; then
            local mod_name=$(basename "$mod" .ko.xz)
            local temp_ko="/tmp/${mod_name}.ko"
            xzcat "$mod" > "$temp_ko" 2>/dev/null || continue
            "$SIGN_FILE" sha256 "$KEY" "$CRT" "$temp_ko" 2>/dev/null || continue
            xz -f "$temp_ko" 2>/dev/null && mv "${temp_ko}.xz" "$mod" 2>/dev/null || true
            log_info "  Signed DKMS: ${mod_name}"
        fi
    done
fi

log_success "Certificate fix complete!"
log_info ""
log_info "Next steps:"
log_info "1. Reboot if you just enrolled the MOK certificate"
log_info "2. After reboot, modules should load automatically"
log_info "3. If modules still don't load, check SELinux policies"


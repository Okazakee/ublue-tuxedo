#!/bin/bash
# Setup Secure Boot for Tuxedo modules
# Handles MOK enrollment and module signing

set -euo pipefail

# MOK directory (configurable via environment variable)
MOK_DIR="${TUXEDO_MOK_DIR:-/usr/share/tuxedo/mok}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

check_secure_boot() {
    if command -v mokutil >/dev/null 2>&1; then
        if mokutil --sb-state 2>/dev/null | grep -q "SecureBoot enabled"; then
            return 0
        fi
    fi
    return 1
}

import_mok_certificate() {
    local cert_file="$1"
    local password="${2:-}"
    
    if [ ! -f "$cert_file" ]; then
        log_error "Certificate file not found: $cert_file"
        return 1
    fi
    
    log_info "Importing MOK certificate: $cert_file"
    
    # Prompt for password if not provided
    if [ -z "$password" ]; then
        log_info "MOK enrollment requires a password for security"
        log_info "You will need to enter this password at the MOK enrollment screen during reboot"
        read -sp "Enter MOK enrollment password (will not be displayed): " password
        echo
        read -sp "Confirm MOK enrollment password: " password_confirm
        echo
        
        if [ "$password" != "$password_confirm" ]; then
            log_error "Passwords do not match"
            return 1
        fi
        
        if [ -z "$password" ]; then
            log_error "Password cannot be empty"
            return 1
        fi
    fi
    
    # Import the certificate
    if echo -e "${password}\n${password}" | mokutil --import "$cert_file" 2>/dev/null; then
        log_success "MOK certificate imported successfully"
        log_warning "You will need to reboot to complete the enrollment"
        log_info "During reboot:"
        log_info "  1. You will see a MOK enrollment screen"
        log_info "  2. Select 'Enroll MOK'"
        log_info "  3. Enter the password you just set"
        log_info "  4. Select 'Continue' and then 'Reboot'"
        return 0
    else
        log_error "Failed to import MOK certificate"
        log_error "Make sure you have the required permissions and mokutil is available"
        return 1
    fi
}

setup_mok_enrollment() {
    log_info "Setting up MOK enrollment for Secure Boot"
    
    if [ ! -d "$MOK_DIR" ]; then
        log_error "MOK directory not found: $MOK_DIR"
        log_error "Please ensure the Tuxedo image is properly installed"
        return 1
    fi
    
    local cert_file="$MOK_DIR/MOK.der"
    if [ ! -f "$cert_file" ]; then
        log_error "MOK certificate not found: $cert_file"
        log_error "Please rebuild the image with MOK signing enabled"
        return 1
    fi
    
    # Check if already enrolled
    if mokutil --list-enrolled 2>/dev/null | grep -qi "tuxedo\|MOK"; then
        log_info "MOK certificate appears to be already enrolled"
        return 0
    fi
    
    # Import certificate with password prompt
    import_mok_certificate "$cert_file"
}

sign_modules() {
    local kernel_version="${1:-$(uname -r)}"
    
    log_info "Signing Tuxedo modules for kernel: ${kernel_version}"
    
    local KEY="${MOK_DIR}/MOK.key"
    local DER="${MOK_DIR}/MOK.der"
    local CRT="${MOK_DIR}/MOK.crt"
    
    if [ ! -f "$KEY" ] || [ ! -f "$DER" ]; then
        log_error "MOK keys not found in ${MOK_DIR}"
        return 1
    fi
    
    # Use the sign-modules script if available
    if [ -x "/usr/local/bin/tuxedo-sign-modules" ]; then
        /usr/local/bin/tuxedo-sign-modules "$kernel_version"
        return $?
    elif [ -x "/usr/bin/sign-modules.sh" ]; then
        /usr/bin/sign-modules.sh "$kernel_version"
        return $?
    fi
    
    # Fallback: sign modules directly
    local modules_dir="/lib/modules/${kernel_version}"
    if [ ! -d "$modules_dir" ]; then
        log_warning "Kernel modules directory not found: ${modules_dir}"
        return 1
    fi
    
    local signed_count=0
    
    # Sign modules using kmodsign (preferred)
    if command -v kmodsign >/dev/null 2>&1; then
        while IFS= read -r -d '' mod; do
            if kmodsign sha256 "$KEY" "$DER" "$mod" 2>/dev/null; then
                ((signed_count++))
                log_info "Signed: $(basename "$mod")"
            fi
        done < <(find "$modules_dir" -type f \( -name 'tuxedo*.ko' -o -name 'tuxedo*.ko.xz' \) -print0 2>/dev/null || true)
    # Fallback to sign-file script
    elif [ -x "/usr/src/kernels/${kernel_version}/scripts/sign-file" ]; then
        while IFS= read -r -d '' mod; do
            if "/usr/src/kernels/${kernel_version}/scripts/sign-file" sha256 "$KEY" "$CRT" "$mod" 2>/dev/null; then
                ((signed_count++))
                log_info "Signed: $(basename "$mod")"
            fi
        done < <(find "$modules_dir" -type f -name 'tuxedo*.ko' -print0 2>/dev/null || true)
    else
        log_error "No signing tool available (kmodsign or sign-file)"
        return 1
    fi
    
    if [ $signed_count -gt 0 ]; then
        log_success "Successfully signed ${signed_count} module(s)"
        depmod -a "${kernel_version}" 2>/dev/null || true
        return 0
    else
        log_warning "No Tuxedo modules found to sign"
        return 1
    fi
}

main() {
    log_info "Tuxedo Secure Boot Setup"
    log_info "========================="
    
    # Check if running as root
    if [ "$EUID" -ne 0 ]; then
        log_error "This script must be run as root"
        exit 1
    fi
    
    # Check if Secure Boot is enabled
    if ! check_secure_boot; then
        log_warning "Secure Boot is not enabled"
        log_info "Tuxedo modules should load without signing requirements"
        exit 0
    fi
    
    log_info "Secure Boot is enabled"
    
    # Check if MOK is already enrolled
    if mokutil --list-enrolled 2>/dev/null | grep -qi "tuxedo\|MOK"; then
        log_info "MOK certificate appears to be enrolled"
        log_info "Signing existing modules..."
        sign_modules "$(uname -r)"
    else
        log_info "Setting up MOK enrollment for Tuxedo modules"
        
        # Direct MOK enrollment
        if setup_mok_enrollment; then
            log_success "MOK enrollment setup completed"
            log_warning "Please reboot to complete the enrollment process"
            log_info "After reboot, modules will be automatically signed"
        else
            log_error "Failed to setup MOK enrollment"
            exit 1
        fi
    fi
}

# Show usage if help requested
if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
    cat << EOF
Tuxedo Secure Boot Setup

This script configures Secure Boot for Tuxedo kernel modules by enrolling
a Machine Owner Key (MOK) certificate for module signing.

Usage: $0 [--help]

Process:
1. Checks if Secure Boot is enabled
2. Prompts for MOK enrollment password
3. Imports MOK certificate
4. Provides reboot instructions to complete enrollment

Environment variables:
  TUXEDO_MOK_DIR - Directory containing MOK keys (default: /usr/share/tuxedo/mok)

The certificate is included with pre-built Tuxedo images.

EOF
    exit 0
fi

main "$@"


#!/bin/bash
# Setup Secure Boot for Tuxedo modules
# Supports both Aurora key path and MOK enrollment fallback

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MOK_DIR="/usr/share/aurora-tuxedo/mok"

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

# Aurora key check removed - using direct MOK enrollment only

import_mok_certificate() {
    local cert_file="$1"
    
    if [ ! -f "$cert_file" ]; then
        log_error "Certificate file not found: $cert_file"
        return 1
    fi
    
    log_info "Importing MOK certificate: $cert_file"
    
    # Import the certificate with hardcoded password (PR pattern)
    if echo -e 'tuxedo\ntuxedo' | mokutil --import "$cert_file"; then
        log_success "MOK certificate imported successfully"
        log_warning "You will need to reboot and enter 'tuxedo' at the MOK screen"
        log_info "During reboot, select 'Enroll MOK' and enter password: tuxedo"
        return 0
    else
        log_error "Failed to import MOK certificate"
        return 1
    fi
}

# Aurora keys setup removed - using direct MOK enrollment only

setup_mok_enrollment() {
    log_info "Setting up MOK enrollment for Secure Boot"
    
    if [ ! -d "$MOK_DIR" ]; then
        log_error "MOK directory not found: $MOK_DIR"
        log_error "Please ensure the aurora-tuxedo image is properly installed"
        return 1
    fi
    
    local cert_file="$MOK_DIR/MOK.der"
    if [ -f "$cert_file" ]; then
        log_info "Importing MOK certificate with hardcoded password (PR pattern)"
        
        # Use hardcoded password as in PR
        if echo -e 'tuxedo\ntuxedo' | mokutil --import "$cert_file"; then
            log_success "MOK certificate imported successfully"
            log_warning "You will need to reboot and enter 'tuxedo' at the MOK screen"
            log_info "During reboot, select 'Enroll MOK' and enter password: tuxedo"
            return 0
        else
            log_error "Failed to import MOK certificate"
            return 1
        fi
    else
        log_error "MOK certificate not found: $cert_file"
        log_error "Please rebuild the image with MOK signing enabled"
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
    log_info "Setting up MOK enrollment for Tuxedo modules"
    
    # Direct MOK enrollment (no fallback complexity)
    if setup_mok_enrollment; then
        log_success "MOK enrollment setup completed"
        log_warning "Please reboot to complete the enrollment process"
    else
        log_error "Failed to setup MOK enrollment"
        exit 1
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
2. Imports MOK certificate automatically 
3. Provides reboot instructions to complete enrollment

The certificate is included with pre-built Tuxedo images.

EOF
    exit 0
fi

main "$@"

#!/bin/bash
# Comprehensive Tuxedo Secure Boot Diagnostic Script
# Collects all system state information needed to debug Secure Boot and module loading issues

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Output file
OUTPUT_FILE="tuxedo-secureboot-diagnostics-$(date +%Y%m%d-%H%M%S).txt"
LOG_DIR="/tmp/tuxedo-diagnostics"

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$OUTPUT_FILE"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$OUTPUT_FILE"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$OUTPUT_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$OUTPUT_FILE"
}

log_section() {
    echo "" | tee -a "$OUTPUT_FILE"
    echo "===========================================" | tee -a "$OUTPUT_FILE"
    echo "  $1" | tee -a "$OUTPUT_FILE"
    echo "===========================================" | tee -a "$OUTPUT_FILE"
    echo "" | tee -a "$OUTPUT_FILE"
}

run_command() {
    local cmd="$1"
    local desc="${2:-}"
    if [ -n "$desc" ]; then
        log_info "$desc"
    fi
    echo "Command: $cmd" >> "$OUTPUT_FILE"
    echo "---" >> "$OUTPUT_FILE"
    eval "$cmd" >> "$OUTPUT_FILE" 2>&1 || true
    echo "Exit code: ${PIPESTATUS[0]}" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
}

check_sudo() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}[ERROR]${NC} This script requires root privileges"
        echo "Please run with sudo: sudo $0"
        exit 1
    fi
}

# Show usage if help requested (before sudo check)
if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
    cat << EOF
Tuxedo Secure Boot Diagnostic Script

This script collects comprehensive system state information needed to debug
Secure Boot and module loading issues with Tuxedo kernel modules.

Usage: sudo $0 [--help]

What it collects:
- System information (OS, kernel version, hardware)
- Secure Boot status and MOK enrollment status
- MOK certificate information and fingerprints
- Kernel module signing keys and trust status
- DKMS module status and locations
- Module loading status and signatures
- Systemd service status and logs
- Recent errors related to Tuxedo modules
- SELinux status and policies
- TCC (Tuxedo Control Center) status

Output:
- Text file: tuxedo-secureboot-diagnostics-YYYYMMDD-HHMMSS.txt
- Log directory: /tmp/tuxedo-diagnostics/

The script requires root privileges to access system information and logs.

EOF
    exit 0
fi

# Check sudo first
check_sudo

# Create log directory
mkdir -p "$LOG_DIR"

# Initialize output file
> "$OUTPUT_FILE"
echo "Tuxedo Secure Boot Diagnostics Report" >> "$OUTPUT_FILE"
echo "Generated: $(date)" >> "$OUTPUT_FILE"
echo "===========================================" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

log_info "Starting Tuxedo Secure Boot Diagnostics"
log_info "Output file: $OUTPUT_FILE"
log_info "Log directory: $LOG_DIR"
log_info ""

# Header
log_section "DIAGNOSTIC REPORT"
run_command "date"
run_command "uname -a"

# System Information
log_section "SYSTEM INFORMATION"
run_command "cat /etc/os-release" "OS Release Information"
run_command "hostnamectl" "Hostname and System Info"
run_command "rpm -q kernel --qf '%{NAME}-%{VERSION}-%{RELEASE}\n' | tail -5" "Installed Kernels"
run_command "uname -r" "Current Kernel Version"
run_command "rpm -q kernel-devel --qf '%{NAME}-%{VERSION}-%{RELEASE}\n' 2>/dev/null | tail -1 || echo 'No kernel-devel package found'" "Kernel Development Package"

# Secure Boot Status
log_section "SECURE BOOT STATUS"
run_command "mokutil --sb-state 2>&1 || echo 'mokutil not available'" "Secure Boot State"
run_command "mokutil --list-enrolled 2>&1 || echo 'mokutil not available'" "Enrolled MOK Keys"
run_command "mokutil --list-new 2>&1 || echo 'No pending MOK enrollments'" "Pending MOK Enrollments"
run_command "efibootmgr -v 2>&1 || echo 'efibootmgr not available'" "EFI Boot Entries"
run_command "dmesg | grep -i 'secure boot\|efi\|mok' | tail -20" "Kernel Messages about Secure Boot"

# MOK Certificate Information
log_section "MOK CERTIFICATE INFORMATION"
run_command "ls -la /usr/share/aurora-tuxedo/mok/ 2>&1 || echo 'MOK directory not found'" "MOK Directory Contents"
run_command "file /usr/share/aurora-tuxedo/mok/* 2>&1 || echo 'MOK files not found'" "MOK File Types"
run_command "openssl x509 -inform DER -in /usr/share/aurora-tuxedo/mok/MOK.der -noout -subject -issuer -dates -fingerprint -sha1 2>&1 || echo 'MOK.der not found or invalid'" "MOK Certificate Details (DER)"
run_command "openssl x509 -in /usr/share/aurora-tuxedo/mok/MOK.crt -noout -subject -issuer -dates -fingerprint -sha1 2>&1 || echo 'MOK.crt not found or invalid'" "MOK Certificate Details (PEM)"
run_command "test -f /usr/share/aurora-tuxedo/mok/MOK.key && echo 'MOK.key exists' || echo 'MOK.key NOT FOUND'" "MOK Private Key Check"

# Kernel Module Signing Keys
log_section "KERNEL MODULE SIGNING KEYS"
run_command "keyctl show %:.builtin_trusted 2>&1 | grep -i tuxedo || echo 'No Tuxedo keys in builtin trust'" "Built-in Trusted Keys (Tuxedo)"
run_command "keyctl show %:.builtin_trusted 2>&1 | tail -20" "Built-in Trusted Keys (Last 20)"
run_command "keyctl show %:.secondary_trusted 2>&1 | grep -i tuxedo || echo 'No Tuxedo keys in secondary trust'" "Secondary Trusted Keys (Tuxedo)"
run_command "keyctl show %:.secondary_trusted 2>&1 | tail -20" "Secondary Trusted Keys (Last 20)"
run_command "cat /proc/keys | grep -i tuxedo || echo 'No Tuxedo keys in /proc/keys'" "Active Keys (Tuxedo)"
run_command "dmesg | grep -i 'key.*tuxedo\|certificate.*tuxedo' | tail -20" "Kernel Messages about Tuxedo Keys"

# DKMS Status
log_section "DKMS STATUS"
run_command "dkms status" "DKMS Module Status"
run_command "dkms status tuxedo-drivers" "Tuxedo Drivers DKMS Status"
run_command "ls -la /var/lib/dkms/tuxedo-drivers/*/ 2>&1 | head -30" "DKMS Module Directories"
run_command "find /var/lib/dkms/tuxedo-drivers -name '*.ko*' -type f 2>/dev/null | head -20" "DKMS Module Files"

# Module Locations
log_section "MODULE LOCATIONS"
KVER=$(uname -r)
run_command "ls -la /lib/modules/${KVER}/updates/ 2>&1 | grep tuxedo || echo 'No Tuxedo modules in /lib/modules/${KVER}/updates/'" "Modules in /lib/modules"
run_command "ls -la /usr/local/lib/modules/${KVER}/extra/ 2>&1 || echo 'Writable modules directory not found'" "Modules in /usr/local/lib/modules"
run_command "find /lib/modules/${KVER} -name 'tuxedo*.ko*' -type f 2>&1" "All Tuxedo Modules in /lib/modules"
run_command "find /usr/local/lib/modules/${KVER} -name 'tuxedo*.ko*' -type f 2>&1" "All Tuxedo Modules in /usr/local/lib/modules"

# Module Loading Status
log_section "MODULE LOADING STATUS"
run_command "lsmod | grep tuxedo || echo 'No Tuxedo modules loaded'" "Loaded Tuxedo Modules"
run_command "modinfo tuxedo_keyboard 2>&1 || echo 'tuxedo_keyboard module not found'" "tuxedo_keyboard Module Info"
run_command "modinfo tuxedo_io 2>&1 || echo 'tuxedo_io module not found'" "tuxedo_io Module Info"
run_command "modinfo tuxedo_compatibility_check 2>&1 || echo 'tuxedo_compatibility_check module not found'" "tuxedo_compatibility_check Module Info"
run_command "modprobe -n tuxedo_keyboard 2>&1" "Module Dependencies Check (tuxedo_keyboard)"
run_command "depmod -n ${KVER} 2>&1 | grep tuxedo | head -20" "Module Dependencies (Tuxedo)"

# Module Signing Status
log_section "MODULE SIGNING STATUS"
run_command "find /lib/modules/${KVER} -name 'tuxedo*.ko*' -type f 2>/dev/null | while read mod; do echo \"Checking: \$mod\"; modinfo \"\$mod\" 2>&1 | grep -E 'signer|sig_key|signature' || echo '  No signature info'; done | head -50" "Module Signature Information"
run_command "find /usr/local/lib/modules/${KVER} -name 'tuxedo*.ko*' -type f 2>/dev/null | while read mod; do echo \"Checking: \$mod\"; modinfo \"\$mod\" 2>&1 | grep -E 'signer|sig_key|signature' || echo '  No signature info'; done | head -50" "Module Signature Information (Writable Location)"
run_command "find /lib/modules/${KVER} -name 'tuxedo*.ko' -type f -exec sh -c 'echo \"File: \$1\"; hexdump -C \"\$1\" | tail -3' _ {} \\; 2>/dev/null | head -80" "Module File Headers (Binary Check)"

# Module Signing Tools
log_section "MODULE SIGNING TOOLS"
run_command "which kmodsign || echo 'kmodsign not found'" "kmodsign Location"
run_command "test -x /usr/src/kernels/${KVER}/scripts/sign-file && echo 'sign-file exists' || echo 'sign-file NOT FOUND'" "sign-file Check"
run_command "ls -la /usr/src/kernels/${KVER}/scripts/sign-file 2>&1 || echo 'sign-file path not found'" "sign-file Details"

# Systemd Services
log_section "SYSTEMD SERVICES"
run_command "systemctl status load-tuxedo-modules.service --no-pager -l 2>&1 || echo 'Service not found'" "load-tuxedo-modules.service Status"
run_command "systemctl status sign-tuxedo-modules.service --no-pager -l 2>&1 || echo 'Service not found'" "sign-tuxedo-modules.service Status"
run_command "systemctl status tccd.service --no-pager -l 2>&1 || echo 'Service not found'" "tccd.service Status"
run_command "systemctl is-enabled load-tuxedo-modules.service 2>&1" "load-tuxedo-modules.service Enabled Status"
run_command "systemctl is-enabled sign-tuxedo-modules.service 2>&1" "sign-tuxedo-modules.service Enabled Status"

# Service Logs
log_section "SERVICE LOGS"
run_command "journalctl -u load-tuxedo-modules.service --no-pager -n 50 2>&1" "load-tuxedo-modules.service Logs (Last 50)"
run_command "journalctl -u sign-tuxedo-modules.service --no-pager -n 50 2>&1" "sign-tuxedo-modules.service Logs (Last 50)"
run_command "journalctl -u tccd.service --no-pager -n 50 2>&1" "tccd.service Logs (Last 50)"
run_command "dmesg | grep -i 'tuxedo\|module.*sign' | tail -50" "Kernel Messages (Tuxedo/Module Signing)"

# Scripts and Hooks
log_section "SCRIPTS AND HOOKS"
run_command "ls -la /usr/local/bin/load-tuxedo-modules.sh /usr/bin/sign-modules.sh /usr/bin/setup-secureboot 2>&1" "Script Locations"
run_command "test -x /usr/local/bin/load-tuxedo-modules.sh && echo 'load-tuxedo-modules.sh executable' || echo 'NOT executable'" "load-tuxedo-modules.sh Executable Check"
run_command "ls -la /etc/dkms/post_install.d/ 2>&1 || echo 'DKMS post_install.d not found'" "DKMS Post-Install Hooks"
run_command "cat /etc/dkms/post_install.d/99-sign-tuxedo-modules.sh 2>&1 | head -30 || echo 'DKMS hook not found'" "DKMS Hook Contents"

# Filesystem Information
log_section "FILESYSTEM INFORMATION"
run_command "mount | grep -E '^/dev.*on /.*ro' || echo 'No read-only mounts found'" "Read-Only Mounts"
run_command "findmnt / -o TARGET,SOURCE,FSTYPE,OPTIONS" "Root Filesystem Info"
run_command "rpm-ostree status 2>&1 || echo 'Not an rpm-ostree system'" "RPM-OSTree Status"

# Certificate Trust Locations
log_section "CERTIFICATE TRUST LOCATIONS"
run_command "ls -la /etc/keys/ 2>&1 || echo '/etc/keys/ not found'" "System Keys Directory"
run_command "find /etc/keys -name '*tuxedo*' -o -name '*mok*' 2>&1" "Tuxedo/MOK Keys in /etc/keys"
run_command "ls -la /etc/pki/ 2>&1 | head -20" "PKI Directory Contents"
run_command "find /etc/pki -name '*tuxedo*' -o -name '*mok*' 2>&1" "Tuxedo/MOK Keys in /etc/pki"

# SELinux Status
log_section "SELINUX STATUS"
run_command "getenforce 2>&1 || echo 'SELinux not available'" "SELinux Enforcing Status"
run_command "sestatus 2>&1 || echo 'SELinux not available'" "SELinux Status"
run_command "semodule -l | grep tccd || echo 'No tccd SELinux module found'" "TCCD SELinux Module"

# TCC (Tuxedo Control Center) Status
log_section "TUXEDO CONTROL CENTER STATUS"
run_command "which tuxedo-control-center || echo 'TCC not found in PATH'" "TCC Binary Location"
run_command "rpm -q tuxedo-control-center --qf '%{NAME}-%{VERSION}-%{RELEASE}\n' 2>&1 || echo 'TCC package not found'" "TCC Package Info"
run_command "rpm -q tuxedo-drivers --qf '%{NAME}-%{VERSION}-%{RELEASE}\n' 2>&1 || echo 'Tuxedo drivers package not found'" "Tuxedo Drivers Package Info"
run_command "systemctl status tccd.service --no-pager -l 2>&1 || echo 'tccd.service not found'" "TCC Service Detailed Status"

# Module Loading Attempts
log_section "MANUAL MODULE LOADING TEST"
run_command "modprobe -n tuxedo_compatibility_check 2>&1" "Dry-run: tuxedo_compatibility_check"
run_command "modprobe -n tuxedo_keyboard 2>&1" "Dry-run: tuxedo_keyboard"
run_command "modprobe -n tuxedo_io 2>&1" "Dry-run: tuxedo_io"

# File Permissions
log_section "FILE PERMISSIONS"
run_command "ls -la /usr/share/aurora-tuxedo/mok/ 2>&1" "MOK Directory Permissions"
run_command "ls -la /usr/local/lib/modules/${KVER}/extra/ 2>&1" "Module Directory Permissions"
run_command "ls -la /usr/local/bin/load-tuxedo-modules.sh 2>&1" "Script Permissions"

# Network and Package Repositories
log_section "PACKAGE REPOSITORIES"
run_command "dnf repolist 2>&1 | grep -i tuxedo || echo 'No Tuxedo repositories found'" "Tuxedo Repositories"
run_command "cat /etc/yum.repos.d/tuxedo.repo 2>&1 || echo 'Tuxedo repo file not found'" "Tuxedo Repository Configuration"

# Recent Errors
log_section "RECENT ERRORS"
run_command "journalctl -p err --no-pager -n 100 2>&1 | grep -i 'tuxedo\|module\|secure\|mok\|sign' | tail -50" "Recent System Errors (Tuxedo Related)"
run_command "dmesg | grep -iE 'error|fail|reject|denied' | grep -i 'tuxedo\|module\|sign' | tail -30" "Kernel Errors (Tuxedo Related)"

# Environment Variables
log_section "ENVIRONMENT VARIABLES"
run_command "env | grep -i 'secure\|mok\|tuxedo\|module' || echo 'No relevant environment variables'" "Relevant Environment Variables"

# Hardware Information
log_section "HARDWARE INFORMATION"
run_command "dmidecode -s system-manufacturer 2>&1 || echo 'dmidecode not available'" "System Manufacturer"
run_command "dmidecode -s system-product-name 2>&1 || echo 'dmidecode not available'" "System Product Name"
run_command "lspci | grep -i 'vga\|display\|3d' || echo 'No GPU found'" "GPU Information"

# Final Summary
log_section "DIAGNOSTIC SUMMARY"
run_command "echo '=== KEY FINDINGS ==='" "Summary Header"
run_command "echo ''" ""
run_command "echo 'Kernel Version: $(uname -r)'" ""
run_command "echo 'Secure Boot: $(mokutil --sb-state 2>&1 || echo unknown)'" ""
run_command "echo 'Tuxedo Modules Loaded: $(lsmod | grep -c tuxedo || echo 0)'" ""
run_command "echo 'MOK Keys Present: $(test -f /usr/share/aurora-tuxedo/mok/MOK.key && echo yes || echo no)'" ""
run_command "echo 'Module Service Enabled: $(systemctl is-enabled load-tuxedo-modules.service 2>&1)'" ""
run_command "echo 'Module Service Active: $(systemctl is-active load-tuxedo-modules.service 2>&1)'" ""

# Copy relevant logs
log_section "COPYING LOGS"
run_command "cp -r /var/log/*tuxedo* $LOG_DIR/ 2>&1 || echo 'No Tuxedo logs found'" "Copying Tuxedo Logs"
run_command "journalctl -u load-tuxedo-modules.service --no-pager > $LOG_DIR/load-tuxedo-modules.log 2>&1" "Exporting Module Service Logs"
run_command "journalctl -u sign-tuxedo-modules.service --no-pager > $LOG_DIR/sign-tuxedo-modules.log 2>&1" "Exporting Sign Service Logs"
run_command "journalctl -u tccd.service --no-pager > $LOG_DIR/tccd.log 2>&1" "Exporting TCC Service Logs"
run_command "dmesg > $LOG_DIR/dmesg.log 2>&1" "Exporting Kernel Messages"

log_success "Diagnostics complete!"
log_info "Output file: $OUTPUT_FILE"
log_info "Log directory: $LOG_DIR"
log_info ""
log_info "Please review the output file and share it for debugging if issues persist."

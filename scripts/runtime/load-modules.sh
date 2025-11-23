#!/bin/bash
# Load Tuxedo kernel modules in correct order
# Handles kernel updates by copying signed modules from DKMS to writable location

set -euo pipefail

KVER=$(uname -r)
MODDIR="/usr/local/lib/modules/${KVER}/extra"
DKMS_MODULE_DIR="/var/lib/dkms/tuxedo-drivers/4.17.0/${KVER}/x86_64/module"
MOK_DIR="${TUXEDO_MOK_DIR:-/usr/share/tuxedo/mok}"
KEY="${MOK_DIR}/MOK.key"
CRT="${MOK_DIR}/MOK.crt"
DER="${MOK_DIR}/MOK.der"

# Create directory if needed
mkdir -p "${MODDIR}"

# Check if MOK keys exist (for signing)
HAS_MOK_KEYS=false
if [ -f "$KEY" ] && [ -f "$CRT" ]; then
    HAS_MOK_KEYS=true
fi

# Find sign-file tool
SIGN_FILE=""
if [ -x "/usr/src/kernels/${KVER}/scripts/sign-file" ]; then
    SIGN_FILE="/usr/src/kernels/${KVER}/scripts/sign-file"
elif command -v kmodsign >/dev/null 2>&1; then
    SIGN_FILE="kmodsign"
fi

# Function to copy, decompress, and sign a module
copy_and_sign_module() {
    local mod_name=$1
    local source_xz="${DKMS_MODULE_DIR}/${mod_name}.ko.xz"
    local target_ko="${MODDIR}/${mod_name}.ko"
    local target_xz="${MODDIR}/${mod_name}.ko.xz"
    
    # Check if source exists
    if [ ! -f "$source_xz" ]; then
        return 1
    fi
    
    # Check if target already exists and is newer (don't re-copy if already done)
    if [ -f "$target_ko" ] && [ "$target_ko" -nt "$source_xz" ]; then
        return 0
    fi
    
    # Copy compressed module
    cp "$source_xz" "$target_xz" 2>/dev/null || return 1
    
    # Decompress
    xzcat "$target_xz" > "$target_ko" 2>/dev/null || return 1
    
    # Sign the uncompressed module if MOK keys are available
    if [ "$HAS_MOK_KEYS" = true ] && [ -n "$SIGN_FILE" ]; then
        if [ "$SIGN_FILE" = "kmodsign" ]; then
            kmodsign sha256 "$KEY" "$DER" "$target_ko" 2>/dev/null || return 1
        else
            "$SIGN_FILE" sha256 "$KEY" "$CRT" "$target_ko" 2>/dev/null || return 1
        fi
    fi
    
    # Remove compressed version (we keep uncompressed for loading)
    rm -f "$target_xz"
    
    return 0
}

# Copy and sign all Tuxedo modules for current kernel
if [ -d "$DKMS_MODULE_DIR" ]; then
    copy_and_sign_module "tuxedo_compatibility_check" || true
    copy_and_sign_module "tuxedo_keyboard" || true
    copy_and_sign_module "tuxedo_io" || true
    copy_and_sign_module "tuxedo_nb04_wmi_ab" || true
    copy_and_sign_module "tuxedo_nb04_wmi_bs" || true
    copy_and_sign_module "tuxedo_nb04_sensors" || true
    copy_and_sign_module "tuxedo_nb04_power_profiles" || true
    copy_and_sign_module "tuxedo_nb04_kbd_backlight" || true
fi

# Load dependencies
modprobe led-class-multicolor sparse-keymap 2>/dev/null || true

# Load modules in correct order
if [ -f "${MODDIR}/tuxedo_compatibility_check.ko" ] && ! lsmod | grep -q tuxedo_compatibility_check; then
    insmod "${MODDIR}/tuxedo_compatibility_check.ko" || true
fi

if [ -f "${MODDIR}/tuxedo_keyboard.ko" ] && ! lsmod | grep -q tuxedo_keyboard; then
    insmod "${MODDIR}/tuxedo_keyboard.ko" || true
fi

# Load tuxedo_io (needed by TCC)
if [ -f "${MODDIR}/tuxedo_io.ko" ] && ! lsmod | grep -q "^tuxedo_io "; then
    insmod "${MODDIR}/tuxedo_io.ko" || true
fi

# Load nb04-specific modules for InfinityBook Gen10
if [ -f "${MODDIR}/tuxedo_nb04_wmi_ab.ko" ] && ! lsmod | grep -q tuxedo_nb04_wmi_ab; then
    insmod "${MODDIR}/tuxedo_nb04_wmi_ab.ko" || true
fi

if [ -f "${MODDIR}/tuxedo_nb04_wmi_bs.ko" ] && ! lsmod | grep -q tuxedo_nb04_wmi_bs; then
    insmod "${MODDIR}/tuxedo_nb04_wmi_bs.ko" || true
fi

if [ -f "${MODDIR}/tuxedo_nb04_sensors.ko" ] && ! lsmod | grep -q tuxedo_nb04_sensors; then
    insmod "${MODDIR}/tuxedo_nb04_sensors.ko" || true
fi

if [ -f "${MODDIR}/tuxedo_nb04_power_profiles.ko" ] && ! lsmod | grep -q tuxedo_nb04_power_profiles; then
    insmod "${MODDIR}/tuxedo_nb04_power_profiles.ko" || true
fi

# Try to load keyboard backlight (may fail if hardware doesn't support it)
if [ -f "${MODDIR}/tuxedo_nb04_kbd_backlight.ko" ] && ! lsmod | grep -q tuxedo_nb04_kbd_backlight; then
    insmod "${MODDIR}/tuxedo_nb04_kbd_backlight.ko" 2>/dev/null || true
fi


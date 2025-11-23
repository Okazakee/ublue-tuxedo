# Secure Boot Support for Tuxedo Modules

This document explains how Secure Boot works with Tuxedo Control Center (TCC) and the Tuxedo kernel modules.

## Overview

**TCC itself doesn't require Secure Boot** - it's a userspace application. However, **TCC depends on Tuxedo kernel modules** (`tuxedo_io`, `tuxedo_keyboard`) which **must be signed** when Secure Boot is enabled.

## How It Works

### 1. Build Time

During image build:
- MOK (Machine Owner Key) certificates are embedded from GitHub Secrets
- Tuxedo kernel modules are built via DKMS
- Modules are **signed with the MOK key** during build
- Certificates are placed in `/usr/share/tuxedo/mok/`

### 2. First Boot (Secure Boot Setup)

When you first boot the image with Secure Boot enabled:

1. **Run the setup script**:
   ```bash
   sudo setup-secureboot
   ```

2. **The script will**:
   - Check if Secure Boot is enabled
   - Prompt for a MOK enrollment password
   - Import the MOK certificate into firmware
   - Provide reboot instructions

3. **Reboot and enroll**:
   - During reboot, you'll see a MOK enrollment screen
   - Select "Enroll MOK"
   - Enter the password you set
   - Complete the enrollment

### 3. Runtime (After Enrollment)

Once MOK is enrolled:

1. **Modules are automatically signed**:
   - DKMS hook signs modules after building
   - Module loading service signs modules on boot
   - All modules are verified by Secure Boot

2. **Modules load automatically**:
   - `tuxedo-modules.service` loads modules on boot
   - Modules are loaded from `/usr/local/lib/modules/$(uname -r)/extra/`
   - Signed modules pass Secure Boot verification

3. **TCC works normally**:
   - TCC communicates with `tuxedo_io` module
   - Keyboard controls use `tuxedo_keyboard` module
   - All functionality works as expected

### 4. Kernel Updates

When a new kernel is installed:

1. **DKMS rebuilds modules** automatically
2. **DKMS hook signs modules** automatically (via `dkms-hook.sh`)
3. **Module loading service** copies and loads signed modules
4. **No manual intervention needed** - everything is automatic

## Components

### Scripts

- **`setup-secureboot.sh`**: MOK enrollment (run once after first boot)
- **`sign-modules.sh`**: Signs modules with MOK key
- **`load-modules.sh`**: Loads signed modules in correct order
- **`dkms-hook.sh`**: Auto-signs modules after DKMS builds

### Services

- **`tuxedo-modules.service`**: Loads modules on boot
- **`tuxedo-sign-modules.service`**: Signs modules after kernel updates
- **`sign-tuxedo-modules.service`**: Backup signing service

### MOK Certificates

- **Location**: `/usr/share/tuxedo/mok/`
- **Files**:
  - `MOK.key` - Private key (for signing)
  - `MOK.der` - Certificate in DER format (for enrollment)
  - `MOK.crt` - Certificate in PEM format (for signing)

## Verification

### Check Secure Boot Status

```bash
mokutil --sb-state
```

### Check MOK Enrollment

```bash
mokutil --list-enrolled | grep -i tuxedo
```

### Check Module Signatures

```bash
# List signed modules
find /lib/modules/$(uname -r) -name "tuxedo*.ko*" -exec modinfo {} \; | grep -E "signer|sig_key"
```

### Check Loaded Modules

```bash
lsmod | grep tuxedo
```

### Test TCC

```bash
# Launch TCC
tuxedo-control-center

# Check TCC service
systemctl status tccd.service
```

## Troubleshooting

### Modules Won't Load

**Symptom**: `insmod: ERROR: could not insert module: Required key not available`

**Solution**:
1. Verify MOK is enrolled: `mokutil --list-enrolled`
2. If not enrolled, run: `sudo setup-secureboot`
3. Reboot and complete enrollment
4. After reboot, modules should load automatically

### TCC Can't Communicate with Hardware

**Symptom**: TCC launches but can't control keyboard/fans

**Solution**:
1. Check modules are loaded: `lsmod | grep tuxedo`
2. If not loaded, check service: `systemctl status tuxedo-modules.service`
3. Manually load: `sudo /usr/local/bin/tuxedo-load-modules`
4. Check logs: `journalctl -u tuxedo-modules.service`

### Modules Not Signed After Kernel Update

**Symptom**: Modules fail to load after kernel update

**Solution**:
1. Manually sign modules: `sudo /usr/local/bin/tuxedo-sign-modules`
2. Reload modules: `sudo /usr/local/bin/tuxedo-load-modules`
3. Check DKMS hook: `ls -la /etc/dkms/post_install.d/99-sign-tuxedo-modules.sh`

### MOK Certificate Not Found

**Symptom**: `setup-secureboot` says certificate not found

**Solution**:
1. Check certificate location: `ls -la /usr/share/tuxedo/mok/`
2. If missing, rebuild image with MOK keys in GitHub Secrets
3. Or generate new certificate: `scripts/utils/generate-mok-cert.sh`

## Security Notes

1. **MOK Password**: Choose a strong password for MOK enrollment
2. **Private Key**: Never share the MOK private key
3. **Certificate Rotation**: If compromised, generate new certificate and re-enroll
4. **Secure Boot**: Keep Secure Boot enabled for security

## Summary

✅ **TCC works with Secure Boot** when:
- MOK certificate is enrolled in firmware
- Tuxedo modules are signed with MOK key
- Modules load successfully on boot
- TCC service can communicate with modules

The entire process is **automated** after initial MOK enrollment - you only need to run `setup-secureboot` once after first boot.


# Archive Directory

This directory contains old files that have been replaced by the new template-based system.

## Contents

### old-containerfiles/
Contains the 36 old Containerfiles that were replaced by the template system.
These are kept for reference but are no longer used.

### old-scripts/
Contains old scripts that have been replaced:
- `add-mok-to-kernel-trust.sh` → replaced by `scripts/utils/add-mok-to-kernel-trust.sh`
- `dkms-sign-hook.sh` → replaced by `scripts/runtime/dkms-hook.sh`
- `install-tcc-with-selinux-fix.sh` → replaced by `scripts/install/install-tcc.sh`
- `load-tuxedo-modules.sh` → replaced by `scripts/runtime/load-modules.sh`
- `setup-secureboot.sh` → replaced by `scripts/install/setup-secureboot.sh`
- `sign-modules.sh` → replaced by `scripts/runtime/sign-modules.sh`
- `build-modules.sh` → replaced by `scripts/install/install-tuxedo-drivers.sh`
- `fix-certificate-mismatch.sh` → obsolete, uses old hardcoded paths

### old-overlay/
Contains old overlay files:
- `load-tuxedo-modules.service` → replaced by `tuxedo-modules.service`
- `tuxedo-keyboard` → replaced by `tuxedo-resume.sh`

### Diagnostic Files
- `tuxedo-secureboot-diagnostics-*.txt` - Old diagnostic output files

### Documentation
- `TCC-FIX-SUMMARY.md` - Outdated documentation about TCC fixes

## Note

These files are kept for historical reference and troubleshooting.
They should not be used in new builds.


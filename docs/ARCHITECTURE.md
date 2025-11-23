# Universal Blue Tuxedo Architecture

## Overview

This repository provides a template-based build system for creating Universal Blue OCI images with Tuxedo hardware support. The system generates 36 image variants from a single template, eliminating code duplication and ensuring consistency.

## Architecture Principles

1. **Single Source of Truth**: One `Containerfile.template` generates all 36 variants
2. **Template-Based Generation**: Variants are defined in `config/variants.yaml` and generated automatically
3. **Modular Scripts**: Installation and runtime scripts are organized by function
4. **Secure Boot First**: Proper MOK enrollment and module signing throughout
5. **Free Tier Optimized**: CI/CD respects GitHub Actions free tier limits

## Directory Structure

```
ublue-tuxedo/
├── .github/workflows/     # CI/CD workflows
├── config/                # Configuration files
│   └── variants.yaml      # Variant definitions (36 variants)
├── containerfiles/
│   ├── Containerfile.template  # Single template
│   └── generated/         # Auto-generated Containerfiles (gitignored)
├── scripts/
│   ├── build/             # Build-time scripts
│   │   └── generate-containerfiles.sh
│   ├── install/           # Installation scripts
│   │   ├── install-tuxedo-drivers.sh
│   │   ├── install-tcc.sh
│   │   └── setup-secureboot.sh
│   ├── runtime/           # Runtime scripts
│   │   ├── load-modules.sh
│   │   ├── sign-modules.sh
│   │   └── dkms-hook.sh
│   └── utils/             # Utility scripts
│       ├── add-mok-to-kernel-trust.sh
│       └── check-base-images.sh
├── overlay/               # Files to overlay into images
│   ├── etc/
│   │   ├── modules-load.d/
│   │   └── systemd/system/
│   └── usr/
│       └── share/tuxedo/mok/
└── Makefile               # Build system
```

## Build Process

### 1. Template Generation

The `Containerfile.template` contains all common build steps:
- Repository setup
- Driver installation
- TCC installation
- Module building and signing
- Service configuration

### 2. Variant Configuration

`config/variants.yaml` defines all 36 variants:
- Base image (Aurora, Bluefin, Bazzite)
- Tags (stable, latest)
- Package names
- Descriptions

### 3. Containerfile Generation

`scripts/build/generate-containerfiles.sh`:
- Reads `variants.yaml`
- Generates 36 Containerfiles from template
- Replaces `ARG BASE_IMAGE` with actual base image
- Customizes labels per variant

### 4. Build Execution

Each variant builds:
1. From its base image
2. Installs Tuxedo drivers via `install-tuxedo-drivers.sh`
3. Installs TCC via `install-tcc.sh`
4. Builds and signs DKMS modules
5. Configures systemd services
6. Applies overlay files

## Component Details

### Installation Scripts

**install-tuxedo-drivers.sh**:
- Adds Tuxedo Fedora repository
- Installs kernel headers matching installed kernel
- Installs DKMS and build tools
- Installs tuxedo-drivers package
- Builds DKMS modules for current kernel

**install-tcc.sh**:
- Installs tuxedo-control-center package
- Moves to ostree-compatible location (`/usr/lib`)
- Creates proper symlinks
- Installs SELinux policies for V8 runtime
- Configures systemd services

**setup-secureboot.sh**:
- Checks Secure Boot status
- Prompts for MOK enrollment password
- Imports MOK certificate
- Provides enrollment instructions

### Runtime Scripts

**load-modules.sh**:
- Copies signed modules from DKMS to writable location
- Loads modules in correct order
- Handles kernel updates automatically

**sign-modules.sh**:
- Signs modules with MOK key
- Handles compressed modules (.ko.xz)
- Supports both kmodsign and sign-file

**dkms-hook.sh**:
- Automatically signs modules after DKMS builds
- Called by DKMS post-install hook
- Handles kernel version detection

### Systemd Services

**tuxedo-modules.service**:
- Loads modules on boot
- Runs after kernel modules are available
- Handles kernel updates

**tuxedo-sign-modules.service**:
- Signs modules after kernel updates
- Runs after DKMS completes
- One-shot service

**tuxedo-resume.sh** (system-sleep hook):
- Reloads modules on resume from suspend
- Fixes keyboard backlight issues

## Secure Boot Flow

### Build Time
1. MOK certificates embedded from GitHub Secrets
2. Modules signed during build
3. Certificates placed in `/usr/share/tuxedo/mok/`

### First Boot
1. User runs `setup-secureboot` script
2. Script prompts for MOK enrollment password
3. Script imports MOK certificate
4. User reboots and enrolls at MOK screen

### Runtime
1. DKMS builds modules for new kernel
2. DKMS hook signs modules automatically
3. Module loading service loads signed modules
4. All modules verified by Secure Boot

## CI/CD Architecture

### Workflow Structure

1. **check-base-images job**:
   - Checks if base images have changed
   - Determines which variants need building
   - Outputs variant list

2. **build job** (matrix strategy):
   - Builds variants in parallel (max 18 concurrent)
   - Respects GitHub Actions free tier (20 job limit)
   - Uses Docker Buildx with caching
   - Pushes to GHCR

### Free Tier Optimization

- **Batching**: 18 variants per batch (under 20 concurrent limit)
- **Conditional Execution**: Only builds changed variants
- **Caching**: Uses GitHub Actions cache for faster builds
- **Smart Detection**: Skips builds when base images unchanged

## Environment Variables

- `TUXEDO_MOK_DIR`: MOK certificate directory (default: `/usr/share/tuxedo/mok`)
- `BASE_IMAGE`: Base image for template (set during generation)

## Extension Points

### Adding a New Variant

1. Add variant definition to `config/variants.yaml`
2. Run `make generate` to regenerate Containerfiles
3. Build with `make build VARIANT=new-variant`

### Modifying Build Steps

1. Edit `containerfiles/Containerfile.template`
2. Run `make generate` to regenerate all variants
3. Test with `make build VARIANT=aurora`

### Adding New Scripts

1. Place in appropriate directory (`scripts/install/`, `scripts/runtime/`, etc.)
2. Reference in `Containerfile.template`
3. Ensure executable permissions

## Maintenance

### Updating All Variants

1. Edit `Containerfile.template`
2. Run `make generate`
3. Test with `make build VARIANT=aurora`
4. Commit changes

### Updating Base Images

1. Update base image tags in `config/variants.yaml`
2. Run `make generate`
3. CI/CD will detect changes and rebuild

## Testing

- **Local**: `make build VARIANT=aurora`
- **All Variants**: `make build-all` (takes time)
- **Validation**: `make validate`
- **CI**: Automated on push/PR


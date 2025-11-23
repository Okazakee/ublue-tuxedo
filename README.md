# Universal Blue Tuxedo

Universal Blue OCI images with official Tuxedo drivers and TCC (Tuxedo Control Center) for Tuxedo laptops.

Supports **Aurora** (KDE Plasma), **Bluefin** (GNOME), and **Bazzite** (Gaming/Desktop/Deck) with stable/latest kernel variants, NVIDIA support, and open-source NVIDIA drivers. **36 total variants available** - the most comprehensive Universal Blue Tuxedo collection!

## Quick Start

### Quick Installation

Choose your preferred desktop environment:

```bash
# Aurora Stable (KDE Plasma)
sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/okazakee/aurora-tuxedo:stable

# Bluefin Stable (GNOME)  
sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/okazakee/bluefin-tuxedo:stable

# Bazzite Gaming Stable
sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/okazakee/bazzite-tuxedo:stable

# Reboot to apply
sudo systemctl reboot
```

### Additional Variants

📖 **See [Available Images](#available-images) below** for all 36 variants including:
- **NVIDIA versions** (proprietary/open drivers)
- **DX versions** (with development tools)  
- **Latest builds** (newest kernel)
- **Specialized builds** (Deck, GNOME variants)

💡 **Pro tip:** Replace `:stable` with `:latest` for newest kernel features

## Available Images

🖥️ **Aurora (KDE Plasma)** - 8 variants:
- `aurora-tuxedo:stable/latest` - Base Aurora with gated/newest kernel
- `aurora-tuxedo-dx:stable/latest` - Dev tools + Aurora  
- `aurora-nvidia-tuxedo:stable/latest` - NVIDIA drivers + Aurora
- `aurora-dx-nvidia-tuxedo:stable/latest` - Dev tools + NVIDIA + Aurora

🐧 **Bluefin (GNOME)** - 8 variants:
- `bluefin-tuxedo:stable/latest` - Base Bluefin with gated/newest kernel
- `bluefin-tuxedo-dx:stable/latest` - Dev tools + Bluefin
- `bluefin-nvidia-tuxedo:stable/latest` - NVIDIA drivers + Bluefin  
- `bluefin-dx-nvidia-tuxedo:stable/latest` - Dev tools + NVIDIA + Bluefin

🎮 **Bazzite Regular** - 8 variants:
- `bazzite-tuxedo:stable/latest` - Gaming KDE Plasma
- `bazzite-deck-tuxedo:stable/latest` - Steam Deck UI
- `bazzite-gnome-tuxedo:stable/latest` - GNOME Desktop
- `bazzite-deck-gnome-tuxedo:stable/latest` - Deck + GNOME

🎯 **Bazzite NVIDIA** - 12 variants:
- `bazzite-nvidia-tuxedo:stable/latest` - Gaming + NVIDIA
- `bazzite-nvidia-open-tuxedo:stable/latest` - Gaming + Open NVIDIA
- `bazzite-deck-nvidia-tuxedo:stable/latest` - Deck + NVIDIA
- `bazzite-gnome-nvidia-tuxedo:stable/latest` - GNOME + NVIDIA
- `bazzite-gnome-nvidia-open-tuxedo:stable/latest` - GNOME + Open NVIDIA
- `bazzite-deck-nvidia-gnome-tuxedo:stable/latest` - Deck + GNOME + NVIDIA

## Quick Reference URLs

Replace `[variant]:stable` with `[variant]:latest` for newest kernel:

**Aurora Family:**
- Base: `ghcr.io/okazakee/aurora-tuxedo:stable`
- DX: `ghcr.io/okazakee/aurora-tuxedo-dx:stable`  
- NVIDIA: `ghcr.io/okazakee/aurora-nvidia-tuxedo:stable`
- DX NVIDIA: `ghcr.io/okazakee/aurora-dx-nvidia-tuxedo:stable`

**Bluefin Family:**
- Base: `ghcr.io/okazakee/bluefin-tuxedo:stable`
- DX: `ghcr.io/okazakee/bluefin-tuxedo-dx:stable`
- NVIDIA: `ghcr.io/okazakee/bluefin-nvidia-tuxedo:stable`
- DX NVIDIA: `ghcr.io/okazakee/bluefin-dx-nvidia-tuxedo:stable`

**Bazzite Regular Family:**
- Gaming: `ghcr.io/okazakee/bazzite-tuxedo:stable`
- Deck: `ghcr.io/okazakee/bazzite-deck-tuxedo:stable`
- GNOME: `ghcr.io/okazakee/bazzite-gnome-tuxedo:stable`
- Deck GNOME: `ghcr.io/okazakee/bazzite-deck-gnome-tuxedo:stable`

**Bazzite NVIDIA Family:**
- NVIDIA Gaming: `ghcr.io/okazakee/bazzite-nvidia-tuxedo:stable`
- NVIDIA Open Gaming: `ghcr.io/okazakee/bazzite-nvidia-open-tuxedo:stable`
- NVIDIA Deck: `ghcr.io/okazakee/bazzite-deck-nvidia-tuxedo:stable`
- NVIDIA GNOME: `ghcr.io/okazakee/bazzite-gnome-nvidia-tuxedo:stable`
- NVIDIA Open GNOME: `ghcr.io/okazakee/bazzite-gnome-nvidia-open-tuxedo:stable`
- NVIDIA Deck GNOME: `ghcr.io/okazakee/bazzite-deck-nvidia-gnome-tuxedo:stable`

## Features

- **Fedora 43 Ready**: Optimized for latest Fedora with proper repository support
- **Official Tuxedo Support**: Uses the official Tuxedo Fedora repository
- **Pre-built Kernel Modules**: DKMS modules built and installed during image creation
- **Enhanced TCC Installation**: SELinux-compatible Tuxedo Control Center with V8 memory policy fixes
- **Secure Boot Support**: Complete MOK enrollment workflow with automatic module signing
- **InfinityBook Optimizations**: Proven fixes for Gen9/10 models
- **Template-Based Architecture**: Single template generates all 36 variants (zero code duplication)
- **Smart CI/CD**: Checks base images and only builds when updates are available (free tier optimized)
- **Automatic Module Management**: DKMS hooks and systemd services handle kernel updates automatically

### Add Recommended Kernel Arguments

For InfinityBook Gen9/10 models, add the recommended kernel argument:

```bash
sudo rpm-ostree kargs --append-if-missing acpi.ec_no_wakeup=1
```

**Note**: This addresses EC wake issues as recommended by Tuxedo.

## Secure Boot Setup

The `setup-secureboot` script handles Secure Boot setup with secure password-based MOK enrollment:

```bash
sudo setup-secureboot
```

The script will:

1. Check if Secure Boot is enabled
2. Prompt for a MOK enrollment password (secure, no hardcoded passwords)
3. Import the MOK certificate into firmware
4. Provide reboot instructions

**After reboot:**
- You'll see a MOK enrollment screen
- Select "Enroll MOK" and enter your password
- Complete the enrollment

MOK certificates are embedded in all images (from GitHub Secrets) for secure module signing.

### Automatic Kernel Update Handling

**No manual intervention needed after kernel updates!** The system automatically handles module rebuilding and signing:

1. **DKMS Hook**: Automatically rebuilds and signs Tuxedo modules when a new kernel is installed
2. **Module Loading Service**: Automatically copies signed modules from DKMS to a writable location and loads them
3. **Kernel Install Trigger**: The `tuxedo-modules.service` runs after kernel installation to ensure modules are ready

**What happens automatically:**
- After a kernel update, DKMS rebuilds modules for the new kernel
- Modules are automatically signed with your MOK certificate (via DKMS hook)
- Modules are copied to `/usr/local/lib/modules/$(uname -r)/extra/` (writable location)
- Modules are automatically loaded on next boot

**You only need to reboot** - everything else is handled automatically!

📖 **For detailed Secure Boot documentation, see [docs/SECUREBOOT.md](docs/SECUREBOOT.md)**

## Verification

After rebasing, verify the installation:

```bash
# Check if Tuxedo modules are loaded
lsmod | grep tuxedo

# Expected output:
# tuxedo_keyboard
# tuxedo_io

# Launch Tuxedo Control Center
tuxedo-control-center

# Check TCC service status (should be running)
systemctl status tccd.service

# Check module loading service
systemctl status tuxedo-modules.service
```

## Troubleshooting

<details>
<summary><h3 style="display: inline;">🔧 Modules Not Loading</h3></summary>

1. Check if modules are present:

   ```bash
   ls -la /usr/local/lib/modules/$(uname -r)/extra/ | grep tuxedo
   ```

2. Manually load modules:

   ```bash
   sudo /usr/local/bin/tuxedo-load-modules
   ```

3. Check system logs:
   ```bash
   journalctl -b -u tuxedo-modules.service
   dmesg | grep tuxedo
   ```

</details>

<details>
<summary><h3 style="display: inline;">🔒 Secure Boot Issues</h3></summary>

1. Check Secure Boot status:

   ```bash
   mokutil --sb-state
   ```

2. If modules fail to load with Secure Boot enabled:

   ```bash
   sudo setup-secureboot
   ```

3. Verify MOK enrollment:
   ```bash
   mokutil --list-enrolled | grep -i tuxedo
   ```

4. Manually sign modules if needed:
   ```bash
   sudo /usr/local/bin/tuxedo-sign-modules
   ```

📖 **For complete Secure Boot troubleshooting, see [docs/SECUREBOOT.md](docs/SECUREBOOT.md)**

</details>

<details>
<summary><h3 style="display: inline;">😴 Suspend/Resume Issues</h3></summary>

The image includes a systemd-sleep hook that reinitializes Tuxedo modules on resume. If you experience issues:

1. Check if the hook is present:

   ```bash
   ls -la /usr/lib/systemd/system-sleep/tuxedo-resume.sh
   ```

2. Test manual module reload:
   ```bash
   sudo /usr/local/bin/tuxedo-load-modules
   ```

</details>

<details>
<summary><h3 style="display: inline;">🖥️ TCC Service Issues</h3></summary>

The TCC daemon (`tccd.service`) includes SELinux fixes for V8 JavaScript runtime compatibility. If the service fails:

1. Check service status:

   ```bash
   systemctl status tccd.service --lines=10
   ```

2. If service shows "Failed with result 'core-dump'" or "signal=ILL":

   ```bash
   # This image includes enhanced SELinux policies to prevent this
   # The service may need a restart after initial boot
   sudo systemctl restart tccd.service
   ```

3. Check SELinux context (if supported):

   ```bash
   ls -Z /opt/tuxedo-control-center/resources/dist/tuxedo-control-center/data/service/tccd
   ```

**Note**: This image includes targeted SELinux policies that resolve the V8 memory permission issues causing TCC crashes.

</details>

<details>
<summary><h3 style="display: inline;">⏮️ Rollback</h3></summary>

If you encounter issues, you can rollback to your previous image:

```bash
sudo rpm-ostree rollback
```

</details>

## Building from Source

### Prerequisites

- Docker or Podman
- Make
- yq (for YAML parsing) - `dnf install yq` or `pip install yq`
- Git

### Quick Build

1. Clone the repository:

   ```bash
   git clone https://github.com/okazakee/ublue-tuxedo.git
   cd ublue-tuxedo
   ```

2. Generate Containerfiles from template:

   ```bash
   make generate
   ```

3. Build a specific variant:

   ```bash
   # Build Aurora stable
   make build VARIANT=aurora

   # Build Aurora DX stable
   make build VARIANT=aurora-dx-stable

   # Build any variant (see config/variants.yaml for all names)
   make build VARIANT=bazzite-nvidia
   ```

4. Build all variants (takes time):

   ```bash
   make build-all
   ```

### Build System

The repository uses a **template-based build system**:

- **Single Template**: `containerfiles/Containerfile.template` generates all 36 variants
- **Variant Configuration**: `config/variants.yaml` defines all variants
- **Automatic Generation**: `make generate` creates all Containerfiles
- **Zero Duplication**: One template, 36 generated files

### Available Make Targets

```bash
make generate    # Generate all Containerfiles from template
make build VARIANT=aurora  # Build specific variant
make build-all   # Build all 36 variants (takes time)
make validate    # Validate configuration and generated files
make test        # Run validation tests
make clean       # Clean generated Containerfiles
```

📖 **For detailed build documentation, see [docs/BUILDING.md](docs/BUILDING.md) (if exists) or [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)**

## Architecture

This repository uses a **modern template-based architecture**:

- **Single Source of Truth**: One `Containerfile.template` generates all 36 variants
- **Modular Scripts**: Organized by function (install, runtime, utils)
- **Automatic CI/CD**: GitHub Actions builds only changed variants
- **Free Tier Optimized**: Respects GitHub Actions limits (max 18 concurrent jobs)

### Key Components

- **Template System**: `containerfiles/Containerfile.template` + `config/variants.yaml`
- **Installation Scripts**: Driver installation, TCC setup, Secure Boot configuration
- **Runtime Scripts**: Module loading, signing, DKMS hooks
- **Systemd Services**: Automatic module management on boot and kernel updates
- **Overlay Files**: System configuration, services, SELinux policies

📖 **For complete architecture documentation, see [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)**

## CI/CD

The repository includes GitHub Actions workflows that:

- **Smart Building**: Checks base image digests and only builds changed variants
- **Free Tier Optimized**: Batches builds (max 18 concurrent) to respect limits
- **Automatic Publishing**: Builds and pushes images to GHCR
- **MOK Key Integration**: Embeds MOK certificates from GitHub Secrets for module signing

### Required GitHub Secrets

For Secure Boot module signing, add these secrets:

- `MOK_PRIVATE_KEY` - MOK private key (PEM format)
- `MOK_CERTIFICATE_PEM` - MOK certificate (PEM format)
- `MOK_CERTIFICATE_DER` - MOK certificate (DER format, base64 encoded)

📖 **For CI/CD details, see [docs/GITHUB_ACTIONS.md](docs/GITHUB_ACTIONS.md)**

## Contributing

We welcome contributions! The repository uses a template-based system for easy maintenance.

1. Fork the repository
2. Create a feature branch
3. Make your changes (edit the template, not generated files)
4. Test with `make build VARIANT=aurora`
5. Submit a pull request

📖 **For contribution guidelines, see [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md)**

## Documentation

- **[ARCHITECTURE.md](docs/ARCHITECTURE.md)** - Complete system architecture
- **[CONTRIBUTING.md](docs/CONTRIBUTING.md)** - How to contribute
- **[SECUREBOOT.md](docs/SECUREBOOT.md)** - Secure Boot setup and troubleshooting
- **[GITHUB_ACTIONS.md](docs/GITHUB_ACTIONS.md)** - CI/CD workflow details
- **[VARIANTS.md](docs/VARIANTS.md)** - Complete variant listing

## License

This project follows the same license as the Universal Blue base images.

## Support

- **Tuxedo Support**: [Tuxedo Computers Support](https://www.tuxedocomputers.com/en/Support.1.html)
- **Universal Blue**: [Universal Blue Documentation](https://universal-blue.org/)
- **Aurora**: [Aurora Documentation](https://aurora.blue/)
- **Issues**: [GitHub Issues](https://github.com/okazakee/ublue-tuxedo/issues)

## Acknowledgments

- [Universal Blue](https://universal-blue.org/) for the base images (Aurora, Bluefin, Bazzite)
- [Tuxedo Computers](https://www.tuxedocomputers.com/) for official drivers
- [BrickMan240](https://github.com/BrickMan240) for the original PR and improvements

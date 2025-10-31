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

- **Official Tuxedo Support**: Uses the official Tuxedo Fedora repository
- **Pre-built Kernel Modules**: DKMS modules built and installed during image creation
- **Enhanced TCC Installation**: SELinux-compatible Tuxedo Control Center with V8 memory policy fixes
- **Secure Boot Support**: Direct MOK enrollment with secure key management
- **InfinityBook Optimizations**: Proven fixes for Gen9/10 models
- **Smart CI**: Checks all base images (Aurora, Bluefin, Bazzite) and only builds when updates are available
- **Multi-Variant Support**: Aurora, Bluefin, and Bazzite with stable/latest variants

### Add Recommended Kernel Arguments

For InfinityBook Gen9/10 models, add the recommended kernel argument:

```bash
sudo rpm-ostree kargs --append-if-missing acpi.ec_no_wakeup=1
```

**Note**: This addresses EC wake issues as recommended by Tuxedo.

## Secure Boot Setup

The `setup-secureboot` script automatically handles Secure Boot setup with two fallback paths:

```bash
sudo /usr/bin/setup-secureboot
```

The script will:

1. **First**: Attempt to use Aurora keys (if available and trusted)
2. **Simplified Approach**: Direct MOK enrollment only

MOK certificates are embedded in all images for secure module signing.

### Automatic Kernel Update Handling

**No manual intervention needed after kernel updates!** The system automatically handles module rebuilding and signing:

1. **DKMS Hook**: Automatically rebuilds and signs Tuxedo modules when a new kernel is installed
2. **Module Loading Service**: Automatically copies signed modules from DKMS to a writable location and loads them
3. **Kernel Install Trigger**: The `load-tuxedo-modules.service` runs after `kernel-install.service` to ensure modules are ready for the new kernel

**What happens automatically:**
- After a kernel update, DKMS rebuilds modules for the new kernel
- Modules are automatically signed with your MOK certificate
- Modules are copied to `/usr/local/lib/modules/$(uname -r)/extra/` (writable location)
- Modules are automatically loaded on next boot

**You only need to reboot** - everything else is handled automatically!

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
```

## Troubleshooting

<details>
<summary><h3 style="display: inline;">🔧 Modules Not Loading</h3></summary>

1. Check if modules are present:

   ```bash
   ls -la /lib/modules/$(uname -r)/updates/ | grep tuxedo
   ```

2. Manually load modules:

   ```bash
   sudo modprobe tuxedo_keyboard
   sudo modprobe tuxedo_io
   ```

3. Check system logs:
   ```bash
   journalctl -b -u tuxedo-control-center
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
   sudo /usr/bin/setup-secureboot
   ```

3. Verify MOK enrollment:
   ```bash
   mokutil --list-enrolled
   ```

</details>

<details>
<summary><h3 style="display: inline;">😴 Suspend/Resume Issues</h3></summary>

The image includes a systemd-sleep hook that reinitializes Tuxedo modules on resume. If you experience issues:

1. Check if the hook is present:

   ```bash
   ls -la /usr/lib/systemd/system-sleep/tuxedo-keyboard
   ```

2. Test manual module reload:
   ```bash
   sudo modprobe -r tuxedo_keyboard tuxedo_io
   sudo modprobe tuxedo_keyboard tuxedo_io
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

4. Manual service start for testing:

   ```bash
   sudo /opt/tuxedo-control-center/resources/dist/tuxedo-control-center/data/service/tccd --start
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

<details>
<summary><h3 style="display: inline;">🔨 Build Instructions</h3></summary>

### Prerequisites

- Docker or Podman
- Git

### Build Steps

1. Clone the repository:

   ```bash
   git clone https://github.com/okazakee/aurora-tuxedo.git
   cd aurora-tuxedo
   ```

2. Build a specific variant:

   ```bash
   # Build Aurora stable
   docker build -f containerfiles/Containerfile.aurora -t aurora-tuxedo:stable .

   # Or build any other variant
   docker build -f containerfiles/Containerfile.bazzite-nvidia -t bazzite-nvidia-tuxedo:stable .
   ```

3. Test the image:
   ```bash
   docker run --rm aurora-tuxedo:stable bash -c "rpm -qa | grep tuxedo"
   ```

</details>

### Build Process Improvements (PR Pattern)

The build process now includes the proven patterns from [BrickMan240's PR #6](https://github.com/BrickMan240/ublue-tuxedo-tcc/pull/6):

- **Writable Build Location**: Copies DKMS sources to `/tmp/tuxedo-drivers-build` to avoid immutable filesystem issues
- **Explicit Module Installation**: Uses `make modules_install` to ensure modules are properly placed
- **Secure Key Management**: MOK keys stored securely in GitHub Secrets and embedded during build
- **Automated Setup**: One-time MOK enrollment with persistent module signing across updates

## CI/CD

The repository includes GitHub Actions workflows that:

- Check if Aurora base image has changed
- Build and push the image to GHCR
- Test the built image
- Update the Aurora digest file

### Required Secrets

- `GHCR_PAT`: Personal Access Token with `write:packages` permission

## Architecture

### Containerfile Structure

Each variant uses a different base image:

1. **Stable**: `ghcr.io/ublue-os/aurora:stable` - Weekly updates with gated kernel
2. **Latest**: `ghcr.io/ublue-os/aurora:latest` - Newest features with latest kernel
3. **DX**: `ghcr.io/ublue-os/aurora-dx:latest` - Developer Experience with pre-installed tools

Common build process for all variants:

1. **Repository Setup**: Official Tuxedo Fedora repository
2. **Package Installation**: TCC, drivers, DKMS, build dependencies
3. **Enhanced TCC Installation**: SELinux-compatible installation with V8 memory policies
4. **Module Building**: DKMS autoinstall with proper module placement
5. **System Integration**: modules-load.d and systemd-sleep hooks
6. **Overlay Files**: Additional configuration files

### Key Components

- **Tuxedo Control Center**: GUI for fan control, brightness, keyboard backlight
- **Enhanced TCC Installation**: Script with comprehensive SELinux policies for V8 JavaScript runtime
- **Tuxedo Drivers**: Kernel modules for hardware control
- **DKMS**: Dynamic Kernel Module Support for automatic rebuilding
- **Secure Boot**: Module signing with MOK enrollment (simplified)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test on real hardware if possible
5. Submit a pull request

## License

This project follows the same license as the Aurora base image.

## Support

- **Tuxedo Support**: [Tuxedo Computers Support](https://www.tuxedocomputers.com/en/Support.1.html)
- **Aurora Support**: [Aurora Documentation](https://aurora.blue/)
- **Issues**: [GitHub Issues](https://github.com/okazakee/aurora-tuxedo/issues)

## Acknowledgments

- [Universal Blue](https://universal-blue.org/) for the base images (Aurora, Bluefin, Bazzite)
- [Tuxedo Computers](https://www.tuxedocomputers.com/) for official drivers
- [BrickMan240](https://github.com/BrickMan240) for the original PR and improvements
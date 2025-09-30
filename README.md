# Aurora Tuxedo

Aurora-based OCI images with official Tuxedo drivers and TCC (Tuxedo Control Center) for InfinityBook laptops.

## Available Variants

- **Stable**: `ghcr.io/okazakee/aurora-tuxedo:stable` - Weekly updates with gated kernel
- **Latest**: `ghcr.io/okazakee/aurora-tuxedo:latest` - Newest features with latest kernel
- **DX**: `ghcr.io/okazakee/aurora-tuxedo:dx` - Developer Experience with pre-installed dev tools

## Features

- **Official Tuxedo Support**: Uses the official Tuxedo Fedora repository
- **Pre-built Kernel Modules**: DKMS modules built and installed during image creation
- **Secure Boot Support**: Aurora key path with MOK enrollment fallback
- **InfinityBook Optimizations**: Proven fixes for Gen9/10 models
- **Smart CI**: Skips builds when Aurora base hasn't changed, only publishes after tests pass
- **Multi-Variant Support**: Stable, Latest, and DX variants available

## Quick Start

### Rebase to Aurora Tuxedo

Choose your preferred variant:

**Stable (Recommended for most users):**

```bash
sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/okazakee/aurora-tuxedo:stable
sudo systemctl reboot
```

**Latest (For cutting-edge features):**

```bash
sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/okazakee/aurora-tuxedo:latest
sudo systemctl reboot
```

**DX (For developers):**

```bash
sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/okazakee/aurora-tuxedo:dx
sudo systemctl reboot
```

### Add Recommended Kernel Arguments

For InfinityBook Gen9/10 models, add the recommended kernel argument:

```bash
sudo rpm-ostree kargs --append-if-missing acpi.ec_no_wakeup=1
```

**Note**: This addresses EC wake issues as recommended by Tuxedo.

## Secure Boot Setup

The image supports two Secure Boot paths:

### 1. Aurora Key Path (Preferred)

If you're using the Aurora base image, modules may be signed with Aurora's keys:

```bash
sudo /usr/bin/setup-secureboot
```

The script will detect if Aurora keys are available and trusted.

### 2. MOK Enrollment (Fallback)

If Aurora keys aren't available, use MOK enrollment:

```bash
sudo /usr/bin/setup-secureboot
```

The script will automatically import the MOK certificate with the hardcoded password "tuxedo". During reboot, select "Enroll MOK" and enter the password: **tuxedo**.

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
```

## Troubleshooting

### Modules Not Loading

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

### Secure Boot Issues

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

### Suspend/Resume Issues

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

### Rollback

If you encounter issues, you can rollback to your previous image:

```bash
sudo rpm-ostree rollback
```

## Building from Source

### Prerequisites

- Docker or Podman
- Git

### Build Steps

1. Clone the repository:

   ```bash
   git clone https://github.com/okazakee/aurora-tuxedo.git
   cd aurora-tuxedo
   ```

2. Build the image:

   ```bash
   docker build -t aurora-tuxedo:latest .
   ```

3. Test the image:
   ```bash
   docker run --rm aurora-tuxedo:latest bash -c "rpm -qa | grep tuxedo"
   ```

### Build Process Improvements (PR Pattern)

The build process now includes the proven patterns from [BrickMan240's PR #6](https://github.com/BrickMan240/ublue-tuxedo-tcc/pull/6):

- **Writable Build Location**: Copies DKMS sources to `/tmp/tuxedo-drivers-build` to avoid immutable filesystem issues
- **Explicit Module Installation**: Uses `make modules_install` to ensure modules are properly placed
- **MOK Signing**: Generates MOK keys during build for Secure Boot compatibility
- **Hardcoded Password**: Uses "tuxedo" as the MOK enrollment password for seamless setup

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
3. **Module Building**: DKMS autoinstall with proper module placement
4. **System Integration**: modules-load.d and systemd-sleep hooks
5. **Overlay Files**: Additional configuration files

### Key Components

- **Tuxedo Control Center**: GUI for fan control, brightness, keyboard backlight
- **Tuxedo Drivers**: Kernel modules for hardware control
- **DKMS**: Dynamic Kernel Module Support for automatic rebuilding
- **Secure Boot**: Module signing with Aurora keys or MOK enrollment

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

- [Aurora Project](https://aurora.blue/) for the base image
- [Tuxedo Computers](https://www.tuxedocomputers.com/) for official drivers
- [BrickMan240](https://github.com/BrickMan240) for the original PR and improvements
- [Linux-Tech&More](https://www.linux-tech-and-more.com/) for Tuxedo repository information

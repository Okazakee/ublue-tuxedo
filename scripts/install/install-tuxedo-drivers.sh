#!/bin/bash
# Install Tuxedo drivers with DKMS support for Fedora 43
# This script handles driver installation, kernel headers, and DKMS module building

set -euo pipefail

echo "=== Installing Tuxedo Drivers ==="

# Get Fedora version
FEDORA_VER=$(rpm -E '%{fedora}')

# Add Tuxedo repository
echo "Adding Tuxedo repository for Fedora ${FEDORA_VER}..."
cat > /etc/yum.repos.d/tuxedo.repo <<EOF
[tuxedo]
name=TUXEDO
baseurl=https://rpm.tuxedocomputers.com/fedora/${FEDORA_VER}/x86_64/base
enabled=1
gpgcheck=1
gpgkey=https://rpm.tuxedocomputers.com/fedora/${FEDORA_VER}/0x54840598.pub.asc
EOF

# Import GPG key
curl -fsSL "https://rpm.tuxedocomputers.com/fedora/${FEDORA_VER}/0x54840598.pub.asc" \
    -o /etc/pki/rpm-gpg/0x54840598.pub.asc
rpm --import /etc/pki/rpm-gpg/0x54840598.pub.asc

# Upgrade system
echo "Upgrading system packages..."
dnf -y upgrade --setopt=install_weak_deps=False

# Get kernel version
KVER=$(rpm -q kernel --qf '%{VERSION}-%{RELEASE}.%{ARCH}\n' | tail -1)
echo "Detected kernel version: ${KVER}"

# Install kernel headers and development tools
echo "Installing kernel headers and build tools..."
dnf -y install "kernel-devel-${KVER}" || dnf -y install kernel-devel
dnf -y install kernel-headers 2>/dev/null || true
dnf -y install dkms gcc make

# Install tuxedo-drivers (skip post-install scripts, we'll handle DKMS manually)
echo "Installing tuxedo-drivers package..."
dnf -y install tuxedo-drivers --setopt=tsflags=noscripts

# Build DKMS modules for the installed kernel
echo "Building DKMS modules for kernel ${KVER}..."
if [ -d "/usr/src/tuxedo-drivers" ] && [ -d "/usr/src/kernels/${KVER}" ]; then
    # Add tuxedo-drivers to DKMS
    dkms add tuxedo-drivers/4.17.0 -k "${KVER}" || true
    
    # Build modules
    echo "Building DKMS modules..."
    dkms autoinstall -k "${KVER}" || true
    
    # Update module dependencies
    depmod -a "${KVER}" || true
    
    echo "DKMS modules built successfully"
else
    echo "Warning: DKMS sources or kernel headers not found"
    echo "  /usr/src/tuxedo-drivers exists: $([ -d /usr/src/tuxedo-drivers ] && echo yes || echo no)"
    echo "  /usr/src/kernels/${KVER} exists: $([ -d /usr/src/kernels/${KVER} ] && echo yes || echo no)"
fi

# Verify installation
echo "Verifying tuxedo-drivers installation..."
rpm -q tuxedo-drivers || echo "Warning: tuxedo-drivers package not found"

# Check for built modules
if find /lib/modules -name "tuxedo*.ko*" 2>/dev/null | head -1 | grep -q .; then
    echo "Tuxedo modules found in /lib/modules"
else
    echo "Warning: No tuxedo modules found in /lib/modules"
fi

# Clean up
dnf -y clean all

echo "=== Tuxedo Drivers Installation Complete ==="


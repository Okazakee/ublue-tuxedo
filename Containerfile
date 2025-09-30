# syntax=docker/dockerfile:1.4
FROM ghcr.io/ublue-os/aurora:stable
ENV LANG=C.UTF-8
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Add TUXEDO official repo and setup GPG key
RUN FEDORA_VER=$(rpm -E '%{fedora}') && \
    printf '[tuxedo]\nname=TUXEDO\nbaseurl=https://rpm.tuxedocomputers.com/fedora/%s/x86_64/base\nenabled=1\ngpgcheck=1\ngpgkey=https://rpm.tuxedocomputers.com/fedora/%s/0x54840598.pub.asc\n' \
    "${FEDORA_VER}" "${FEDORA_VER}" > /etc/yum.repos.d/tuxedo.repo && \
    curl -fsSL "https://rpm.tuxedocomputers.com/fedora/${FEDORA_VER}/0x54840598.pub.asc" -o /etc/pki/rpm-gpg/0x54840598.pub.asc && \
    rpm --import /etc/pki/rpm-gpg/0x54840598.pub.asc

# Install vendor packages + build deps
RUN dnf -y upgrade --setopt=install_weak_deps=False && \
    dnf -y install tuxedo-control-center tuxedo-drivers dkms gcc make perl kernel-devel python3-pip || true && \
    dnf -y clean all

# DKMS / prebuild modules (PR: ensure building in writable tmp)
RUN set -eux; \
    # Get the kernel version from installed kernel package
    KVER=$(rpm -q kernel --qf '%{VERSION}-%{RELEASE}.%{ARCH}\n' | tail -1); \
    echo "Building modules for kernel: ${KVER}"; \
    # Ensure kernel headers are available
    if [ ! -d "/lib/modules/${KVER}/build" ]; then \
      echo "Kernel headers not found for ${KVER}"; \
      ls -la /lib/modules/ || true; \
      exit 1; \
    fi; \
    # Create writable build location
    mkdir -p /tmp/tuxedo-drivers-build; \
    # Copy DKMS sources to writable location if they exist
    if [ -d "/usr/src/tuxedo-drivers" ]; then \
      cp -r /usr/src/tuxedo-drivers /tmp/tuxedo-drivers-build/; \
      cd /tmp/tuxedo-drivers-build/tuxedo-drivers; \
      # Build modules for the correct kernel
      make KDIR=/lib/modules/${KVER}/build; \
      # Install modules to the correct kernel version
      make KDIR=/lib/modules/${KVER}/build INSTALL_MOD_PATH=/ INSTALL_MOD_DIR=updates modules_install; \
      # Update module dependencies
      depmod -a ${KVER}; \
      # Verify modules were installed
      ls -la /lib/modules/${KVER}/updates/ || echo "Warning: updates directory not found"; \
    else \
      echo "DKMS sources not found in /usr/src/tuxedo-drivers"; \
      exit 1; \
    fi

# Ensure modules auto-load on boot
RUN mkdir -p /etc/modules-load.d && echo 'tuxedo_keyboard' > /etc/modules-load.d/tuxedo.conf

# Copy overlay files
COPY overlay/ /

# Copy setup script
COPY scripts/setup-secureboot.sh /usr/bin/setup-secureboot
RUN chmod +x /usr/bin/setup-secureboot

# Resume hook to re-init keyboard on resume (fixes backlight reinit)
# File is already copied from overlay with correct permissions

# Cleanup
RUN rm -rf /var/cache/dnf/* /var/tmp/*

LABEL org.opencontainers.image.title="aurora-tuxedo"
LABEL org.opencontainers.image.description="Aurora with Tuxedo drivers and TCC for InfinityBook laptops"
LABEL org.opencontainers.image.vendor="Aurora Tuxedo"

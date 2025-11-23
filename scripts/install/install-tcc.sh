#!/bin/bash
# Install Tuxedo Control Center with SELinux support for V8 runtime
# This script handles TCC installation, ostree compatibility, and SELinux policies

set -euo pipefail

echo "=== Installing Tuxedo Control Center ==="

# Install TCC package
echo "Installing tuxedo-control-center package..."
dnf -y install tuxedo-control-center
dnf -y clean all

# Verify TCC was installed and find its location
echo "Locating TCC installation..."
TCC_LOCATION=""

# Check common installation locations
if [ -d /opt/tuxedo-control-center ] && [ "$(ls -A /opt/tuxedo-control-center 2>/dev/null)" ]; then
    TCC_LOCATION="/opt/tuxedo-control-center"
    echo "Found TCC in /opt/tuxedo-control-center"
elif [ -d /usr/lib/tuxedo-control-center ] && [ "$(ls -A /usr/lib/tuxedo-control-center 2>/dev/null)" ]; then
    TCC_LOCATION="/usr/lib/tuxedo-control-center"
    echo "Found TCC in /usr/lib/tuxedo-control-center"
else
    echo "TCC not found in standard locations, checking package contents..."
    TCC_FILES=$(rpm -ql tuxedo-control-center 2>/dev/null | grep -E "(tuxedo-control-center|tccd)" | head -5 || true)
    if [ -n "$TCC_FILES" ]; then
        echo "Package files found:"
        echo "$TCC_FILES"
        # Try to find the actual directory
        TCC_DIR=$(echo "$TCC_FILES" | grep -o '/[^ ]*/tuxedo-control-center[^ ]*' | head -1 | xargs dirname 2>/dev/null || true)
        if [ -n "$TCC_DIR" ] && [ -d "$TCC_DIR" ]; then
            TCC_LOCATION="$TCC_DIR"
            echo "Found TCC in: $TCC_LOCATION"
        fi
    fi
fi

if [ -z "$TCC_LOCATION" ] || [ ! -d "$TCC_LOCATION" ]; then
    echo "ERROR: TCC installation not found"
    echo "Package status:"
    rpm -q tuxedo-control-center || echo "Package not installed"
    exit 1
fi

# Move TCC to ostree-compatible location (if not already there)
if [ "$TCC_LOCATION" != "/usr/lib/tuxedo-control-center" ]; then
    echo "Moving TCC from $TCC_LOCATION to ostree-compatible location..."
    if [ -L /opt ]; then
        rm /opt
        mkdir -p /opt
    elif [ ! -d /opt ]; then
        mkdir -p /opt
    fi

    mkdir -p /usr/lib/tuxedo-control-center
    if [ -d "$TCC_LOCATION" ] && [ "$(ls -A "$TCC_LOCATION" 2>/dev/null)" ]; then
        cp -a "$TCC_LOCATION"/. /usr/lib/tuxedo-control-center/ 2>/dev/null || {
            echo "Warning: Some files may not have copied, continuing..."
        }
    fi
    rpm -q tuxedo-control-center --qf '%{VERSION}-%{RELEASE}\n' > /usr/lib/tuxedo-control-center/.build-version 2>/dev/null || true
    
    # Only remove if it was in /opt
    if [ "$TCC_LOCATION" = "/opt/tuxedo-control-center" ]; then
        rm -rf /opt/tuxedo-control-center
    fi
    
    mkdir -p /var/opt
    ln -sfn /usr/lib/tuxedo-control-center /opt/tuxedo-control-center
    ln -sfn /usr/lib/tuxedo-control-center /var/opt/tuxedo-control-center
    echo "TCC moved to /usr/lib/tuxedo-control-center with symlinks"
else
    echo "TCC already in /usr/lib/tuxedo-control-center, creating symlinks..."
    mkdir -p /var/opt
    ln -sfn /usr/lib/tuxedo-control-center /opt/tuxedo-control-center 2>/dev/null || true
    ln -sfn /usr/lib/tuxedo-control-center /var/opt/tuxedo-control-center 2>/dev/null || true
fi

# Update desktop file
if [ -f /usr/share/applications/tuxedo-control-center.desktop ]; then
    sed -i 's|/usr/lib/tuxedo-control-center|/opt/tuxedo-control-center|g' \
        /usr/share/applications/tuxedo-control-center.desktop
fi

# Update service files to use /opt paths
for service_file in /etc/systemd/system/tccd*.service; do
    if [ -f "$service_file" ]; then
        sed -i 's|/usr/lib/tuxedo-control-center|/opt/tuxedo-control-center|g' "$service_file"
    fi
done

# Enable TCC services
systemctl enable tccd.service 2>/dev/null || true
systemctl enable tccd-sleep.service 2>/dev/null || true

# Install SELinux policies for V8 runtime
echo "Installing SELinux policies for V8 runtime..."
mkdir -p /usr/share/selinux/policy/modules/cil/200

# Enhanced SELinux policy for V8/Node.js runtime
cat > /usr/share/selinux/policy/modules/cil/200/tccd-v8-enhanced.cil << 'EOF'
;; Enhanced SELinux policy for TCC V8/Node.js runtime
(policy_module tccd_v8_enhanced 1.0.0)

(require
    (type tccd_t)
    (type init_t)
    (class process (execmem execmod execstack heap mmap))
    (class capability3 (setuid))
)

;; Allow V8 to modify memory permissions for JIT compilation
(allow tccd_t init_t (process (execmem execmod execstack heap)))

;; Allow memory mapping operations needed by V8
(allow tccd_t self (process (mmap)))

;; Allow capability setting for runtime privileges
(allow tccd_t self (capability3 t (setuid)))
EOF

# Try to install SELinux policy (may fail in containers without SELinux)
if command -v semodule > /dev/null 2>&1; then
    semodule -s targeted -i /usr/share/selinux/policy/modules/cil/200/tccd-v8-enhanced.cil 2>/dev/null || {
        echo "Warning: Could not install SELinux policy (normal in containers without SELinux)"
    }
else
    echo "SELinux utilities not available, policy saved for manual installation"
fi

# Create CLI wrapper for consistent launch behavior
install -m 755 /dev/stdin /usr/bin/tuxedo-control-center <<'EOF'
#!/bin/bash
# Launch TCC - pass all arguments through
exec /opt/tuxedo-control-center/tuxedo-control-center "$@"
EOF

echo "=== TCC Installation Complete ==="


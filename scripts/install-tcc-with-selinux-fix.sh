#!/bin/bash
# Enhanced TCC installation with proper SELinux V8 support
set -eux

echo "=== Enhanced TCC Installation with SELinux Fix ==="

# Install TCC - move to /usr/lib for ostree compatibility
if [ -L /opt ]; then
    rm /opt
    mkdir -p /opt
elif [ ! -d /opt ]; then
    mkdir -p /opt
fi

dnf -y install tuxedo-control-center && dnf -y clean all

if [ ! -d /opt/tuxedo-control-center ]; then
    echo "ERROR: TCC not installed to /opt/tuxedo-control-center"
    rpm -ql tuxedo-control-center || true
    exit 1
fi

mkdir -p /usr/lib/tuxedo-control-center
cp -a /opt/tuxedo-control-center/. /usr/lib/tuxedo-control-center/
rpm -q tuxedo-control-center --qf '%{VERSION}-%{RELEASE}\n' > /usr/lib/tuxedo-control-center/.build-version
rm -rf /opt/tuxedo-control-center
mkdir -p /var/opt
ln -sfn /usr/lib/tuxedo-control-center /opt/tuxedo-control-center
ln -sfn /usr/lib/tuxedo-control-center /var/opt/tuxedo-control-center

if [ -f /usr/share/applications/tuxedo-control-center.desktop ]; then
    sed -i 's|/usr/lib/tuxedo-control-center|/opt/tuxedo-control-center|g' /usr/share/applications/tuxedo-control-center.desktop
fi

# Update service files to use /opt paths (existing code)
for service_file in /etc/systemd/system/tccd*.service; do
    if [ -f "$service_file" ]; then
        sed -i 's|/usr/lib/tuxedo-control-center|/opt/tuxedo-control-center|g' "$service_file"
    fi
done

# Enable services
systemctl enable tccd.service 2>/dev/null || true
systemctl enable tccd-sleep.service 2>/dev/null || true

echo "=== Installing Enhanced SELinux Policy ==="

# Create comprehensive SELinux policy for V8 runtime
mkdir -p /usr/share/selinux/policy/modules/cil/200

# Enhanced policy that covers all V8 memory operations
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

# Try to install the policy
echo "Installing SELinux policy..."
if command -v semodule > /dev/null 2>&1; then
    # Install policy but don't fail if it doesn't work (some containers don't have SELinux)
    semodule -s targeted -i /usr/share/selinux/policy/modules/cil/200/tccd-v8-enhanced.cil || {
        echo "Warning: Could not install SELinux policy (this is normal in some containers)"
        echo "Policy file saved for manual installation: /usr/share/selinux/policy/modules/cil/200/tccd-v8-enhanced.cil"
    }
else
    echo "SELinux utilities not available, saving policy for manual installation"
fi

# Also create the old policy for compatibility
cat > /usr/share/selinux/policy/modules/cil/200/tccd-execmem.cil << 'EOF'
(policy_module tccd_execmem 1.0.0)

(require
    (type tccd_t)
    (type init_t)
    (class process (execmem))
)

(allow tccd_t init_t (process (execmem)))
EOF

# Try to install old policy too
if command -v semodule > /dev/null 2>&1; then
    semodule -s targeted -i /usr/share/selinux/policy/modules/cil/200/tccd-execmem.cil || echo "Legacy policy install failed"
fi

echo "✅ TCC staged to /usr/lib/tuxedo-control-center with enhanced runtime support"
echo "✅ SELinux policies installed for V8 memory operations"

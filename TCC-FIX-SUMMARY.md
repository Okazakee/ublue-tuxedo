# TCC Service Fix Summary

## Issues Identified

1. **Missing `/opt` symlink**: TCC components may hardcode paths to `/opt/tuxedo-control-center`, but we only had a symlink at `/var/opt/tuxedo-control-center`
2. **Service verification needed**: Need to verify tccd service files are correctly updated and the binary is accessible

## Changes Made to All 36 Containerfiles

### 1. Added `/opt` Symlink

**Before:**

```dockerfile
ln -sf /usr/lib/tuxedo-control-center /var/opt/tuxedo-control-center;
```

**After:**

```dockerfile
# Create symlinks for compatibility (both /opt and /var/opt)
mkdir -p /var/opt;
ln -sf /usr/lib/tuxedo-control-center /var/opt/tuxedo-control-center;
# Create /opt symlink (some TCC components may look here)
ln -sf /usr/lib/tuxedo-control-center /opt/tuxedo-control-center; \
```

**Why:** Some TCC components or configuration files may still reference `/opt/tuxedo-control-center`. In rpm-ostree systems, `/opt` can be writable if it's not a symlink, so we create a symlink there as well.

### 2. Added Service Verification & Debugging

Added comprehensive debugging output during build to verify:

- Service files exist in `/etc/systemd/system/`
- Service file contents show correct paths
- tccd binary exists at `/usr/lib/tuxedo-control-center/resources/dist/tuxedo-control-center/data/service/tccd`
- Both symlinks (`/opt` and `/var/opt`) are correctly created

**Debug output includes:**

```bash
echo "=== Checking tccd service files ===";
ls -la /etc/systemd/system/tccd*.service || echo "No service files found";
for svc in /etc/systemd/system/tccd*.service; do
    if [ -f "$svc" ]; then
        echo "--- Content of $svc ---";
        cat "$svc";
    fi;
done;
ls -la /usr/lib/systemd/system/tccd*.service 2>/dev/null || echo "No service files in /usr/lib/systemd/system";
echo "=== Checking tccd binary ===";
ls -la /usr/lib/tuxedo-control-center/resources/dist/tuxedo-control-center/data/service/tccd || echo "tccd binary not found";
echo "=== Checking symlinks ===";
ls -la /opt/tuxedo-control-center || echo "/opt symlink missing";
ls -la /var/opt/tuxedo-control-center || echo "/var/opt symlink missing";
```

## What This Fixes

1. **Service startup issues**: tccd service will now find all required files whether it looks in `/opt` or `/usr/lib`
2. **Configuration file access**: Any TCC config that references `/opt/tuxedo-control-center` will work via the symlink
3. **Better diagnostics**: Build logs will now show exactly what's wrong if the service fails

## Testing the Fix

After building and rebasing:

1. **Check if service is running:**

   ```bash
   systemctl status tccd.service
   ```

2. **Check symlinks:**

   ```bash
   ls -la /opt/tuxedo-control-center
   ls -la /var/opt/tuxedo-control-center
   ```

3. **Launch TCC GUI:**

   ```bash
   tuxedo-control-center
   ```

4. **Check logs if it fails:**
   ```bash
   journalctl -u tccd.service -n 50
   ```

## Next Steps

If the service still doesn't work after these fixes:

1. Check the build logs for the debug output
2. Verify the tccd binary has correct permissions and dependencies
3. Check if SIGILL error still occurs (CPU incompatibility issue)
4. Verify Electron/Chrome sandbox settings if GUI issues persist

## Files Updated

All 36 Containerfiles in `containerfiles/` directory have been updated with these fixes.

#!/bin/bash
# Reload Tuxedo modules on resume from suspend
# Fixes keyboard backlight and other hardware issues after suspend

case "$1" in
    pre)
        # Before suspend - unload modules if needed
        modprobe -r tuxedo_keyboard tuxedo_io 2>/dev/null || true
        ;;
    post)
        # After resume - reload modules
        sleep 1
        /usr/local/bin/tuxedo-load-modules 2>/dev/null || true
        ;;
esac

exit 0


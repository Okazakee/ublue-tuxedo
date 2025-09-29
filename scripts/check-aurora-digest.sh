#!/bin/bash
# Check if Aurora base image digest has changed
# Used in CI to skip builds when base image hasn't changed

set -euo pipefail

AURORA_IMAGE="ghcr.io/ublue-os/aurora:stable"
DIGEST_FILE=".aurora-digest"

log_info() {
    echo "[INFO] $1"
}

log_success() {
    echo "[SUCCESS] $1"
}

log_warning() {
    echo "[WARNING] $1"
}

get_current_digest() {
    log_info "Fetching current digest for $AURORA_IMAGE"
    
    if command -v skopeo >/dev/null 2>&1; then
        skopeo inspect "docker://$AURORA_IMAGE" | jq -r '.Digest'
    else
        log_warning "skopeo not available, using docker"
        docker manifest inspect "$AURORA_IMAGE" | jq -r '.config.digest'
    fi
}

get_stored_digest() {
    if [ -f "$DIGEST_FILE" ]; then
        cat "$DIGEST_FILE"
    else
        echo ""
    fi
}

update_digest_file() {
    local new_digest="$1"
    echo "$new_digest" > "$DIGEST_FILE"
    log_success "Updated digest file: $new_digest"
}

main() {
    local current_digest
    local stored_digest
    
    current_digest=$(get_current_digest)
    stored_digest=$(get_stored_digest)
    
    log_info "Current digest: $current_digest"
    log_info "Stored digest:  $stored_digest"
    
    if [ "$current_digest" = "$stored_digest" ] && [ -n "$current_digest" ]; then
        log_success "Aurora base image digest unchanged - skipping build"
        echo "skip_build=true" >> "$GITHUB_OUTPUT"
        exit 0
    else
        log_info "Aurora base image digest changed - proceeding with build"
        update_digest_file "$current_digest"
        echo "skip_build=false" >> "$GITHUB_OUTPUT"
        exit 0
    fi
}

# Show usage if help requested
if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
    cat << EOF
Check Aurora Digest

This script checks if the Aurora base image digest has changed
and updates the digest file if needed.

Usage: $0 [--help]

The script will:
1. Fetch the current digest of ghcr.io/ublue-os/aurora:stable
2. Compare it with the stored digest in .aurora-digest
3. Update the digest file if it has changed
4. Set GitHub Actions output 'skip_build' accordingly

EOF
    exit 0
fi

main "$@"

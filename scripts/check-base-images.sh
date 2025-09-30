#!/bin/bash
# Check if any Universal Blue base image digest has changed
# Used in CI to skip builds when base images haven't changed

set -euo pipefail

# Base images to check
BASE_IMAGES=(
    "ghcr.io/ublue-os/aurora:stable"
    "ghcr.io/ublue-os/aurora:latest"
    "ghcr.io/ublue-os/aurora-dx:stable"
    "ghcr.io/ublue-os/aurora-dx:latest"
    "ghcr.io/ublue-os/bluefin:stable"
    "ghcr.io/ublue-os/bluefin:latest"
    "ghcr.io/ublue-os/bluefin-dx:stable"
    "ghcr.io/ublue-os/bluefin-dx:latest"
    "ghcr.io/ublue-os/bazzite:stable"
)

DIGEST_FILE=".base-image-digests"

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
    local image="$1"
    
    if command -v skopeo >/dev/null 2>&1; then
        skopeo inspect "docker://$image" 2>/dev/null | jq -r '.Digest' || echo ""
    else
        docker manifest inspect "$image" 2>/dev/null | jq -r '.config.digest' || echo ""
    fi
}

get_all_digests() {
    local digests=""
    for image in "${BASE_IMAGES[@]}"; do
        log_info "Fetching digest for $image"
        local digest=$(get_current_digest "$image")
        if [ -n "$digest" ]; then
            digests="${digests}${image}=${digest}\n"
        fi
    done
    echo -e "$digests"
}

get_stored_digests() {
    if [ -f "$DIGEST_FILE" ]; then
        cat "$DIGEST_FILE"
    else
        echo ""
    fi
}

update_digest_file() {
    local new_digests="$1"
    echo -e "$new_digests" > "$DIGEST_FILE"
    log_success "Updated digest file with all base image digests"
}

map_image_to_variants() {
    local image="$1"
    case "$image" in
        "ghcr.io/ublue-os/aurora:stable")
            echo "aurora-stable"
            ;;
        "ghcr.io/ublue-os/aurora:latest")
            echo "aurora-latest"
            ;;
        "ghcr.io/ublue-os/aurora-dx:stable")
            echo "aurora-dx-stable"
            ;;
        "ghcr.io/ublue-os/aurora-dx:latest")
            echo "aurora-dx-latest"
            ;;
        "ghcr.io/ublue-os/bluefin:stable")
            echo "bluefin-stable"
            ;;
        "ghcr.io/ublue-os/bluefin:latest")
            echo "bluefin-latest"
            ;;
        "ghcr.io/ublue-os/bluefin-dx:stable")
            echo "bluefin-dx-stable"
            ;;
        "ghcr.io/ublue-os/bluefin-dx:latest")
            echo "bluefin-dx-latest"
            ;;
        "ghcr.io/ublue-os/bazzite:stable")
            echo "bazzite-stable"
            ;;
    esac
}

main() {
    local current_digests
    local stored_digests
    local changed_variants=()
    
    stored_digests=$(get_stored_digests)
    
    log_info "Checking base image digests for changes..."
    
    # Check each base image individually
    for image in "${BASE_IMAGES[@]}"; do
        log_info "Checking $image"
        local current_digest=$(get_current_digest "$image")
        local stored_line=$(echo "$stored_digests" | grep "^${image}=" || echo "")
        local stored_digest=""
        
        if [ -n "$stored_line" ]; then
            stored_digest="${stored_line#*=}"
        fi
        
        if [ "$current_digest" != "$stored_digest" ] || [ -z "$stored_digest" ]; then
            log_info "  → Digest changed for $image"
            local variant=$(map_image_to_variants "$image")
            if [ -n "$variant" ]; then
                changed_variants+=("\"$variant\"")
            fi
        else
            log_info "  → No change for $image"
        fi
    done
    
    # Update digest file with current state
    current_digests=$(get_all_digests)
    update_digest_file "$current_digests"
    
    if [ ${#changed_variants[@]} -eq 0 ]; then
        log_success "No base images changed - skipping all builds"
        echo "skip_all=true" >> "$GITHUB_OUTPUT"
        echo "variants_to_build=[]" >> "$GITHUB_OUTPUT"
    else
        log_success "Found ${#changed_variants[@]} variant(s) to build"
        local variants_json="[$(IFS=,; echo "${changed_variants[*]}")]"
        log_info "Variants to build: $variants_json"
        echo "skip_all=false" >> "$GITHUB_OUTPUT"
        echo "variants_to_build=$variants_json" >> "$GITHUB_OUTPUT"
    fi
}

# Show usage if help requested
if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
    cat << EOF
Check Universal Blue Base Image Digests

This script checks if any Universal Blue base image digest has changed
and updates the digest file if needed.

Usage: $0 [--help]

The script will:
1. Fetch the current digests of all base images (Aurora, Bluefin, Bazzite)
2. Compare them with the stored digests in .base-image-digests
3. Update the digest file if any have changed
4. Set GitHub Actions output 'skip_build' accordingly

Base images checked:
$(printf '  - %s\n' "${BASE_IMAGES[@]}")

EOF
    exit 0
fi

main "$@"


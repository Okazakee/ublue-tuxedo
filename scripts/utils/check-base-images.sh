#!/bin/bash
# Check if any Universal Blue base image digest has changed
# Used in CI to skip builds when base images haven't changed

set -euo pipefail

# Parse command line arguments
FILTER_PATTERN=""
SPECIFIC_IMAGES=()
DIGEST_FILE=".base-image-digests"

while [[ $# -gt 0 ]]; do
  case $1 in
    --filter)
      FILTER_PATTERN="$2"
      shift 2
      ;;
    --images)
      shift  # Remove --images
      # Collect all arguments until next --option or end
      while [[ $# -gt 0 ]] && [[ $1 != --* ]]; do
        SPECIFIC_IMAGES+=("$1")
        shift
      done
      ;;
    --digest-file)
      DIGEST_FILE="$2"
      shift 2
      ;;
    --help|-h)
      SHOW_HELP=true
      shift
      ;;
    *)
      echo "Unknown option $1"
      exit 1
      ;;
  esac
done

# Define all base images
ALL_BASE_IMAGES=(
    "ghcr.io/ublue-os/aurora:stable"
    "ghcr.io/ublue-os/aurora:latest"
    "ghcr.io/ublue-os/aurora-dx:stable"
    "ghcr.io/ublue-os/aurora-dx:latest"
    "ghcr.io/ublue-os/aurora-nvidia:stable"
    "ghcr.io/ublue-os/aurora-nvidia:latest"
    "ghcr.io/ublue-os/aurora-dx-nvidia:stable"
    "ghcr.io/ublue-os/aurora-dx-nvidia:latest"
    "ghcr.io/ublue-os/bluefin:stable"
    "ghcr.io/ublue-os/bluefin:latest"
    "ghcr.io/ublue-os/bluefin-dx:stable"
    "ghcr.io/ublue-os/bluefin-dx:latest"
    "ghcr.io/ublue-os/bluefin-nvidia:stable"
    "ghcr.io/ublue-os/bluefin-nvidia:latest"
    "ghcr.io/ublue-os/bluefin-dx-nvidia:stable"
    "ghcr.io/ublue-os/bluefin-dx-nvidia:latest"
    "ghcr.io/ublue-os/bazzite:stable"
    "ghcr.io/ublue-os/bazzite:latest"
    "ghcr.io/ublue-os/bazzite-nvidia:stable"
    "ghcr.io/ublue-os/bazzite-nvidia:latest"
    "ghcr.io/ublue-os/bazzite-deck:stable"
    "ghcr.io/ublue-os/bazzite-deck:latest"
    "ghcr.io/ublue-os/bazzite-nvidia-open:stable"
    "ghcr.io/ublue-os/bazzite-nvidia-open:latest"
    "ghcr.io/ublue-os/bazzite-deck-nvidia:stable"
    "ghcr.io/ublue-os/bazzite-deck-nvidia:latest"
    "ghcr.io/ublue-os/bazzite-gnome:stable"
    "ghcr.io/ublue-os/bazzite-gnome:latest"
    "ghcr.io/ublue-os/bazzite-gnome-nvidia:stable"
    "ghcr.io/ublue-os/bazzite-gnome-nvidia:latest"
    "ghcr.io/ublue-os/bazzite-gnome-nvidia-open:stable"
    "ghcr.io/ublue-os/bazzite-gnome-nvidia-open:latest"
    "ghcr.io/ublue-os/bazzite-deck-gnome:stable"
    "ghcr.io/ublue-os/bazzite-deck-gnome:latest"
    "ghcr.io/ublue-os/bazzite-deck-nvidia-gnome:stable"
    "ghcr.io/ublue-os/bazzite-deck-nvidia-gnome:latest"
)

# Determine which images to check
if [ ${#SPECIFIC_IMAGES[@]} -gt 0 ]; then
    log_info() {
        echo "[INFO] $1"
    }
    log_info "Checking specific images: ${SPECIFIC_IMAGES[*]}"
    BASE_IMAGES=("${SPECIFIC_IMAGES[@]}")
elif [ -n "$FILTER_PATTERN" ]; then
    log_info() {
        echo "[INFO] $1"
    }
    log_info "Filtering images with pattern: $FILTER_PATTERN"
    
    BASE_IMAGES=()
    for image in "${ALL_BASE_IMAGES[@]}"; do
        if [[ "$image" == *"$FILTER_PATTERN"* ]]; then
            BASE_IMAGES+=("$image")
        fi
    done
else
    BASE_IMAGES=("${ALL_BASE_IMAGES[@]}")
fi

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
        "ghcr.io/ublue-os/aurora-nvidia:stable")
            echo "aurora-nvidia-stable"
            ;;
        "ghcr.io/ublue-os/aurora-nvidia:latest")
            echo "aurora-nvidia-latest"
            ;;
        "ghcr.io/ublue-os/aurora-dx-nvidia:stable")
            echo "aurora-dx-nvidia-stable"
            ;;
        "ghcr.io/ublue-os/aurora-dx-nvidia:latest")
            echo "aurora-dx-nvidia-latest"
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
        "ghcr.io/ublue-os/bluefin-nvidia:stable")
            echo "bluefin-nvidia-stable"
            ;;
        "ghcr.io/ublue-os/bluefin-nvidia:latest")
            echo "bluefin-nvidia-latest"
            ;;
        "ghcr.io/ublue-os/bluefin-dx-nvidia:stable")
            echo "bluefin-dx-nvidia-stable"
            ;;
        "ghcr.io/ublue-os/bluefin-dx-nvidia:latest")
            echo "bluefin-dx-nvidia-latest"
            ;;
        "ghcr.io/ublue-os/bazzite:stable")
            echo "bazzite-stable"
            ;;
        "ghcr.io/ublue-os/bazzite:latest")
            echo "bazzite-latest"
            ;;
        "ghcr.io/ublue-os/bazzite-nvidia:stable")
            echo "bazzite-nvidia-stable"
            ;;
        "ghcr.io/ublue-os/bazzite-nvidia:latest")
            echo "bazzite-nvidia-latest"
            ;;
        "ghcr.io/ublue-os/bazzite-deck:stable")
            echo "bazzite-deck-stable"
            ;;
        "ghcr.io/ublue-os/bazzite-deck:latest")
            echo "bazzite-deck-latest"
            ;;
        "ghcr.io/ublue-os/bazzite-nvidia-open:stable")
            echo "bazzite-nvidia-open-stable"
            ;;
        "ghcr.io/ublue-os/bazzite-nvidia-open:latest")
            echo "bazzite-nvidia-open-latest"
            ;;
        "ghcr.io/ublue-os/bazzite-deck-nvidia:stable")
            echo "bazzite-deck-nvidia-stable"
            ;;
        "ghcr.io/ublue-os/bazzite-deck-nvidia:latest")
            echo "bazzite-deck-nvidia-latest"
            ;;
        "ghcr.io/ublue-os/bazzite-gnome:stable")
            echo "bazzite-gnome-stable"
            ;;
        "ghcr.io/ublue-os/bazzite-gnome:latest")
            echo "bazzite-gnome-latest"
            ;;
        "ghcr.io/ublue-os/bazzite-gnome-nvidia:stable")
            echo "bazzite-gnome-nvidia-stable"
            ;;
        "ghcr.io/ublue-os/bazzite-gnome-nvidia:latest")
            echo "bazzite-gnome-nvidia-latest"
            ;;
        "ghcr.io/ublue-os/bazzite-gnome-nvidia-open:stable")
            echo "bazzite-gnome-nvidia-open-stable"
            ;;
        "ghcr.io/ublue-os/bazzite-gnome-nvidia-open:latest")
            echo "bazzite-gnome-nvidia-open-latest"
            ;;
        "ghcr.io/ublue-os/bazzite-deck-gnome:stable")
            echo "bazzite-deck-gnome-stable"
            ;;
        "ghcr.io/ublue-os/bazzite-deck-gnome:latest")
            echo "bazzite-deck-gnome-latest"
            ;;
        "ghcr.io/ublue-os/bazzite-deck-nvidia-gnome:stable")
            echo "bazzite-deck-nvidia-gnome-stable"
            ;;
        "ghcr.io/ublue-os/bazzite-deck-nvidia-gnome:latest")
            echo "bazzite-deck-nvidia-gnome-latest"
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
if [ "${SHOW_HELP:-false}" = "true" ]; then
    cat << EOF
Check Universal Blue Base Image Digests

This script checks if any Universal Blue base image digest has changed
and updates the digest file if needed.

Usage: $0 [OPTIONS]

Options:
  --filter PATTERN    Only check images matching the pattern (e.g., "aurora", "bazzite-nvidia")
  --images IMAGE1 IMAGE2 ... Specify exact images to check (preferred for workflows)
  --digest-file FILE  Use custom digest file (default: .base-image-digests)
  --help, -h          Show this help message

Examples:
  $0                                    # Check all base images
  $0 --filter aurora                   # Only check aurora images
  $0 --filter bazzite-nvidia           # Only check bazzite nvidia images
  $0 --filter stable                   # Only check stable variant images
  $0 --images ghcr.io/ublue-os/aurora:stable ghcr.io/ublue-os/aurora-dx:stable

The script will:
1. Fetch the current digests of base images (filtered if pattern provided)
2. Compare them with the stored digests in .base-image-digests
3. Update the digest file if any have changed
4. Set GitHub Actions output 'skip_build' accordingly

All available base images:
$(printf '  - %s\n' "${ALL_BASE_IMAGES[@]}")

EOF
    exit 0
fi

main "$@"


#!/bin/bash
# Generate all Containerfiles from template using variants.yaml
# This script reads the variant configuration and generates 36 Containerfiles

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
TEMPLATE="${REPO_ROOT}/containerfiles/Containerfile.template"
VARIANTS_CONFIG="${REPO_ROOT}/config/variants.yaml"
OUTPUT_DIR="${REPO_ROOT}/containerfiles/generated"

# Check if yq is available (for YAML parsing)
if ! command -v yq >/dev/null 2>&1; then
    echo "Error: yq is required to parse YAML. Install it with:"
    echo "  dnf install yq"
    echo "  or: pip install yq"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Check if template exists
if [ ! -f "$TEMPLATE" ]; then
    echo "Error: Template not found: $TEMPLATE"
    exit 1
fi

# Check if variants config exists
if [ ! -f "$VARIANTS_CONFIG" ]; then
    echo "Error: Variants config not found: $VARIANTS_CONFIG"
    exit 1
fi

echo "Generating Containerfiles from template..."
echo "Template: $TEMPLATE"
echo "Variants: $VARIANTS_CONFIG"
echo "Output: $OUTPUT_DIR"
echo ""

# Read variants from YAML and generate Containerfiles
variant_count=0
while IFS= read -r variant_name; do
    if [ -z "$variant_name" ]; then
        continue
    fi
    
    # Extract variant data using yq
    base_image=$(yq eval ".variants[] | select(.name == \"$variant_name\") | .base_image" "$VARIANTS_CONFIG")
    description=$(yq eval ".variants[] | select(.name == \"$variant_name\") | .description" "$VARIANTS_CONFIG")
    package_name=$(yq eval ".variants[] | select(.name == \"$variant_name\") | .package_name" "$VARIANTS_CONFIG")
    
    if [ -z "$base_image" ] || [ "$base_image" = "null" ]; then
        echo "Warning: Skipping variant '$variant_name' - no base_image found"
        continue
    fi
    
    output_file="${OUTPUT_DIR}/Containerfile.${variant_name}"
    
    # Generate Containerfile by replacing ARG BASE_IMAGE and FROM ${BASE_IMAGE} with actual base image
    # The template has: ARG BASE_IMAGE\nFROM ${BASE_IMAGE}
    # We replace ARG line with a comment and FROM line with actual base image
    sed "s|^ARG BASE_IMAGE|# Base image: ${base_image}|" "$TEMPLATE" | \
    sed "s|FROM \${BASE_IMAGE}|FROM ${base_image}|" | \
    sed "s|LABEL org.opencontainers.image.title=\"tuxedo\"|LABEL org.opencontainers.image.title=\"${package_name}\"|" | \
    sed "s|LABEL org.opencontainers.image.description=\"Universal Blue with Tuxedo drivers and TCC\"|LABEL org.opencontainers.image.description=\"${description}\"|" > "$output_file"
    
    variant_count=$((variant_count + 1))
    echo "Generated: Containerfile.${variant_name} (${base_image})"
done < <(yq eval '.variants[].name' "$VARIANTS_CONFIG")

echo ""
echo "Successfully generated ${variant_count} Containerfiles in ${OUTPUT_DIR}"
echo ""
echo "To use these Containerfiles, copy them from ${OUTPUT_DIR} to ${REPO_ROOT}/containerfiles/"
echo "Or update your build process to use the generated directory."


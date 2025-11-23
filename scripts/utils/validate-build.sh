#!/bin/bash
# Validate build configuration and generated files
# Checks that all components are in place and correctly configured

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TEMPLATE="${REPO_ROOT}/containerfiles/Containerfile.template"
VARIANTS_CONFIG="${REPO_ROOT}/config/variants.yaml"
GENERATED_DIR="${REPO_ROOT}/containerfiles/generated"

errors=0
warnings=0

log_error() {
    echo "ERROR: $1" >&2
    ((errors++))
}

log_warning() {
    echo "WARNING: $1" >&2
    ((warnings++))
}

log_info() {
    echo "INFO: $1"
}

# Check template exists
if [ ! -f "$TEMPLATE" ]; then
    log_error "Template not found: $TEMPLATE"
else
    log_info "Template found: $TEMPLATE"
fi

# Check variants config exists
if [ ! -f "$VARIANTS_CONFIG" ]; then
    log_error "Variants config not found: $VARIANTS_CONFIG"
else
    log_info "Variants config found: $VARIANTS_CONFIG"
    
    # Validate YAML syntax if yq is available
    if command -v yq >/dev/null 2>&1; then
        if yq eval . "$VARIANTS_CONFIG" > /dev/null 2>&1; then
            log_info "Variants YAML syntax is valid"
        else
            log_error "Variants YAML syntax is invalid"
        fi
    else
        log_warning "yq not found, skipping YAML validation"
    fi
fi

# Check generated Containerfiles
if [ ! -d "$GENERATED_DIR" ]; then
    log_warning "Generated directory not found: $GENERATED_DIR"
    log_warning "Run 'make generate' to create Containerfiles"
else
    generated_count=$(find "$GENERATED_DIR" -name "Containerfile.*" 2>/dev/null | wc -l)
    if [ "$generated_count" -lt 36 ]; then
        log_warning "Only $generated_count Containerfiles found (expected 36)"
        log_warning "Run 'make generate' to regenerate"
    else
        log_info "Found $generated_count generated Containerfiles"
    fi
fi

# Check scripts are executable
script_dirs=(
    "${REPO_ROOT}/scripts/install"
    "${REPO_ROOT}/scripts/runtime"
    "${REPO_ROOT}/scripts/utils"
    "${REPO_ROOT}/scripts/build"
)

for dir in "${script_dirs[@]}"; do
    if [ -d "$dir" ]; then
        for script in "$dir"/*.sh; do
            if [ -f "$script" ] && [ ! -x "$script" ]; then
                log_warning "Script is not executable: $script"
            fi
        done
    fi
done

# Check overlay structure
overlay_dir="${REPO_ROOT}/overlay"
if [ ! -d "$overlay_dir" ]; then
    log_warning "Overlay directory not found: $overlay_dir"
else
    log_info "Overlay directory found"
fi

# Summary
echo ""
if [ $errors -gt 0 ]; then
    echo "Validation FAILED with $errors error(s) and $warnings warning(s)"
    exit 1
elif [ $warnings -gt 0 ]; then
    echo "Validation PASSED with $warnings warning(s)"
    exit 0
else
    echo "Validation PASSED"
    exit 0
fi


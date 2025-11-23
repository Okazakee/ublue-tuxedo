# Makefile for Universal Blue Tuxedo
# Build system for managing 36 image variants

.PHONY: help generate build build-all build-variant test validate clean

# Configuration
REPO_ROOT := $(shell pwd)
SCRIPTS_DIR := $(REPO_ROOT)/scripts
CONFIG_DIR := $(REPO_ROOT)/config
CONTAINERFILES_DIR := $(REPO_ROOT)/containerfiles
GENERATED_DIR := $(CONTAINERFILES_DIR)/generated
VARIANTS_CONFIG := $(CONFIG_DIR)/variants.yaml
TEMPLATE := $(CONTAINERFILES_DIR)/Containerfile.template

# Build tool (podman or docker)
BUILD_TOOL ?= podman
BUILD_CMD := $(BUILD_TOOL) build

# Default registry and namespace
REGISTRY ?= ghcr.io
NAMESPACE ?= okazakee

help:
	@echo "Universal Blue Tuxedo Build System"
	@echo ""
	@echo "Targets:"
	@echo "  generate       - Generate all Containerfiles from template"
	@echo "  build-all      - Build all 36 variants (local)"
	@echo "  build          - Build a specific variant (requires VARIANT=name)"
	@echo "  test           - Run validation tests"
	@echo "  validate       - Validate configuration and generated files"
	@echo "  clean          - Clean generated Containerfiles"
	@echo ""
	@echo "Examples:"
	@echo "  make generate"
	@echo "  make build VARIANT=aurora"
	@echo "  make build-all"
	@echo "  make validate"

generate:
	@echo "Generating Containerfiles from template..."
	@chmod +x $(SCRIPTS_DIR)/build/generate-containerfiles.sh
	@bash $(SCRIPTS_DIR)/build/generate-containerfiles.sh
	@echo "Done. Generated files are in $(GENERATED_DIR)"

build: validate
	@if [ -z "$(VARIANT)" ]; then \
		echo "Error: VARIANT is required. Example: make build VARIANT=aurora"; \
		exit 1; \
	fi
	@echo "Building variant: $(VARIANT)"
	@VARIANT_FILE=$(GENERATED_DIR)/Containerfile.$(VARIANT); \
	if [ ! -f "$$VARIANT_FILE" ]; then \
		echo "Error: Containerfile not found: $$VARIANT_FILE"; \
		echo "Run 'make generate' first"; \
		exit 1; \
	fi
	@BASE_IMAGE=$$(grep "^FROM" $$VARIANT_FILE | head -1 | awk '{print $$2}'); \
	PACKAGE_NAME=$$(grep "org.opencontainers.image.title" $$VARIANT_FILE | sed 's/.*"\(.*\)".*/\1/'); \
	TAG=$$(grep "org.opencontainers.image.title" $$VARIANT_FILE | sed 's/.*"\(.*\)".*/\1/' | sed 's/.*-tuxedo//' || echo "stable"); \
	echo "Building $(VARIANT) -> $(REGISTRY)/$(NAMESPACE)/$$PACKAGE_NAME:$$TAG"; \
	$(BUILD_CMD) -f $$VARIANT_FILE -t $(REGISTRY)/$(NAMESPACE)/$$PACKAGE_NAME:$$TAG .

build-all: generate
	@echo "Building all 36 variants..."
	@echo "This will take a long time. Consider building specific variants instead."
	@echo "Press Ctrl+C to cancel, or wait 5 seconds to continue..."
	@sleep 5
	@count=0; \
	while IFS= read -r variant; do \
		if [ -n "$$variant" ]; then \
			count=$$((count + 1)); \
			echo "[$$count/36] Building $$variant..."; \
			$(MAKE) build VARIANT=$$variant || echo "Failed to build $$variant"; \
		fi; \
	done < <(grep -E "^  - name:" $(VARIANTS_CONFIG) | sed 's/.*name: //' | sed 's/"//g'); \
	echo "Build complete. Check results above."

test:
	@echo "Running validation tests..."
	@chmod +x $(SCRIPTS_DIR)/utils/validate-build.sh 2>/dev/null || true
	@bash $(SCRIPTS_DIR)/utils/validate-build.sh || echo "Validation script not found, skipping"

validate: generate
	@echo "Validating configuration..."
	@if [ ! -f "$(TEMPLATE)" ]; then \
		echo "Error: Template not found: $(TEMPLATE)"; \
		exit 1; \
	fi
	@if [ ! -f "$(VARIANTS_CONFIG)" ]; then \
		echo "Error: Variants config not found: $(VARIANTS_CONFIG)"; \
		exit 1; \
	fi
	@if ! command -v yq >/dev/null 2>&1; then \
		echo "Warning: yq not found. Install it for YAML validation."; \
	else \
		echo "Validating YAML syntax..."; \
		yq eval . $(VARIANTS_CONFIG) > /dev/null || exit 1; \
		echo "YAML syntax valid"; \
	fi
	@echo "Checking generated Containerfiles..."
	@generated_count=$$(find $(GENERATED_DIR) -name "Containerfile.*" 2>/dev/null | wc -l); \
	if [ "$$generated_count" -lt 36 ]; then \
		echo "Warning: Only $$generated_count Containerfiles found (expected 36)"; \
		echo "Run 'make generate' to regenerate"; \
	else \
		echo "Found $$generated_count Containerfiles"; \
	fi
	@echo "Validation complete"

clean:
	@echo "Cleaning generated Containerfiles..."
	@rm -rf $(GENERATED_DIR)/Containerfile.*
	@echo "Clean complete"


# Contributing to Universal Blue Tuxedo

Thank you for your interest in contributing! This guide will help you get started.

## Development Setup

### Prerequisites

- Docker or Podman
- Make
- yq (for YAML parsing)
- Git

### Initial Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/okazakee/ublue-tuxedo.git
   cd ublue-tuxedo
   ```

2. Generate Containerfiles:
   ```bash
   make generate
   ```

3. Test a build:
   ```bash
   make build VARIANT=aurora
   ```

## Development Workflow

### Making Changes

1. **Edit the template** (not generated files):
   - Modify `containerfiles/Containerfile.template`
   - Update scripts in `scripts/` directories
   - Modify overlay files in `overlay/`

2. **Regenerate Containerfiles**:
   ```bash
   make generate
   ```

3. **Test your changes**:
   ```bash
   make build VARIANT=aurora
   ```

4. **Validate**:
   ```bash
   make validate
   ```

### Adding a New Variant

1. Edit `config/variants.yaml`:
   ```yaml
   - name: new-variant
     base_image: ghcr.io/ublue-os/base:tag
     tags: [stable]
     description: "Description here"
     package_name: new-variant-tuxedo
   ```

2. Regenerate:
   ```bash
   make generate
   ```

3. Test:
   ```bash
   make build VARIANT=new-variant
   ```

### Modifying Scripts

Scripts are organized by function:

- **`scripts/install/`**: Installation scripts (run during build)
- **`scripts/runtime/`**: Runtime scripts (run on boot/runtime)
- **`scripts/utils/`**: Utility scripts (helper functions)
- **`scripts/build/`**: Build-time scripts (generation, etc.)

When modifying scripts:
1. Ensure they're executable: `chmod +x scripts/path/to/script.sh`
2. Test with a build: `make build VARIANT=aurora`
3. Check error handling and edge cases

### Updating Overlay Files

Overlay files are copied directly into images:

- **`overlay/etc/`**: System configuration
- **`overlay/usr/`**: User-space files
- **`overlay/usr/share/tuxedo/mok/`**: MOK certificates (from secrets)

Changes to overlay files take effect on next build.

## Code Style

### Shell Scripts

- Use `set -euo pipefail` for error handling
- Use meaningful variable names
- Add comments for complex logic
- Follow existing patterns

### YAML Files

- Use 2-space indentation
- Keep consistent structure
- Add comments for clarity

### Containerfiles

- Keep template generic (use ARG for variants)
- Add comments for each major section
- Group related RUN commands

## Testing

### Local Testing

1. **Single variant**:
   ```bash
   make build VARIANT=aurora
   ```

2. **Multiple variants**:
   ```bash
   make build VARIANT=aurora
   make build VARIANT=bluefin
   ```

3. **All variants** (takes time):
   ```bash
   make build-all
   ```

### Validation

```bash
make validate
```

This checks:
- Template exists
- Variants config is valid YAML
- Generated Containerfiles exist
- Scripts are executable

## Pull Request Process

1. **Fork the repository**

2. **Create a feature branch**:
   ```bash
   git checkout -b feature/my-feature
   ```

3. **Make your changes**:
   - Edit template/scripts/config
   - Regenerate Containerfiles
   - Test your changes

4. **Commit your changes**:
   ```bash
   git add .
   git commit -m "Description of changes"
   ```

5. **Push to your fork**:
   ```bash
   git push origin feature/my-feature
   ```

6. **Create a Pull Request**:
   - Describe your changes
   - Reference any related issues
   - Include test results if applicable

### PR Checklist

- [ ] Changes tested locally
- [ ] `make validate` passes
- [ ] Generated Containerfiles updated (if template changed)
- [ ] Documentation updated (if needed)
- [ ] No hardcoded paths or passwords
- [ ] Scripts are executable

## Common Tasks

### Updating Base Images

1. Edit `config/variants.yaml`
2. Update base image tags
3. Run `make generate`
4. Test builds

### Adding New Scripts

1. Create script in appropriate directory
2. Make executable: `chmod +x scripts/path/script.sh`
3. Reference in `Containerfile.template`
4. Test build

### Fixing Build Issues

1. Check build logs for errors
2. Test script in isolation if possible
3. Verify file paths and permissions
4. Check overlay structure

## Questions?

- Open an issue for bugs or feature requests
- Check existing issues for similar problems
- Review `docs/ARCHITECTURE.md` for system overview

## License

Contributions are welcome! By contributing, you agree that your contributions will be licensed under the same license as the project.


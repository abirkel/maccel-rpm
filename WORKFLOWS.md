# Build Workflows

This repository uses automated GitHub Actions workflows to build and publish RPM packages.

## Workflow Architecture

The build workflow consists of five jobs that run in sequence:

1. **load-config**: Loads build configuration from `build.conf`
2. **update-specs** (optional): Updates spec files with new version/release numbers and commits changes
3. **build-rpm**: Builds RPM packages in a container with the specified kernel-devel
4. **publish**: Creates GitHub release and deploys packages to GitHub Pages repository
5. **cleanup-on-failure** (conditional): Reverts spec updates if build or publish fails

**Key Features:**
- Spec files are the single source of truth for package versions
- Version updates are committed before building to maintain consistency
- Automatic rollback of spec changes if builds fail
- Supports building against specific container images with matching kernel-devel packages

## Automatic Builds

### Maccel Release Detection (`check-release.yml`)

- Runs daily to check for new maccel releases
- Automatically triggers a full build (akmod + CLI) when a new release is detected
- Uses `update_specs: true` to update spec files with the new version

### Container Image Monitoring

- Monitors the container image specified in `build.conf`
- Detects kernel version changes in the image
- Automatically triggers kmod-only rebuilds when the kernel updates
- Supports multiple registries: GitHub Container Registry (ghcr.io), Quay.io, and Docker Hub

## Manual Builds

Trigger builds manually via GitHub Actions with custom options:

**Build Current Version** (uses version from spec files)
```bash
gh workflow run build-rpm.yml
```

**Update to New Version and Build**
```bash
gh workflow run build-rpm.yml \
  -f maccel_version=v0.5.7 \
  -f update_specs=true
```

**Rebuild Same Version** (increments release number)
```bash
gh workflow run build-rpm.yml \
  -f maccel_version=v0.5.6 \
  -f update_specs=true
```

**Kmod Only** (for kernel updates)
```bash
gh workflow run build-rpm.yml \
  -f build_akmod=false \
  -f build_cli=false \
  -f build_kmod=true
```

**Custom Container Image**
```bash
gh workflow run build-rpm.yml \
  -f container_image=quay.io/ublue/aurora \
  -f fedora_version=40
```

## Build Configuration

Edit `build.conf` to customize the default container image:

```bash
CONTAINER_IMAGE=ghcr.io/ublue-os/aurora-nvidia-open
CONTAINER_VERSION=latest
ENABLE_KMOD=true
```

### Container Requirements

This workflow is designed to build kmod packages for uBlue atomic images. uBlue images often ship with kernels slightly behind Fedora main, and the corresponding kernel-devel packages are no longer available in standard repositories—they only exist in the images themselves.

- **For kmod builds**: Requires a full OS container with kernel-devel installed (e.g., Aurora)
- **For akmod + CLI only**: Can use smaller Fedora images (e.g., `fedora:latest`)
- **To disable kmod**: Set `ENABLE_KMOD=false` in `build.conf`

See [Building Guide](BUILDING.md) for detailed container selection guidance.

## Build Inputs

The `build-rpm.yml` workflow accepts these inputs:

- `maccel_version` (string, optional) - Maccel version to build (e.g., v0.5.6). Only used with `update_specs`
- `update_specs` (boolean, default: false) - Update spec files with new version and release numbers before building
- `build_akmod` (boolean, default: true) - Build akmod package
- `build_cli` (boolean, default: true) - Build CLI package
- `build_kmod` (boolean, default: false) - Build kmod package
- `container_image` (string, optional) - Container image to use (overrides build.conf default)
- `fedora_version` (string, optional) - Container version tag (overrides build.conf default)

### Important Notes

- The version that gets built is determined by the `Version:` field in the spec files
- Use `update_specs: true` with `maccel_version` to update specs to a new version before building
- Without `update_specs`, the workflow builds whatever version is currently in the spec files
- Spec files are the single source of truth for package versions

### Version Update Behavior

- **New version**: Sets `Version:` to new value, resets `Release:` to 1, adds changelog entry
- **Same version**: Keeps `Version:` unchanged, increments `Release:` number, adds rebuild changelog entry
- **Automatic rollback**: If build fails after updating specs, the commit is automatically reverted

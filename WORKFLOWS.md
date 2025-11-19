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

**Build for Specific Kernel Version**
```bash
gh workflow run build-rpm.yml \
  -f kernel_version=6.11.5-300.fc41.x86_64 \
  -f build_akmod=true \
  -f build_kmod=true
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
- `kernel_version` (string, optional) - Specific kernel version to build for (e.g., 6.11.5-300.fc41.x86_64). If not provided, auto-detects from container
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

## Generated kmod Spec Workflow

The build workflow uses kmodtool to generate kmod spec files dynamically, following RPMFusion standards:

### How It Works

1. **akmod Build Phase**:
   - The akmod spec invokes kmodtool during the %build section
   - kmodtool generates a proper kmod spec with kernel-specific subpackages
   - Generated spec includes weak modules support and ABI tracking
   - The generated spec is packaged into the akmod for use by akmods

2. **kmod Build Phase** (when `build_kmod: true`):
   - Workflow locates the generated kmod spec from akmod build output
   - Searches in `~/rpmbuild/BUILD/maccel-*/kmod-maccel.spec`
   - Copies generated spec to `~/rpmbuild/SPECS/`
   - Builds kmod using: `rpmbuild --define "kernels $KVER" -ba kmod-maccel.spec`

3. **Kernel Version Handling**:
   - For akmod builds: passes `--define "kernel_version $KVER"` to rpmbuild
   - For kmod builds: passes `--define "kernels $KVER"` to rpmbuild
   - Auto-detects kernel version from container if not explicitly provided
   - Uses kernel-devel package version from the container image

### Why Generated Specs?

The kmodtool-generated specs provide:
- **Proper subpackaging**: Creates per-kernel packages (kmod-maccel-6.11.5-300.fc41.x86_64)
- **Meta-package**: Creates kmod-maccel that depends on latest kernel-specific package
- **Weak modules support**: Allows modules to work across minor kernel updates
- **ABI tracking**: Ensures module compatibility with kernel ABI
- **RPMFusion compatibility**: Follows standard packaging methodology

### Troubleshooting Generated Specs

**Generated spec not found**:
```bash
# Workflow will fail with clear error message
# Check that akmod build completed successfully
# Verify kmodtool is installed in the container
```

**kmod build fails**:
```bash
# Ensure kernel_version matches available kernel-devel
# Check that kernel-devel is installed in container
# Verify generated spec syntax with rpmlint
```

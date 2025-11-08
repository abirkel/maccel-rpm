# Maccel RPM Packaging

[![Latest Release](https://img.shields.io/github/v/release/abirkel/maccel-rpm?label=Latest%20Release&color=blue)](https://github.com/abirkel/maccel-rpm/releases/latest)
[![Build Status](https://img.shields.io/github/actions/workflow/status/abirkel/maccel-rpm/build-rpm.yml?branch=main&label=Build)](https://github.com/abirkel/maccel-rpm/actions/workflows/build-rpm.yml)
[![Platform](https://img.shields.io/badge/Platform-Fedora%20%7C%20RPM-294172?logo=fedora)](https://github.com/abirkel/maccel-rpm)

RPM packages for the [maccel](https://github.com/Gnarus-G/maccel) mouse acceleration driver for Fedora and RPM-based Linux distributions.

## Overview

This repository provides automated RPM packaging for maccel, a mouse acceleration driver consisting of a kernel module and CLI tool. Packages are built automatically via GitHub Actions when new maccel releases are detected.

## Packages

- **akmod-maccel**: Automatic kernel module package that rebuilds for new kernels using akmods
- **maccel**: CLI tool for configuring mouse acceleration parameters

## Installation

**Prerequisites**: Fedora or compatible RPM-based distribution (x86_64)

### Repository Setup

Add the maccel repository to your system:

```bash
# Download and install the repository configuration
sudo curl -L https://raw.githubusercontent.com/abirkel/maccel-rpm/main/maccel.repo \
  -o /etc/yum.repos.d/maccel.repo
```

The GPG public key will be automatically imported when you first install a package from this repository.

### Package Installation

Install maccel and its dependencies:

```bash
# Install maccel (automatically installs akmod-maccel as a dependency)
sudo dnf install maccel
```

The `maccel` package will automatically pull in `akmod-maccel`, which provides the kernel module. The akmod system will build the kernel module for your current kernel during installation.

### Post-Installation

After installation, complete these steps to start using maccel:

**1. Add Your User to the maccel Group**

The maccel group is required for non-root users to configure mouse acceleration:

```bash
# Add your user to the maccel group
sudo usermod -aG maccel $USER

# Log out and log back in for the group change to take effect
# Or use: newgrp maccel
```

**2. Verify Kernel Module is Loaded**

Check that the maccel kernel module loaded successfully:

```bash
# Check if the module is loaded
lsmod | grep maccel

# View module information
modinfo maccel

# Check module parameters
ls -l /sys/module/maccel/parameters/
```

**3. Basic CLI Usage**

Once the module is loaded and you're in the maccel group, you can use the CLI:

```bash
# View current settings
maccel print

# Set acceleration parameters (example)
maccel set --sensitivity 1.5 --acceleration 0.5

# View help for all options
maccel --help
```

For detailed usage instructions, see the [upstream maccel documentation](https://github.com/Gnarus-G/maccel#readme).

## Troubleshooting

Having issues? Check out the [Troubleshooting Guide](TROUBLESHOOTING.md) for solutions to common problems including:

- Kernel module not loading
- Permission denied errors
- Package installation failures
- Kernel update issues

For additional help, see the [upstream maccel issues](https://github.com/Gnarus-G/maccel/issues) or [open an issue](https://github.com/abirkel/maccel-rpm/issues) in this repository.

## Build Workflows

This repository uses automated GitHub Actions workflows to build and publish RPM packages.

### Workflow Architecture

The build workflow consists of four jobs that run in sequence:

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

### Automatic Builds

**Maccel Release Detection** (`check-release.yml`)
- Runs daily to check for new maccel releases
- Automatically triggers a full build (akmod + CLI) when a new release is detected
- Uses `update_specs: true` to update spec files with the new version

**Container Image Monitoring**
- Monitors the container image specified in `build.conf`
- Detects kernel version changes in the image
- Automatically triggers kmod-only rebuilds when the kernel updates
- Supports multiple registries: GitHub Container Registry (ghcr.io), Quay.io, and Docker Hub

### Manual Builds

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

### Build Configuration

Edit `build.conf` to customize the default container image:

```bash
CONTAINER_IMAGE=ghcr.io/ublue-os/aurora-nvidia-open
CONTAINER_VERSION=latest
ENABLE_KMOD=true
```

**Container Requirements**:

This workflow is designed to build kmod packages for uBlue atomic images. uBlue images often ship with kernels slightly behind Fedora main, and the corresponding kernel-devel packages are no longer available in standard repositories—they only exist in the images themselves.

- **For kmod builds**: Requires a full OS container with kernel-devel installed (e.g., Aurora)
- **For akmod + CLI only**: Can use smaller Fedora images (e.g., `fedora:latest`)
- **To disable kmod**: Set `ENABLE_KMOD=false` in `build.conf`

See [Building Guide](BUILDING.md) for detailed container selection guidance.

### Build Inputs

The `build-rpm.yml` workflow accepts these inputs:

- `maccel_version` (string, optional) - Maccel version to build (e.g., v0.5.6). Only used with `update_specs`
- `update_specs` (boolean, default: false) - Update spec files with new version and release numbers before building
- `build_akmod` (boolean, default: true) - Build akmod package
- `build_cli` (boolean, default: true) - Build CLI package
- `build_kmod` (boolean, default: false) - Build kmod package
- `container_image` (string, optional) - Container image to use (overrides build.conf default)
- `fedora_version` (string, optional) - Container version tag (overrides build.conf default)

**Important Notes:**
- The version that gets built is determined by the `Version:` field in the spec files
- Use `update_specs: true` with `maccel_version` to update specs to a new version before building
- Without `update_specs`, the workflow builds whatever version is currently in the spec files
- Spec files are the single source of truth for package versions

**Version Update Behavior:**
- **New version**: Sets `Version:` to new value, resets `Release:` to 1, adds changelog entry
- **Same version**: Keeps `Version:` unchanged, increments `Release:` number, adds rebuild changelog entry
- **Automatic rollback**: If build fails after updating specs, the commit is automatically reverted

## Building Locally

Want to build the packages yourself or modify them? See the [Building Guide](BUILDING.md) for detailed instructions on local development.

## Contributing

This is a personal packaging project for maccel. Issues and pull requests are welcome.

## License

The packaging scripts and spec files in this repository are provided as-is. The maccel software itself is licensed under GPL-2.0-or-later. See the [upstream repository](https://github.com/Gnarus-G/maccel) for details.

## Upstream

- Maccel Repository: https://github.com/Gnarus-G/maccel
- Maccel Documentation: https://github.com/Gnarus-G/maccel#readme

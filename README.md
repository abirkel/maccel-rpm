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

## Building Locally

Want to build the packages yourself or modify them? See the [Building Guide](BUILDING.md) for detailed instructions on local development.

## Contributing

This is a personal packaging project for maccel. Issues and pull requests are welcome.

## License

The packaging scripts and spec files in this repository are provided as-is. The maccel software itself is licensed under GPL-2.0-or-later. See the [upstream repository](https://github.com/Gnarus-G/maccel) for details.

## Upstream

- Maccel Repository: https://github.com/Gnarus-G/maccel
- Maccel Documentation: https://github.com/Gnarus-G/maccel#readme

# Maccel RPM Packaging

RPM packages for the [maccel](https://github.com/Gnarus-G/maccel) mouse acceleration driver for Fedora and RPM-based Linux distributions.

## Overview

This repository provides automated RPM packaging for maccel, a mouse acceleration driver consisting of a kernel module and CLI tool. Packages are built automatically via GitHub Actions when new maccel releases are detected.

## Packages

This repository builds three RPM packages:

- **akmod-maccel**: Automatic kernel module package that rebuilds for new kernels using akmods
- **kmod-maccel**: Kernel module package for specific kernel versions (optional, not built by default)
- **maccel**: CLI tool for configuring mouse acceleration parameters

## Repository Structure

```
maccel-rpm/
├── .github/
│   └── workflows/      # GitHub Actions workflows
├── .gitignore
├── specs/              # RPM spec files
└── README.md
```

## Installation

### Prerequisites

- Fedora or compatible RPM-based distribution
- x86_64 architecture
- Internet connection for downloading packages

### Repository Setup

Add the maccel repository to your system:

```bash
# Download and install the repository configuration
sudo curl -L https://raw.githubusercontent.com/abirkel/maccel-rpm/main/maccel.repo \
  -o /etc/yum.repos.d/maccel.repo
```

The GPG public key will be automatically imported when you first install a package from this repository.

**Manual GPG Key Import (Optional)**:

If you prefer to import the GPG key manually before installing packages:

```bash
# Import the GPG public key
sudo rpm --import https://raw.githubusercontent.com/abirkel/maccel-rpm/main/RPM-GPG-KEY-maccel
```

### Package Installation

Install maccel and its dependencies:

```bash
# Install maccel (automatically installs akmod-maccel as a dependency)
sudo dnf install maccel
```

The `maccel` package will automatically pull in `akmod-maccel`, which provides the kernel module. The akmod system will build the kernel module for your current kernel during installation.

**Installing Only the Kernel Module**:

If you only need the kernel module without the CLI tool:

```bash
sudo dnf install akmod-maccel
```

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

### Kernel Module Not Loading

**Problem**: The maccel module doesn't appear in `lsmod` output.

**Solutions**:
```bash
# Check if akmod build completed successfully
sudo akmods --force --kernel $(uname -r)

# Check akmod logs
sudo journalctl -u akmods

# Manually load the module
sudo modprobe maccel

# Check for build errors
ls -l /usr/src/akmods/maccel-kmod-*/
```

### Permission Denied Errors

**Problem**: Cannot write to `/sys/module/maccel/parameters/` or `/dev/maccel`.

**Solutions**:
```bash
# Verify you're in the maccel group
groups | grep maccel

# If not in the group, add yourself
sudo usermod -aG maccel $USER

# Log out and log back in, or use
newgrp maccel

# Check udev rules are installed
ls -l /usr/lib/udev/rules.d/99-maccel.rules

# Reload udev rules
sudo udevadm control --reload-rules
sudo udevadm trigger
```

### Package Installation Fails

**Problem**: DNF cannot find the maccel package or GPG verification fails.

**Solutions**:
```bash
# Verify repository is configured
cat /etc/yum.repos.d/maccel.repo

# Check repository is enabled
sudo dnf repolist | grep maccel

# Clear DNF cache and retry
sudo dnf clean all
sudo dnf makecache

# Manually import GPG key if needed
sudo rpm --import https://raw.githubusercontent.com/abirkel/maccel-rpm/main/RPM-GPG-KEY-maccel
```

### Kernel Update Breaks Module

**Problem**: After a kernel update, maccel stops working.

**Solutions**:
```bash
# The akmod should rebuild automatically, but you can force it
sudo akmods --force --kernel $(uname -r)

# Check if the module exists for your kernel
ls -l /lib/modules/$(uname -r)/extra/maccel.ko

# Reboot if necessary
sudo reboot
```

### Checking Build Status

To check the status of package builds in this repository:

1. Visit the [Actions tab](https://github.com/abirkel/maccel-rpm/actions) on GitHub
2. Look for the latest "Build and Publish RPM Packages" workflow run
3. Check the workflow logs for any build errors
4. Verify the latest release in the [Releases section](https://github.com/abirkel/maccel-rpm/releases)

### Reporting Issues

If you encounter problems not covered here:

1. **Check upstream issues**: Many issues may be related to maccel itself, not the packaging. See [maccel issues](https://github.com/Gnarus-G/maccel/issues)
2. **Check package issues**: For packaging-specific problems, check [this repository's issues](https://github.com/abirkel/maccel-rpm/issues)
3. **Create a new issue**: Include:
   - Your Fedora version (`cat /etc/fedora-release`)
   - Kernel version (`uname -r`)
   - Package versions (`rpm -qa | grep maccel`)
   - Relevant log output
   - Steps to reproduce the problem

## Building Locally

If you want to build the RPM packages locally instead of using the pre-built packages:

### Prerequisites

```bash
# Install build dependencies
sudo dnf install rpm-build rpmdevtools rpmlint akmods kmodtool \
                 kernel-devel gcc make rust cargo git wget
```

### Build Process

```bash
# Clone this repository
git clone https://github.com/abirkel/maccel-rpm.git
cd maccel-rpm

# Set up RPM build tree
rpmdev-setuptree

# Download the maccel source (replace VERSION with desired version)
VERSION=v0.5.6
wget https://github.com/Gnarus-G/maccel/archive/${VERSION}.tar.gz \
     -O ~/rpmbuild/SOURCES/maccel-${VERSION#v}.tar.gz

# Copy spec files
cp specs/*.spec ~/rpmbuild/SPECS/

# Build the packages
cd ~/rpmbuild/SPECS
rpmbuild -ba akmod-maccel.spec
rpmbuild -ba maccel.spec

# Find built packages
ls -l ~/rpmbuild/RPMS/x86_64/
ls -l ~/rpmbuild/SRPMS/
```

### Installing Local Builds

```bash
# Install the locally built packages
sudo dnf install ~/rpmbuild/RPMS/x86_64/akmod-maccel-*.rpm
sudo dnf install ~/rpmbuild/RPMS/x86_64/maccel-*.rpm
```

## Contributing

This is a personal packaging project for maccel. Issues and pull requests are welcome.

## License

The packaging scripts and spec files in this repository are provided as-is. The maccel software itself is licensed under GPL-2.0-or-later. See the [upstream repository](https://github.com/Gnarus-G/maccel) for details.

## Upstream

- Maccel Repository: https://github.com/Gnarus-G/maccel
- Maccel Documentation: https://github.com/Gnarus-G/maccel#readme

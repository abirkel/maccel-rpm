# Troubleshooting Guide

This guide covers common issues you may encounter when installing or using maccel RPM packages.

## Kernel Module Not Loading

**Problem**: The maccel module doesn't appear in `lsmod` output.

**Solutions**:
```bash
# Check if the kmod package is installed
rpm -q kmod-maccel

# Verify the module file exists for your kernel
ls -l /lib/modules/$(uname -r)/extra/maccel/

# Manually load the module
sudo modprobe maccel

# Check kernel logs for errors
sudo dmesg | grep maccel

# If module file doesn't exist, you may need the kmod package for your kernel version
# Check available kmod packages in the repository
dnf list available kmod-maccel
```

## Permission Denied Errors

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

## Package Installation Fails

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

# If GPG verification fails, manually import the key
sudo rpm --import https://raw.githubusercontent.com/abirkel/maccel-rpm/main/RPM-GPG-KEY-maccel
```

## Kernel Update Breaks Module

**Problem**: After a kernel update, maccel stops working.

**Solutions**:
```bash
# Check if a kmod package exists for your new kernel version
KERNEL_VERSION=$(uname -r)
dnf list available "kmod-maccel-*${KERNEL_VERSION}*"

# If available, update the kmod package
sudo dnf update kmod-maccel

# If not available, the repository may not have built packages for your kernel yet
# Check the repository for available kernel versions
dnf repoquery kmod-maccel --qf "%{version}-%{release}"

# You can also check the GitHub releases page for available packages
# https://github.com/abirkel/maccel-rpm/releases

# As a temporary workaround, you can boot into your previous kernel
# and wait for the new kmod package to be built
```

**Note**: Unlike akmod packages that rebuild automatically, kmod packages are pre-compiled for specific kernel versions. When you update your kernel, you need a kmod package built for that specific kernel version. The repository automatically builds new kmod packages when kernel updates are detected, but there may be a delay.

## Checking Build Status

To check the status of package builds in this repository:

1. Visit the [Actions tab](https://github.com/abirkel/maccel-rpm/actions) on GitHub
2. Look for the latest "Build and Publish RPM Packages" workflow run
3. Check the workflow logs for any build errors
4. Verify the latest release in the [Releases section](https://github.com/abirkel/maccel-rpm/releases)

## Reporting Issues

If you encounter problems not covered here:

1. **Check upstream issues**: Many issues may be related to maccel itself, not the packaging. See [maccel issues](https://github.com/Gnarus-G/maccel/issues)
2. **Check package issues**: For packaging-specific problems, check [this repository's issues](https://github.com/abirkel/maccel-rpm/issues)
3. **Create a new issue**: Include:
   - Your Fedora version (`cat /etc/fedora-release`)
   - Kernel version (`uname -r`)
   - Package versions (`rpm -qa | grep maccel`)
   - Relevant log output
   - Steps to reproduce the problem


## Wrong Kernel Type

**Problem**: Installed kmod package doesn't match your distribution's kernel type.

**Symptoms**:
- Module file doesn't exist for your kernel version
- Package name shows different kernel version format than your system

**Solutions**:
```bash
# Check your kernel version
uname -r

# Aurora/Fedora main kernel format: 6.17.8-300.fc43.x86_64
# Bazzite kernel format: 6.17.7-ba14.fc43.x86_64

# If you're on Aurora, you need the main kernel type kmod
# If you're on Bazzite, you need the bazzite kernel type kmod

# Check what kmod packages are available
dnf repoquery kmod-maccel --qf "%{version}-%{release}"

# Install the package matching your kernel version
sudo dnf install kmod-maccel-0.5.6-1.6.17.8-300.fc43.x86_64  # For Aurora
# or
sudo dnf install kmod-maccel-0.5.6-1.6.17.7-ba14.fc43.x86_64  # For Bazzite
```

## Repository Not Building for My Kernel

**Problem**: The repository doesn't have kmod packages for your current kernel version.

**Solutions**:

1. **Check if your kernel is tracked**:
   - The repository automatically tracks Aurora and Bazzite kernel versions
   - Check `.external_versions` file in the repository to see tracked versions

2. **Wait for automatic build**:
   - The repository checks for kernel updates daily
   - New kmod packages are built automatically when kernel updates are detected
   - Check the [Actions tab](https://github.com/abirkel/maccel-rpm/actions) for build status

3. **Request a manual build**:
   - Open an issue requesting a build for your specific kernel version
   - Include your kernel version (`uname -r`) and distribution (Aurora/Bazzite)

4. **Build locally** (temporary workaround):
   - See [BUILDING.md](BUILDING.md) for instructions on building packages locally
   - You can build a kmod package for your specific kernel version

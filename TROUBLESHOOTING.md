# Troubleshooting Guide

This guide covers common issues you may encounter when installing or using maccel RPM packages.

## Kernel Module Not Loading

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
# The akmod should rebuild automatically, but you can force it
sudo akmods --force --kernel $(uname -r)

# Check if the module exists for your kernel
ls -l /lib/modules/$(uname -r)/extra/maccel.ko

# Reboot if necessary
sudo reboot
```

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

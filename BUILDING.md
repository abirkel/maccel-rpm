# Building Locally

This guide covers how to build the maccel RPM packages locally on your system.

## Container Requirements (GitHub Actions)

The automated build workflows use containers to ensure consistent builds. The workflow dynamically fetches kernel-devel packages based on the kernel type being built.

### Kernel-devel Package Sources

**Main kernel type**:
- Downloads kernel-devel from Fedora Koji repositories
- URL: `https://kojipkgs.fedoraproject.org/packages/kernel/`
- Used for Aurora and standard Fedora distributions

**Bazzite kernel type**:
- Downloads kernel-devel from Bazzite kernel repository
- Used for Bazzite gaming distribution

### Container Image Selection

The container image should have basic build tools installed. The workflow installs kernel-devel packages dynamically during the build process.

**Recommended images**:
- `ghcr.io/ublue-os/aurora:latest` - Aurora base image
- `quay.io/fedora/fedora:latest` - Standard Fedora
- `fedora:43` - Specific Fedora version

### Configuration

The container image is configured in `build.conf` at the repository root:

```bash
CONTAINER_IMAGE=ghcr.io/ublue-os/aurora
CONTAINER_VERSION=latest
DEFAULT_KERNEL_TYPE=main
```

**Configuration Options**:
- `CONTAINER_IMAGE`: Default container image for builds
- `CONTAINER_VERSION`: Container image tag/version
- `DEFAULT_KERNEL_TYPE`: Default kernel type (main or bazzite)

## Prerequisites

Install the required build dependencies:

```bash
# Install build dependencies
sudo dnf install rpm-build rpmdevtools rpmlint \
                 kernel-devel gcc make rust cargo git wget
```

## Build Process

Follow these steps to build the packages locally:

```bash
# Clone this repository
git clone https://github.com/abirkel/maccel-rpm.git
cd maccel-rpm

# Set up RPM build tree
rpmdev-setuptree

# Copy spec files
cp specs/*.spec ~/rpmbuild/SPECS/
cd ~/rpmbuild/SPECS

# Set version variables
MACCEL_VERSION="0.5.6"  # Without 'v' prefix
KERNEL_VERSION=$(uname -r)
RELEASE_NUMBER="1"

# Download the maccel source
spectool -g -R maccel-kmod.spec
spectool -g -R maccel.spec

# Build the kmod package
rpmbuild --define "kernel_version ${KERNEL_VERSION}" \
         --define "version ${MACCEL_VERSION}" \
         --define "release ${RELEASE_NUMBER}" \
         -ba maccel-kmod.spec

# Build the CLI package
rpmbuild --define "version ${MACCEL_VERSION}" \
         --define "release ${RELEASE_NUMBER}" \
         -ba maccel.spec

# Find built packages
ls -l ~/rpmbuild/RPMS/x86_64/
ls -l ~/rpmbuild/SRPMS/
```

**Note**: The spec files use RPM macros for version and release numbers. You must pass these values via `--define` parameters to rpmbuild.

### Building for Different Kernel Versions

To build kmod packages for a specific kernel version:

```bash
# Install kernel-devel for target kernel
sudo dnf install kernel-devel-6.17.8-300.fc43.x86_64

# Set the kernel version
KERNEL_VERSION="6.17.8-300.fc43.x86_64"
MACCEL_VERSION="0.5.6"
RELEASE_NUMBER="1"

# Build kmod for that kernel
rpmbuild --define "kernel_version ${KERNEL_VERSION}" \
         --define "version ${MACCEL_VERSION}" \
         --define "release ${RELEASE_NUMBER}" \
         -ba ~/rpmbuild/SPECS/maccel-kmod.spec

# Find built kmod packages
ls -l ~/rpmbuild/RPMS/x86_64/kmod-maccel*
```

**Package Naming**: The kmod package will be named `kmod-maccel-{version}-{release}.{kernel_version}.rpm`, ensuring it's specific to that kernel version.

## Installing Local Builds

Once the packages are built, you can install them:

```bash
# Install the locally built packages
sudo dnf install ~/rpmbuild/RPMS/x86_64/kmod-maccel-*.rpm
sudo dnf install ~/rpmbuild/RPMS/x86_64/maccel-*.rpm
```

## Modifying the Spec Files

The spec files are located in the `specs/` directory:

- `specs/maccel-kmod.spec` - Kernel module package
- `specs/maccel.spec` - CLI tool package

The spec files use RPM macros for version and release numbers:
```spec
Version:        %{?version}%{!?version:0.5.6}
Release:        %{?release}%{!?release:1}%{?dist}
```

After making changes to the spec files, copy them to your RPM build tree and rebuild with appropriate macros:

```bash
cp specs/*.spec ~/rpmbuild/SPECS/
cd ~/rpmbuild/SPECS

# Build with version/release macros
rpmbuild --define "version 0.5.6" \
         --define "release 1" \
         --define "kernel_version $(uname -r)" \
         -ba maccel-kmod.spec

rpmbuild --define "version 0.5.6" \
         --define "release 1" \
         -ba maccel.spec
```

## Linting

Before committing changes, lint the spec files:

```bash
rpmlint specs/*.spec
```

## Troubleshooting

### Build Failures

**Missing kernel-devel**
```bash
# Install kernel-devel for your kernel
sudo dnf install kernel-devel-$(uname -r)

# Or for a specific kernel version
sudo dnf install kernel-devel-6.17.8-300.fc43.x86_64

# Check available kernel-devel versions
dnf list available kernel-devel
```

**RPM macro errors**
```bash
# Ensure you're passing all required macros
rpmbuild --define "kernel_version $(uname -r)" \
         --define "version 0.5.6" \
         --define "release 1" \
         -ba maccel-kmod.spec

# Check spec file for required macros
grep -E "%(version|release|kernel_version)" specs/maccel-kmod.spec
```

**Compilation errors**
```bash
# Check build logs
less ~/rpmbuild/BUILD/maccel-*/build.log

# Verify kernel-devel matches your kernel
rpm -q kernel-devel

# Ensure build dependencies are installed
sudo dnf builddep specs/maccel-kmod.spec
```

**Module fails to load after installation**
```bash
# Check if module was built
ls -la /lib/modules/$(uname -r)/extra/maccel/

# Try loading manually with verbose output
sudo modprobe -v maccel

# Check kernel logs for errors
sudo dmesg | grep maccel

# Verify module signature (if secure boot enabled)
modinfo maccel | grep signature
```

### Version Mismatch Issues

**kmod package doesn't match running kernel**
```bash
# Check your kernel version
uname -r

# Build kmod for your specific kernel
KERNEL_VERSION=$(uname -r)
rpmbuild --define "kernel_version ${KERNEL_VERSION}" \
         --define "version 0.5.6" \
         --define "release 1" \
         -ba maccel-kmod.spec

# Install the matching package
sudo dnf install ~/rpmbuild/RPMS/x86_64/kmod-maccel-*$(uname -r)*.rpm
```


## GitHub Actions Secrets

The automated build workflow requires the following secrets to be configured in your GitHub repository settings:

### Required Secrets

- **`GPG_PRIVATE_KEY`**: Base64-encoded GPG private key for signing RPM packages
  - Generate with: `gpg --export-secret-key --armor <KEY_ID> | base64 -w0`
  - Store the base64 output as this secret

- **`GPG_PASSPHRASE`**: Passphrase for the GPG private key

- **`GPG_KEY_ID`**: The GPG key ID used for signing (e.g., `1234567890ABCDEF`)

### Setting Up Secrets

1. Go to your repository on GitHub
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add each secret with the name and value listed above

### Verifying Signed Packages

Users can verify the authenticity of published packages using:

```bash
# Import the public key
rpm --import https://raw.githubusercontent.com/<owner>/<repo>/main/RPM-GPG-KEY-maccel

# Verify a package
rpm -K ~/rpmbuild/RPMS/x86_64/maccel-*.rpm
```

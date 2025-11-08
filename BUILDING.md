# Building Locally

This guide covers how to build the maccel RPM packages locally on your system.

## Container Requirements (GitHub Actions)

The automated build workflows use containers to ensure consistent builds. **Important**: kmod builds require a full OS container with kernel development tools installed.

### Why Full OS Images are Required for kmod

This workflow is designed to build kmod packages for uBlue atomic images against the kernel-devel packages installed in those images. uBlue images often ship with kernels slightly behind Fedora main, and the corresponding kernel-devel packages are no longer available in the standard Fedora repositories. The only way to get these older kernel-devel packages is from the images themselves.

**Current Limitation**: The workflow does not yet support building kmod against the latest Fedora kernel from repositories. It only builds against the kernel-devel found in the container image.

### Container Image Selection

**For kmod builds** (building pre-compiled kernel modules):
- **Required**: Full OS container with kernel-devel installed
- **Recommended**: `ghcr.io/ublue-os/aurora-nvidia-open` (uBlue Aurora with kernel-devel)
- **Why**: Contains the kernel-devel package matching the image's kernel version
- **Not suitable**: Minimal containers like `fedora:minimal` (missing kernel-devel)

**For akmod + CLI only** (no kmod):
- **Flexible**: Can use smaller Fedora tooling images
- **Example**: `fedora:latest` or `fedora:40`
- **Benefit**: Faster builds, smaller image size
- **Note**: akmod packages are kernel-agnostic and rebuild on user systems

### Configuration

The container image is configured in `build.conf` at the repository root:

```bash
# For kmod builds (requires full OS with kernel-devel)
CONTAINER_IMAGE=ghcr.io/ublue-os/aurora-nvidia-open
CONTAINER_VERSION=latest
ENABLE_KMOD=true

# For akmod + CLI only (can use minimal image)
# CONTAINER_IMAGE=fedora
# CONTAINER_VERSION=latest
# ENABLE_KMOD=false
```

To disable kmod builds entirely and use a smaller image, set `ENABLE_KMOD=false`.

## Prerequisites

Install the required build dependencies:

```bash
# Install build dependencies
sudo dnf install rpm-build rpmdevtools rpmlint akmods kmodtool \
                 kernel-devel gcc make rust cargo git wget
```

## Build Process

Follow these steps to build the packages:

```bash
# Clone this repository
git clone https://github.com/abirkel/maccel-rpm.git
cd maccel-rpm

# Set up RPM build tree
rpmdev-setuptree

# Copy spec files to see what version they specify
cp specs/*.spec ~/rpmbuild/SPECS/
cd ~/rpmbuild/SPECS

# Check the version in the spec file
grep "^Version:" maccel.spec

# Download the maccel source (spectool reads from spec file)
spectool -g -R akmod-maccel.spec
spectool -g -R maccel.spec

# Build the packages
rpmbuild -ba akmod-maccel.spec
rpmbuild -ba maccel.spec

# Find built packages
ls -l ~/rpmbuild/RPMS/x86_64/
ls -l ~/rpmbuild/SRPMS/
```

**Note**: The spec files contain the version to build. To build a different version, edit the `Version:` field in the spec files before running spectool and rpmbuild.

## Installing Local Builds

Once the packages are built, you can install them:

```bash
# Install the locally built packages
sudo dnf install ~/rpmbuild/RPMS/x86_64/akmod-maccel-*.rpm
sudo dnf install ~/rpmbuild/RPMS/x86_64/maccel-*.rpm
```

## Modifying the Spec Files

The spec files are located in the `specs/` directory:

- `specs/akmod-maccel.spec` - Kernel module package
- `specs/maccel.spec` - CLI tool package

After making changes to the spec files, copy them to your RPM build tree and rebuild:

```bash
cp specs/*.spec ~/rpmbuild/SPECS/
cd ~/rpmbuild/SPECS
rpmbuild -ba akmod-maccel.spec
rpmbuild -ba maccel.spec
```

## Linting

Before committing changes, lint the spec files:

```bash
rpmlint specs/*.spec
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

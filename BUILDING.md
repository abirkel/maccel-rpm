# Building Locally

This guide covers how to build the maccel RPM packages locally on your system.

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

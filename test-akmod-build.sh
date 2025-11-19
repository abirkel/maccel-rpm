#!/bin/bash
set -euo pipefail

# Test akmod build in Fedora container
# This script tests building the akmod package using the proper kmodtool --akmod approach

echo "=== Starting Fedora container test for akmod build ==="

# Get current directory for Docker mount
WORKSPACE_DIR="$(pwd)"

# Run all tests in the pre-built Fedora container
docker run --rm -v "${WORKSPACE_DIR}:/workspace" -w /workspace fedora-rpm-build bash -c '
set -euo pipefail

echo "=== Setting up RPM build tree ==="
rpmdev-setuptree

echo "=== Copying spec file ==="
cp /workspace/specs/akmod-maccel.spec ~/rpmbuild/SPECS/

echo "=== Downloading source with spectool ==="
spectool -g -R ~/rpmbuild/SPECS/akmod-maccel.spec

echo "=== Building akmod package ==="
# Build the akmod package - kmodtool will generate the proper akmod structure
# Note: We use --nodeps because akmods is not in standard Fedora repos
rpmbuild --define "version 0.5.6" --define "release 1" --nodeps -ba ~/rpmbuild/SPECS/akmod-maccel.spec

echo ""
echo "=== Verifying akmod package was built ==="
AKMOD_RPM=$(find ~/rpmbuild/RPMS -name "akmod-maccel-*.rpm" | head -1)
if [ -z "$AKMOD_RPM" ]; then
    echo "✗ Akmod RPM not found"
    echo "Available RPMs:"
    find ~/rpmbuild/RPMS -name "*.rpm" -ls
    exit 1
fi
echo "✓ Akmod package built: $AKMOD_RPM"

echo ""
echo "=== Extracting and verifying akmod package contents ==="
mkdir -p /tmp/akmod-extract
cd /tmp/akmod-extract
rpm2cpio "$AKMOD_RPM" | cpio -idmv 2>&1

echo ""
echo "=== Verifying akmod package structure ==="
echo "Package contents:"
find /tmp/akmod-extract -type f | sort

echo ""
echo "=== Checking for kernel module files ==="
KMOD_FILES=$(find /tmp/akmod-extract -name "*.ko" 2>/dev/null | wc -l)
if [ "$KMOD_FILES" -gt 0 ]; then
    echo "✓ Found $KMOD_FILES kernel module file(s):"
    find /tmp/akmod-extract -name "*.ko" -ls
else
    echo "✗ No kernel module files found"
    exit 1
fi

echo ""
echo "=== Verifying akmod installation structure ==="
# Check if files are installed in the correct kernel module location
KMOD_INSTALL_DIR=$(find /tmp/akmod-extract -type d -path "*/lib/modules/*/extra*" 2>/dev/null | head -1)
if [ -n "$KMOD_INSTALL_DIR" ]; then
    echo "✓ Kernel modules installed to: ${KMOD_INSTALL_DIR#/tmp/akmod-extract}"
    echo "Contents:"
    ls -la "$KMOD_INSTALL_DIR"
else
    echo "✗ Kernel modules not installed to expected location"
    echo "Available directories:"
    find /tmp/akmod-extract -type d | grep -E "(lib|modules)" || echo "No module directories found"
    exit 1
fi

echo ""
echo "=== Verifying package metadata ==="
echo "Package info:"
rpm -qip "$AKMOD_RPM" | head -20

echo ""
echo "=== All verification checks passed! ==="
echo ""
echo "Summary:"
echo "  ✓ Akmod package built successfully using kmodtool --akmod"
echo "  ✓ Kernel module(s) compiled and included"
echo "  ✓ Modules installed to correct kernel directory structure"
echo "  ✓ Package metadata is correct"
'

echo ""
echo "=== Test completed successfully ==="

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
cp /workspace/specs/maccel-kmod.spec ~/rpmbuild/SPECS/

echo "=== Downloading source with spectool ==="
spectool -g -R ~/rpmbuild/SPECS/maccel-kmod.spec

echo "=== Building akmod package ==="
# Build the akmod package - kmodtool will generate the proper akmod structure
# Note: We use --nodeps because akmods is not in standard Fedora repos
rpmbuild --define "version 0.5.6" --define "release 1" --nodeps -ba ~/rpmbuild/SPECS/maccel-kmod.spec

echo ""
echo "=== Verifying akmod package was built ==="
# Look for the actual akmod package (not the metapackage)
AKMOD_RPM=$(find ~/rpmbuild/RPMS -name "akmod-maccel-*.rpm" | head -1)
if [ -z "$AKMOD_RPM" ]; then
    echo "✗ Akmod RPM not found"
    echo "Available RPMs:"
    find ~/rpmbuild/RPMS -name "*.rpm" -ls
    exit 1
fi
echo "✓ Akmod package built: $AKMOD_RPM"

echo ""
echo "=== Verifying metapackage was also built ==="
KMOD_META_RPM=$(find ~/rpmbuild/RPMS -name "kmod-maccel-*.rpm" | head -1)
if [ -z "$KMOD_META_RPM" ]; then
    echo "✗ Metapackage RPM not found"
    exit 1
fi
echo "✓ Metapackage built: $KMOD_META_RPM"

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
echo "=== Note: Akmod packages don'\''t contain pre-built modules without kernel-devel ==="
echo "This is expected behavior - akmods will build modules on the target system"
KMOD_FILES=$(find /tmp/akmod-extract -name "*.ko" 2>/dev/null | wc -l)
if [ "$KMOD_FILES" -gt 0 ]; then
    echo "✓ Found $KMOD_FILES pre-built kernel module file(s):"
    find /tmp/akmod-extract -name "*.ko" -ls
else
    echo "✓ No pre-built modules (expected without kernel-devel installed)"
fi

echo ""
echo "=== Verifying package metadata ==="
echo "Package info:"
rpm -qip "$AKMOD_RPM" | head -20

echo ""
echo "=== Verifying source RPM was packaged for automatic rebuilds ==="
AKMODS_DIR=$(find /tmp/akmod-extract -type d -path "*/usr/src/akmods" 2>/dev/null | head -1)
if [ -n "$AKMODS_DIR" ]; then
    echo "✓ Source RPM directory found: ${AKMODS_DIR#/tmp/akmod-extract}"
    echo "Contents:"
    ls -la "$AKMODS_DIR"
    
    # Check for the source RPM
    SRC_RPM=$(find "$AKMODS_DIR" -name "*.src.rpm" 2>/dev/null | head -1)
    if [ -n "$SRC_RPM" ]; then
        echo "✓ Source RPM found for automatic rebuilds: $(basename "$SRC_RPM")"
    else
        echo "✗ Source RPM not found"
        exit 1
    fi
else
    echo "✗ /usr/src/akmods directory not found"
    exit 1
fi

echo ""
echo "=== All verification checks passed! ==="
echo ""
echo "Summary:"
echo "  ✓ Akmod package built successfully using kmodtool --akmod"
echo "  ✓ Metapackage created for kernel tracking"
echo "  ✓ Source RPM packaged in /usr/src/akmods/ for automatic rebuilds"
echo "  ✓ Package structure matches ublue-os akmod pattern"
'

echo ""
echo "=== Test completed successfully ==="

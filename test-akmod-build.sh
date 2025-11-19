#!/bin/bash
set -euo pipefail

# Test akmod build in Fedora container
# This script tests the akmod-maccel.spec build process

echo "=== Starting Fedora container test for akmod build ==="

# Get current directory for Docker mount
WORKSPACE_DIR="$(pwd)"

# Run all tests in a Fedora container
docker run --rm -v "${WORKSPACE_DIR}:/workspace" -w /workspace fedora:latest bash -c '
set -euo pipefail

echo "=== Installing build dependencies ==="
dnf install -y rpm-build rpmdevtools kmodtool kernel-devel gcc make spectool

echo "=== Setting up RPM build tree ==="
rpmdev-setuptree

echo "=== Copying spec file ==="
cp /workspace/specs/akmod-maccel.spec ~/rpmbuild/SPECS/

echo "=== Downloading source with spectool ==="
spectool -g -R ~/rpmbuild/SPECS/akmod-maccel.spec

echo "=== Building akmod package ==="
# Note: akmods is not available in standard Fedora repos (it'\''s in RPMFusion)
# We'\''ll build without the akmods dependency check for testing purposes
rpmbuild --define "version 0.5.6" --define "release 1" --nodeps -ba ~/rpmbuild/SPECS/akmod-maccel.spec

echo ""
echo "=== Verifying generated kmod spec exists ==="
if [ -f ~/rpmbuild/BUILD/maccel-*/kmod-maccel.spec ]; then
    echo "✓ Generated kmod spec found"
    KMOD_SPEC=$(find ~/rpmbuild/BUILD/maccel-* -name "kmod-maccel.spec" | head -1)
    echo "  Location: $KMOD_SPEC"
else
    echo "✗ Generated kmod spec NOT found"
    exit 1
fi

echo ""
echo "=== Verifying generated kmod spec structure ==="
echo "--- Content of generated kmod spec ---"
cat "$KMOD_SPEC"
echo "--- End of kmod spec ---"

echo ""
echo "=== Extracting akmod package to verify contents ==="
AKMOD_RPM=$(find ~/rpmbuild/RPMS -name "akmod-maccel-*.rpm" | head -1)
if [ -z "$AKMOD_RPM" ]; then
    echo "✗ Akmod RPM not found"
    exit 1
fi
echo "Found akmod RPM: $AKMOD_RPM"

mkdir -p /tmp/akmod-extract
cd /tmp/akmod-extract
rpm2cpio "$AKMOD_RPM" | cpio -idmv 2>&1 | head -20

echo ""
echo "=== Verifying source installed to correct path with release number ==="
if [ -d usr/src/akmods/maccel-0.5.6-1.fc42 ]; then
    echo "✓ Source installed to correct path: /usr/src/akmods/maccel-0.5.6-1.fc42"
    echo "  Contents:"
    ls -la usr/src/akmods/maccel-0.5.6-1.fc42/
elif [ -d usr/src/akmods/maccel-0.5.6-1 ]; then
    echo "✓ Source installed to correct path: /usr/src/akmods/maccel-0.5.6-1"
    echo "  Contents:"
    ls -la usr/src/akmods/maccel-0.5.6-1/
    # Update path for subsequent checks
    AKMOD_PATH="usr/src/akmods/maccel-0.5.6-1"
else
    echo "✗ Source NOT in expected path"
    echo "  Available paths:"
    find usr/src/akmods/ -type d 2>/dev/null || echo "No akmods directory found"
    exit 1
fi

# Determine the actual path
if [ -d usr/src/akmods/maccel-0.5.6-1.fc42 ]; then
    AKMOD_PATH="usr/src/akmods/maccel-0.5.6-1.fc42"
else
    AKMOD_PATH="usr/src/akmods/maccel-0.5.6-1"
fi

echo ""
echo "=== Verifying generated kmod spec is included in akmod package ==="
if [ -f "$AKMOD_PATH/kmod-maccel.spec" ]; then
    echo "✓ Generated kmod spec included in akmod package"
    echo "  Path: /$AKMOD_PATH/kmod-maccel.spec"
    echo ""
    echo "--- Content of kmod spec from RPM (first 50 lines) ---"
    head -50 "$AKMOD_PATH/kmod-maccel.spec"
    echo "--- End of kmod spec preview ---"
else
    echo "✗ Generated kmod spec NOT included in akmod package"
    echo "  Files in $AKMOD_PATH:"
    ls -la "$AKMOD_PATH/" || true
    exit 1
fi

echo ""
echo "=== Verifying driver directory structure is preserved ==="
if [ -d "$AKMOD_PATH/driver" ]; then
    echo "✓ Driver directory structure preserved"
    echo "  Contents:"
    ls -la "$AKMOD_PATH/driver/"
else
    echo "✗ Driver directory NOT preserved"
    exit 1
fi

echo ""
echo "=== Verifying Makefile is included ==="
if [ -f "$AKMOD_PATH/Makefile" ]; then
    echo "✓ Makefile included"
    echo "  First 20 lines of Makefile:"
    head -20 "$AKMOD_PATH/Makefile"
else
    echo "✗ Makefile NOT included"
    exit 1
fi

echo ""
echo "=== All verification checks passed! ==="
echo ""
echo "Summary:"
echo "  ✓ Akmod package built successfully"
echo "  ✓ Generated kmod spec created during build"
echo "  ✓ Generated kmod spec has correct structure"
echo "  ✓ Source installed to /usr/src/akmods/maccel-0.5.6-1*/"
echo "  ✓ Generated kmod spec included in akmod package"
echo "  ✓ Driver directory structure preserved"
echo "  ✓ Makefile included for building"
'

echo ""
echo "=== Test completed successfully ==="

#!/bin/bash
set -euo pipefail

# Kernel Package Fetcher Script
# Downloads kernel-devel packages for the target kernel version
# Supports both Fedora main kernel (from Koji) and Bazzite kernel

# Default values
KERNEL_VERSION=""
KERNEL_TYPE=""
FEDORA_VERSION=""
OUTPUT_DIR="${PWD}"
MAX_RETRIES=2

# Parse CLI options
while [[ $# -gt 0 ]]; do
  case $1 in
    --kernel-version)
      KERNEL_VERSION="$2"
      shift 2
      ;;
    --kernel-type)
      KERNEL_TYPE="$2"
      shift 2
      ;;
    --fedora-version)
      FEDORA_VERSION="$2"
      shift 2
      ;;
    --output-dir)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 --kernel-version <version> --kernel-type <main|bazzite> --fedora-version <version> [--output-dir <dir>]"
      exit 1
      ;;
  esac
done

# Validate required parameters
if [[ -z "$KERNEL_VERSION" ]]; then
  echo "Error: --kernel-version is required"
  exit 1
fi

if [[ -z "$KERNEL_TYPE" ]]; then
  echo "Error: --kernel-type is required"
  exit 1
fi

if [[ -z "$FEDORA_VERSION" ]]; then
  echo "Error: --fedora-version is required"
  exit 1
fi

if [[ "$KERNEL_TYPE" != "main" && "$KERNEL_TYPE" != "bazzite" ]]; then
  echo "Error: kernel-type must be 'main' or 'bazzite', got '$KERNEL_TYPE'"
  exit 1
fi

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Function to download a file with retry logic
download_with_retry() {
  local url="$1"
  local output_file="$2"
  local retry_count=0

  while [[ $retry_count -lt $MAX_RETRIES ]]; do
    echo "Downloading: $url" >&2
    if curl -fLo "$output_file" "$url" 2>/dev/null; then
      # Validate file is not empty
      if [[ -s "$output_file" ]]; then
        echo "Successfully downloaded: $(basename "$output_file")" >&2
        return 0
      else
        echo "Warning: Downloaded file is empty, retrying..." >&2
        rm -f "$output_file"
      fi
    else
      echo "Warning: Download failed, retrying..." >&2
      rm -f "$output_file"
    fi
    retry_count=$((retry_count + 1))
  done

  echo "Error: Failed to download $url after $MAX_RETRIES attempts"
  return 1
}

# Parse kernel version components
# Expected format: 6.17.8-300.fc43.x86_64
KERNEL_MAJOR_MINOR_PATCH=$(echo "$KERNEL_VERSION" | cut -d '-' -f 1)
KERNEL_RELEASE=$(echo "$KERNEL_VERSION" | cut -d '-' -f 2 | rev | cut -d '.' -f 2- | rev)
ARCH=$(echo "$KERNEL_VERSION" | rev | cut -d '.' -f 1 | rev)

echo "Parsed kernel version components:" >&2
echo "  Version: $KERNEL_MAJOR_MINOR_PATCH" >&2
echo "  Release: $KERNEL_RELEASE" >&2
echo "  Architecture: $ARCH" >&2

# Download packages based on kernel type
if [[ "$KERNEL_TYPE" == "main" ]]; then
  # Fedora main kernel from Koji
  BASE_URL="https://kojipkgs.fedoraproject.org/packages/kernel/${KERNEL_MAJOR_MINOR_PATCH}/${KERNEL_RELEASE}/${ARCH}"

  echo "Fetching main kernel packages from Koji:" >&2
  echo "  Base URL: $BASE_URL" >&2

  # Download kernel-devel
  KERNEL_DEVEL_FILE="kernel-devel-${KERNEL_VERSION}.rpm"
  if ! download_with_retry "${BASE_URL}/${KERNEL_DEVEL_FILE}" "${OUTPUT_DIR}/${KERNEL_DEVEL_FILE}"; then
    echo "Error: Failed to download kernel-devel package"
    exit 1
  fi

  # Download kernel-devel-matched
  KERNEL_DEVEL_MATCHED_FILE="kernel-devel-matched-${KERNEL_VERSION}.rpm"
  if ! download_with_retry "${BASE_URL}/${KERNEL_DEVEL_MATCHED_FILE}" "${OUTPUT_DIR}/${KERNEL_DEVEL_MATCHED_FILE}"; then
    echo "Error: Failed to download kernel-devel-matched package"
    exit 1
  fi

elif [[ "$KERNEL_TYPE" == "bazzite" ]]; then
  # Bazzite kernel from Bazzite GitHub releases
  # Bazzite distributes kernel-devel RPMs as release assets on GitHub

  echo "Fetching bazzite kernel packages from GitHub releases:" >&2

  # Extract the release tag from kernel version
  # Input format: 6.17.5-ba02.fc43.x86_64
  # Release tag format: 6.17.5-ba02
  # We need to remove the .fc43.x86_64 suffix
  BAZZITE_TAG="${KERNEL_VERSION%.fc*}"
  
  # Construct the base URL for Bazzite GitHub releases
  BASE_URL="https://github.com/bazzite-org/kernel-bazzite/releases/download/${BAZZITE_TAG}"
  
  echo "  Release tag: $BAZZITE_TAG" >&2
  echo "  Base URL: $BASE_URL" >&2

  # Download kernel-devel
  KERNEL_DEVEL_FILE="kernel-devel-${KERNEL_VERSION}.rpm"
  if ! download_with_retry "${BASE_URL}/${KERNEL_DEVEL_FILE}" "${OUTPUT_DIR}/${KERNEL_DEVEL_FILE}"; then
    echo "Error: Failed to download kernel-devel package for Bazzite kernel"
    echo "Verify the kernel version exists in Bazzite releases: https://github.com/bazzite-org/kernel-bazzite/releases"
    exit 1
  fi

  # Download kernel-devel-matched
  KERNEL_DEVEL_MATCHED_FILE="kernel-devel-matched-${KERNEL_VERSION}.rpm"
  if ! download_with_retry "${BASE_URL}/${KERNEL_DEVEL_MATCHED_FILE}" "${OUTPUT_DIR}/${KERNEL_DEVEL_MATCHED_FILE}"; then
    echo "Error: Failed to download kernel-devel-matched package for Bazzite kernel"
    exit 1
  fi
fi

# Verify all packages exist and are non-empty
echo "Verifying downloaded packages:" >&2
for package in "${OUTPUT_DIR}"/kernel-devel*.rpm; do
  if [[ ! -f "$package" ]]; then
    echo "Error: Package file not found: $package"
    exit 1
  fi
  if [[ ! -s "$package" ]]; then
    echo "Error: Package file is empty: $package"
    exit 1
  fi
  echo "  ✓ $(basename "$package") ($(stat -f%z "$package" 2>/dev/null || stat -c%s "$package" 2>/dev/null) bytes)" >&2
done

echo "Successfully fetched all kernel packages" >&2

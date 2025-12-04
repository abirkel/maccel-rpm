#!/bin/bash
set -euo pipefail

# CLI Release Number Determination Script
# Queries GitHub releases to determine the next CLI release number
# Implements increment logic: same version → increment, new version → 1

# Default values
MACCEL_VERSION=""
RELEASE_TYPE="stable"
GITHUB_REPO="abirkel/maccel-rpm"

# Parse CLI options
while [[ $# -gt 0 ]]; do
  case $1 in
    --maccel-version)
      MACCEL_VERSION="$2"
      shift 2
      ;;
    --release-type)
      RELEASE_TYPE="$2"
      shift 2
      ;;
    --repo)
      GITHUB_REPO="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 --maccel-version <version> [--release-type <stable|testing>] [--repo <owner/repo>]"
      exit 1
      ;;
  esac
done

# Validate required parameters
if [[ -z "$MACCEL_VERSION" ]]; then
  echo "Error: --maccel-version is required"
  exit 1
fi

if [[ "$RELEASE_TYPE" != "stable" && "$RELEASE_TYPE" != "testing" ]]; then
  echo "Error: release-type must be 'stable' or 'testing', got '$RELEASE_TYPE'"
  exit 1
fi

# Strip 'v' prefix from maccel version if present
MACCEL_VERSION="${MACCEL_VERSION#v}"

echo "Determining CLI release number for:" >&2
echo "  Maccel version: $MACCEL_VERSION" >&2
echo "  Release type: $RELEASE_TYPE" >&2
echo "  Repository: $GITHUB_REPO" >&2

# Query GitHub releases API
echo "Querying GitHub releases..." >&2

# Use gh CLI if available, otherwise fall back to curl
if command -v gh &> /dev/null; then
  if ! RELEASES_JSON=$(gh api "repos/${GITHUB_REPO}/releases" --paginate 2>&1); then
    echo "Error: Failed to query GitHub releases API using gh CLI" >&2
    echo "API response: $RELEASES_JSON" >&2
    echo "Check repository access and authentication" >&2
    exit 1
  fi
else
  # Fall back to curl with GitHub API
  if ! RELEASES_JSON=$(curl -fsSL "https://api.github.com/repos/${GITHUB_REPO}/releases?per_page=100" 2>&1); then
    echo "Error: Failed to query GitHub releases API" >&2
    echo "API response: $RELEASES_JSON" >&2
    echo "Install gh CLI for better API access: https://cli.github.com/" >&2
    exit 1
  fi
fi

# Check if we got any releases
if [[ -z "$RELEASES_JSON" ]] || [[ "$RELEASES_JSON" == "[]" ]]; then
  echo "No existing releases found, using release number 1" >&2
  echo "1"
  exit 0
fi

# Extract all asset names from releases
if ! ASSET_NAMES=$(echo "$RELEASES_JSON" | jq -r '.[].assets[].name' 2>&1); then
  echo "Error: Failed to parse releases JSON" >&2
  echo "jq error: $ASSET_NAMES" >&2
  echo "Ensure jq is installed and the API response is valid JSON" >&2
  exit 1
fi

if [[ -z "$ASSET_NAMES" ]]; then
  echo "No release assets found, using release number 1" >&2
  echo "1"
  exit 0
fi

# Look for CLI packages matching our version
# Package naming pattern: maccel-VERSION-RELEASE.fc43.x86_64.rpm
# Example: maccel-0.5.6-1.fc43.x86_64.rpm

echo "Searching for existing CLI packages..." >&2

# Escape dots in version strings for regex
MACCEL_VERSION_ESCAPED="${MACCEL_VERSION//./\\.}"

# Find matching packages and extract release numbers
# Pattern: maccel-VERSION-RELEASE.fc43.x86_64.rpm (not kmod-maccel)
MATCHING_PACKAGES=$(echo "$ASSET_NAMES" | grep -E "^maccel-${MACCEL_VERSION_ESCAPED}-[0-9]+\.fc[0-9]+\.x86_64\.rpm$" || true)

# Further filter by release type by checking release names
if [[ -n "$MATCHING_PACKAGES" ]]; then
  # Get release names from the API response
  RELEASE_NAMES=$(echo "$RELEASES_JSON" | jq -r '.[].name' 2>&1)
  
  # Filter releases by type (e.g., v0.5.6-stable or v0.5.6-testing)
  FILTERED_RELEASES=$(echo "$RELEASE_NAMES" | grep -E "\-${RELEASE_TYPE}$" || true)
  
  if [[ -n "$FILTERED_RELEASES" ]]; then
    # Extract asset names from filtered releases only
    MATCHING_PACKAGES=$(echo "$RELEASES_JSON" | jq -r ".[] | select(.name | test(\"-${RELEASE_TYPE}$\")) | .assets[].name" | grep -E "^maccel-${MACCEL_VERSION_ESCAPED}-[0-9]+\.fc[0-9]+\.x86_64\.rpm$" || true)
  else
    MATCHING_PACKAGES=""
  fi
fi

if [[ -z "$MATCHING_PACKAGES" ]]; then
  echo "No matching CLI packages found for version $MACCEL_VERSION" >&2
  echo "Using release number 1" >&2
  echo "1"
  exit 0
fi

echo "Found matching CLI packages:" >&2
while IFS= read -r pkg; do
  echo "  $pkg" >&2
done <<< "$MATCHING_PACKAGES"

# Extract release numbers from matching packages
# Pattern: maccel-VERSION-RELEASE.fc43.x86_64.rpm
# We need to extract RELEASE (the number between VERSION- and .fc43)
RELEASE_NUMBERS=$(echo "$MATCHING_PACKAGES" | sed -E "s/^maccel-${MACCEL_VERSION_ESCAPED}-([0-9]+)\.fc[0-9]+\.x86_64\.rpm$/\1/")

# Find the highest release number
MAX_RELEASE=0
while IFS= read -r release; do
  if [[ -n "$release" ]] && [[ "$release" =~ ^[0-9]+$ ]]; then
    if [[ "$release" -gt "$MAX_RELEASE" ]]; then
      MAX_RELEASE="$release"
    fi
  fi
done <<< "$RELEASE_NUMBERS"

# Increment the release number
NEXT_RELEASE=$((MAX_RELEASE + 1))

echo "Highest existing CLI release: $MAX_RELEASE" >&2
echo "Next CLI release number: $NEXT_RELEASE" >&2

echo "$NEXT_RELEASE"

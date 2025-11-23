# Implementation Plan

- [x] 1. Update spec files to use RPM macros




  - Modify maccel-kmod.spec to use %{?version} and %{?release} macros
  - Modify maccel.spec to use %{?version} and %{?release} macros
  - Remove hardcoded version and release numbers
  - Test that specs work with --define parameters
  - _Requirements: 5.1_

- [x] 2. Create kernel version resolution script




  - Create scripts/resolve-kernel-version.sh
  - Implement skopeo inspection for Aurora image
  - Implement skopeo inspection for Bazzite image
  - Extract ostree.linux label from image metadata
  - Parse kernel version components (major.minor.patch, release, arch)
  - Add error handling for missing labels or invalid formats
  - _Requirements: 3.1, 3.3, 3.4_

- [ ]* 2.1 Write property test for kernel version parsing
  - **Property 1: Kernel-devel version matching**
  - **Validates: Requirements 1.2**

- [ ]* 2.2 Write unit tests for version resolution
  - Test Aurora image inspection
  - Test Bazzite image inspection
  - Test version parsing for various formats
  - Test error handling for invalid versions
  - _Requirements: 3.3, 3.4_

- [x] 3. Create kernel package fetcher script








  - Create scripts/fetch-kernel-packages.sh
  - Implement Koji URL construction for main kernel type
  - Implement Bazzite repository URL construction for bazzite kernel type
  - Download kernel-devel and kernel-devel-matched packages
  - Validate downloaded packages exist and are non-zero size
  - Add retry logic for failed downloads
  - _Requirements: 2.2, 2.3, 2.4, 3.5_

- [ ]* 3.1 Write property test for URL construction
  - **Property 4: Kernel package source routing**
  - **Validates: Requirements 2.2, 2.3, 2.4**

- [ ]* 3.2 Write unit tests for package fetching
  - Test Koji URL construction with various kernel versions
  - Test Bazzite URL construction
  - Test download validation
  - Test error handling for 404 responses
  - _Requirements: 2.2, 2.3, 2.4, 3.5_

- [x] 4. Create release number determination script






  - Create scripts/determine-release-number.sh
  - Query GitHub releases API for existing packages
  - Parse package names to extract version and release numbers
  - Implement increment logic (same version → increment, new version → 1)
  - Handle case of no existing packages (return 1)
  - _Requirements: 5.2, 5.3, 5.5_

- [ ]* 4.1 Write property test for release number logic
  - **Property 9: Release number increment logic**
  - **Validates: Requirements 5.2, 5.3**

- [ ]* 4.2 Write unit tests for release determination
  - Test with no existing packages
  - Test with existing package (same version)
  - Test with existing package (new version)
  - Test GitHub API error handling
  - _Requirements: 5.2, 5.3_

- [x] 5. Refactor check-release.yml workflow




  - Add kernel version detection steps (Aurora and Bazzite)
  - Compare all three versions (maccel, Aurora kernel, Bazzite kernel)
  - Determine which kernel types need building
  - Update .external_versions with all three version fields
  - Pass kernel_types parameter to build-rpm.yml
  - _Requirements: 3.1, 3.3, 3.4_

- [ ]* 5.1 Write integration test for check-release workflow
  - Test detection of new maccel version
  - Test detection of new Aurora kernel
  - Test detection of new Bazzite kernel
  - Test .external_versions update
  - _Requirements: 3.1, 3.3, 3.4_
-

- [x] 6. Refactor build-rpm.yml workflow structure




  - Add resolve-versions job to determine kernel versions
  - Add load-config job (keep existing)
  - Remove update-specs job (no longer needed)
  - Update workflow inputs to include kernel_type and kernel_version
  - _Requirements: 2.1, 3.2, 4.1, 4.3_

- [x] 7. Implement matrix build strategy




  - Create matrix strategy with kernel_type dimension
  - Add dynamic matrix generation based on kernel_types input
  - Configure main matrix job to build CLI, bazzite to skip CLI
  - Set up proper matrix job dependencies
  - _Requirements: 2.1, 6.1, 6.5_

- [ ]* 7.1 Write property test for matrix configuration
  - **Property 12: Package separation**
  - **Validates: Requirements 6.5**

- [x] 8. Update build-rpm job for matrix execution




  - Fetch kernel-devel packages using fetch-kernel-packages.sh script
  - Install kernel-devel for target kernel version
  - Determine release number using determine-release-number.sh script
  - Build kmod with kernel_version, version, and release macros
  - Conditionally build CLI based on matrix configuration
  - Upload artifacts with kernel-type-specific names
  - _Requirements: 1.1, 1.2, 1.3, 2.5, 6.2, 6.3_

- [ ]* 8.1 Write property test for kmod naming
  - **Property 2: Kmod package naming convention**
  - **Validates: Requirements 1.3**

- [ ]* 8.2 Write property test for CLI independence
  - **Property 11: CLI kernel-devel independence**
  - **Validates: Requirements 6.3**

- [ ]* 8.3 Write unit tests for build steps
  - Test kernel-devel installation
  - Test release number determination
  - Test rpmbuild with macros
  - Test artifact naming
  - _Requirements: 1.1, 1.2, 1.3, 6.2_

- [x] 9. Implement publish job



  - Download all matrix job artifacts
  - Merge artifacts into single directory
  - Sign all RPM packages
  - Create/update GitHub release with all packages (including preexisting releases)
  - Regenerate repository metadata with createrepo_c
  - Deploy to GitHub Pages
  - _Requirements: 1.4, 6.4_

- [ ]* 9.1 Write property test for package signing
  - **Property 3: Package signing completeness**
  - **Validates: Requirements 1.4, 6.4**

- [ ]* 9.2 Write unit tests for publish steps
  - Test artifact merging
  - Test package signing
  - Test release creation
  - Test repository metadata generation
  - _Requirements: 1.4, 6.4_

- [x] 10. Add error handling and validation





  - Add kernel-devel availability check before building
  - Add build failure detection and log capture
  - Add signing failure detection
  - Implement workflow failure propagation
  - Add clear error messages for common failures
  - _Requirements: 7.1, 7.2, 7.3, 7.4_

- [ ]* 10.1 Write property tests for error handling
  - **Property 13: Build failure propagation**
  - **Property 14: Build log capture**
  - **Validates: Requirements 7.2, 7.3, 7.4**

- [ ]* 10.2 Write unit tests for error scenarios
  - Test kernel-devel not found
  - Test RPM build failure
  - Test signing failure
  - Test error message formatting
  - _Requirements: 7.1, 7.2, 7.3, 7.4_
-

- [x] 11. Add linting and code quality checks





  - Run shellcheck on all shell scripts
  - Run yamllint on workflow files
  - Run rpmlint on spec files
  - Fix any linting errors
  - Add linting to CI workflow
  - _Requirements: 8.1, 8.2, 8.3_

- [ ]* 11.1 Write property tests for linting
  - **Property 15: Shell script linting**
  - **Property 16: YAML linting**
  - **Property 17: Spec file linting**
  - **Validates: Requirements 8.1, 8.2, 8.3**

- [x] 12. Update build.conf with defaults






  - Add DEFAULT_KERNEL_TYPE setting
  - Ensure CONTAINER_IMAGE and CONTAINER_VERSION are set
  - Document all configuration options
  - _Requirements: 4.2, 4.4_

- [x] 13. Update .external_versions file format




  - Add AURORA_KERNEL_VERSION field
  - Add BAZZITE_KERNEL_VERSION field
  - Keep MACCEL_VERSION field
  - Document file format
  - _Requirements: 3.1_

- [ ] 14. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 15. Test end-to-end workflow
  - Trigger workflow on feature branch (refactor/kmod-build-multi-kernel)
  - Use workflow_dispatch with manual inputs to force build (repo already has builds, so change detection may skip)
  - Provide explicit kernel_types input (e.g., "main", "bazzite", or "main,bazzite")
  - Provide explicit maccel_version, aurora_kernel_version, and bazzite_kernel_version inputs
  - Test scenario 1: Manually trigger with main kernel type only
  - Test scenario 2: Manually trigger with bazzite kernel type only
  - Test scenario 3: Manually trigger with both kernel types (main,bazzite)
  - Verify packages are built correctly for each kernel type
  - Verify packages are signed
  - Verify packages are uploaded to release
  - Verify repository metadata is updated
  - Note: Since repo is not clean (existing builds present), workflow may not detect changes automatically - use manual trigger with explicit version parameters to force build
  - _Requirements: 1.1, 1.3, 1.4, 2.5, 6.4_

- [ ]* 15.1 Write integration tests for full workflow
  - Test complete build for main kernel
  - Test complete build for bazzite kernel
  - Test matrix build for both kernels
  - Test package installation
  - _Requirements: 1.1, 1.3, 1.4, 2.5_




- [x] 16. Update documentation


  - Update README.md with new workflow parameters
  - Document kernel type options
  - Document manual trigger process
  - Add troubleshooting section
  - Document .external_versions format
  - _Requirements: All_

- [ ] 17. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

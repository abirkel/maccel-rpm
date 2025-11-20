# Build only the akmod package and no kernel module packages:
%define buildforkernels akmod
%global debug_package %{nil}
%global kmod_name maccel
%global pkg_kmod_name maccel-kmod

Name:           maccel-kmod
Version:        0.5.6
Release:        3%{?dist}
Summary:        Akmod package for maccel mouse acceleration kernel module
License:        GPL-2.0-or-later
URL:            https://github.com/Gnarus-G/maccel
Source0:        %{url}/archive/v%{version}/maccel-%{version}.tar.gz

BuildRequires:  kmodtool

# kmodtool does its magic here - generates the akmod package structure
%{expand:%(kmodtool --target %{_target_cpu} --kmodname %{kmod_name} --akmod 2>/dev/null) }

%description
This package provides the akmod package for the maccel mouse acceleration driver.
The akmod system automatically rebuilds the kernel module when the kernel is updated,
ensuring that maccel continues to work after kernel updates.

Maccel is a mouse acceleration driver for Linux that provides customizable mouse
acceleration curves and parameters through a kernel module and CLI tool.

%prep
# Error out if there was something wrong with kmodtool:
%{?kmodtool_check}
# Print kmodtool output for debugging purposes:
kmodtool --target %{_target_cpu} --kmodname %{kmod_name} --akmod 2>/dev/null

%autosetup -n %{kmod_name}-%{version}

# Prepare build directories for each kernel version
for kernel_version in %{?kernel_versions} ; do
  mkdir -p _kmod_build_${kernel_version%%___*}
  cp -a driver/* Makefile _kmod_build_${kernel_version%%___*}/
done

%build
# Build kernel modules for each kernel version
for kernel_version in %{?kernel_versions} ; do
  make V=1 %{?_smp_mflags} -C ${kernel_version##*___} M=${PWD}/_kmod_build_${kernel_version%%___*} modules
done

%install
# Install kernel modules for each kernel version
for kernel_version in %{?kernel_versions}; do
  mkdir -p %{buildroot}%{kmodinstdir_prefix}/${kernel_version%%___*}/%{kmodinstdir_postfix}/
  install -D -m 755 _kmod_build_${kernel_version%%___*}/%{kmod_name}.ko \
    %{buildroot}%{kmodinstdir_prefix}/${kernel_version%%___*}/%{kmodinstdir_postfix}/
  chmod a+x %{buildroot}%{kmodinstdir_prefix}/${kernel_version%%___*}/%{kmodinstdir_postfix}/%{kmod_name}.ko
done

# Install akmod source (kmodtool handles this via %akmod_install macro)
%{?akmod_install}

%changelog
* Thu Nov 20 2025 Maccel Builder <builder@maccel.local> - 0.5.6-3
- Rebuild with fixed maccel CLI package for container builds

* Thu Nov 20 2025 github-actions[bot]   <github-actions[bot]@users.noreply.github.com> - 0.5.6-2
- Rebuild for kernel compatibility
* Wed Nov 19 2025 github-actions[bot]   <github-actions[bot]@users.noreply.github.com> - 0.5.6-1
- Rebuild for kernel compatibility
* Wed Nov 19 2025 github-actions[bot]   <github-actions[bot]@users.noreply.github.com> - 0.5.6-3
- Rebuild for kernel compatibility
* Wed Nov 19 2025 github-actions[bot]   <github-actions[bot]@users.noreply.github.com> - 0.5.6-2
- Rebuild for kernel compatibility
* Tue Nov 19 2024 Maccel Builder <builder@maccel.local> - 0.5.6-1
- Initial akmod package for maccel
- Refactor to use proper kmodtool --akmod pattern following ublue-os standards

* Fri Nov 08 2024 github-actions[bot] <github-actions[bot]@users.noreply.github.com> - 0.5.5-1
- Update to maccel version 0.5.5

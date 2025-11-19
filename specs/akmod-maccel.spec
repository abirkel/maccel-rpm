# akmod-maccel.spec - Automatic kernel module package for maccel mouse acceleration driver
# This spec file builds an akmod package that automatically rebuilds the kernel module
# when the kernel is updated, using Fedora's akmods system.
#
# rpmlint validation: Passed with 2 acceptable warnings
# - no-buildroot-tag: BuildRoot is automatically managed in modern RPM
# - no-%check-section: No tests needed for source-only akmod package

%global debug_package %{nil}
%global kmod_name maccel
%global kver %{?kernel_version}%{!?kernel_version:0}

Name:           akmod-maccel
Version:        0.5.6
Release:        1%{?dist}
Summary:        Akmod package for maccel mouse acceleration kernel module
License:        GPL-2.0-or-later
URL:            https://github.com/Gnarus-G/maccel
Source0:        %{url}/archive/v%{version}/maccel-%{version}.tar.gz

BuildRequires:  akmods
BuildRequires:  %{_bindir}/kmodtool

Requires:       akmods
Requires:       kernel-devel
Provides:       kmod-maccel = %{version}-%{release}

%description
This package provides the akmod package for the maccel mouse acceleration driver.
The akmod system automatically rebuilds the kernel module when the kernel is updated,
ensuring that maccel continues to work after kernel updates.

Maccel is a mouse acceleration driver for Linux that provides customizable mouse
acceleration curves and parameters through a kernel module and CLI tool.

%prep
%autosetup -n %{kmod_name}-%{version}
%{?kmodtool_check}

%build
# Generate kmod spec using kmodtool
kmodtool --kmodname %{kmod_name} --target %{_target_cpu} --akmod > kmod-%{kmod_name}.spec

# Add required macro definitions to the generated kmod spec
# These are needed for the kmod spec to build properly when used by akmods
sed -i '1i%%global kmod_name %{kmod_name}\n%%global version %{version}\n%%global release %{release}' kmod-%{kmod_name}.spec

%install
# Install driver source to /usr/src/akmods/ for automatic building
mkdir -p %{buildroot}%{_usrsrc}/akmods/%{kmod_name}-%{version}-%{release}
cp -r driver %{buildroot}%{_usrsrc}/akmods/%{kmod_name}-%{version}-%{release}/
cp -r Makefile %{buildroot}%{_usrsrc}/akmods/%{kmod_name}-%{version}-%{release}/
cp kmod-%{kmod_name}.spec %{buildroot}%{_usrsrc}/akmods/%{kmod_name}-%{version}-%{release}/

%files
%license LICENSE
%doc README.md
%{_usrsrc}/akmods/%{kmod_name}-%{version}-%{release}/

%changelog
* Sat Nov 08 2025 github-actions[bot]   <github-actions[bot]@users.noreply.github.com> - 0.5.5-1
- Update to maccel version 0.5.5
* Fri Nov 07 2025 Maccel Builder <builder@maccel.local> - 0.5.6-1
- Initial akmod package for maccel
- Use proper akmod pattern without kmodtool complexity
- Remove fabricated /etc/akmods config file
- Use upstream driver Makefile directly

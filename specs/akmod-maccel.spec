# akmod-maccel.spec - Automatic kernel module package for maccel mouse acceleration driver
# This spec file builds an akmod package that automatically rebuilds the kernel module
# when the kernel is updated, using Fedora's akmods system.

%global debug_package %{nil}

Name:           akmod-maccel
Version:        0.5.6
Release:        1%{?dist}
Summary:        Akmod package for maccel mouse acceleration kernel module
License:        GPL-2.0-or-later
URL:            https://github.com/Gnarus-G/maccel
Source0:        %{url}/archive/v%{version}/maccel-%{version}.tar.gz

BuildRequires:  akmods

Requires:       akmods
Requires:       kernel-devel

%description
This package provides the akmod package for the maccel mouse acceleration driver.
The akmod system automatically rebuilds the kernel module when the kernel is updated,
ensuring that maccel continues to work after kernel updates.

Maccel is a mouse acceleration driver for Linux that provides customizable mouse
acceleration curves and parameters through a kernel module and CLI tool.

%prep
%setup -q -n maccel-%{version}

%build
# Prepare source files only - akmods will compile on target system
# No build needed for akmod packages

%install
# Install driver source to /usr/src/akmods/ for automatic building
mkdir -p %{buildroot}%{_usrsrc}/akmods/maccel-%{version}
cp -r driver/* %{buildroot}%{_usrsrc}/akmods/maccel-%{version}/

%post
# Trigger akmod build for current kernel
/usr/sbin/akmods --force --kernels $(uname -r) || true
/usr/sbin/depmod -a || true
/sbin/modprobe maccel || true

%preun
# Unload module before uninstall
/sbin/modprobe -r maccel 2>/dev/null || true

%files
%license LICENSE
%doc README.md
%{_usrsrc}/akmods/maccel-%{version}/

%changelog
* Fri Nov 07 2025 Maccel Builder <builder@maccel.local> - 0.5.6-1
- Initial akmod package for maccel
- Use proper akmod pattern without kmodtool complexity
- Remove fabricated /etc/akmods config file
- Use upstream driver Makefile directly

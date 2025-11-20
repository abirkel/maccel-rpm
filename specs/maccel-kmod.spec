# Build kmod package for a specific kernel version
# Usage: rpmbuild --define 'kernel_version 6.11.8-300.fc41.x86_64' -ba maccel-kmod.spec

%{!?kernel_version: %{error: kernel_version must be defined. Use: rpmbuild --define 'kernel_version X.X.X-XXX.fcXX.x86_64'}}

%global debug_package %{nil}
%global kmod_name maccel
%global kernel_version_clean %(echo %{kernel_version} | sed 's/\\.fc/%{?dist}.fc/' | sed 's/\\.fc/.fc/')

Name:           kmod-%{kmod_name}
Version:        0.5.6
Release:        1%{?dist}
Summary:        Kernel module for maccel mouse acceleration driver

License:        GPL-2.0-or-later
URL:            https://github.com/Gnarus-G/maccel
Source0:        %{url}/archive/v%{version}/maccel-%{version}.tar.gz

BuildRequires:  kernel-devel = %{kernel_version}
BuildRequires:  gcc
BuildRequires:  make

Requires:       kernel = %{kernel_version}
Provides:       %{kmod_name}-kmod = %{version}-%{release}

%description
Kernel module for the maccel mouse acceleration driver, built for kernel %{kernel_version}.

Maccel is a mouse acceleration driver for Linux that provides customizable mouse
acceleration curves and parameters through a kernel module and CLI tool.

This package contains the pre-compiled kernel module for a specific kernel version.

%prep
%autosetup -n maccel-%{version}

%build
# Build the kernel module for the specified kernel version
make V=1 %{?_smp_mflags} \
    -C /usr/src/kernels/%{kernel_version} \
    M=${PWD}/driver \
    modules

%install
# Install the kernel module
install -D -m 644 driver/%{kmod_name}.ko \
    %{buildroot}/usr/lib/modules/%{kernel_version}/extra/%{kmod_name}/%{kmod_name}.ko

%files
/usr/lib/modules/%{kernel_version}/extra/%{kmod_name}/%{kmod_name}.ko

%post
# Run depmod to update module dependencies
if [ -x /usr/sbin/depmod ]; then
    /usr/sbin/depmod -a %{kernel_version} || :
fi

%postun
# Run depmod after uninstall
if [ $1 -eq 0 ]; then
    if [ -x /usr/sbin/depmod ]; then
        /usr/sbin/depmod -a %{kernel_version} || :
    fi
fi

%changelog
* Thu Nov 20 2025 Maccel Builder <builder@maccel.local> - 0.5.6-1
- Convert from akmod to kmod package for atomic/ostree distros
- Build for specific kernel version passed via macro
- Remove akmods dependency and automatic rebuild logic

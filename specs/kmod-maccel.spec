# kmod-maccel.spec - Kernel module package for maccel mouse acceleration driver
# This spec file builds a pre-compiled kernel module for a specific kernel version.

%global debug_package %{nil}

Name:           kmod-maccel
Version:        0.5.6
Release:        1%{?dist}
Summary:        Kernel module for maccel mouse acceleration driver
License:        GPL-2.0-or-later
URL:            https://github.com/Gnarus-G/maccel
Source0:        %{url}/archive/v%{version}/maccel-%{version}.tar.gz

BuildRequires:  kernel-devel
BuildRequires:  gcc
BuildRequires:  make

Requires:       kernel

%description
This package provides the maccel kernel module compiled for a specific kernel version.

Maccel is a mouse acceleration driver for Linux that provides customizable mouse
acceleration curves and parameters through a kernel module and CLI tool.

NOTE: The recommended installation method is to use the akmod-maccel package,
which automatically rebuilds the kernel module when the kernel is updated.

%prep
%setup -q -n maccel-%{version}

%build
# Build the kernel module using upstream Makefile
KVER=$(ls -1 /usr/src/kernels | head -1)
cd driver
make -C /usr/src/kernels/${KVER} M=$(pwd) modules

%install
# Get kernel version from build
KVER=$(ls -1 /usr/src/kernels | head -1)

# Install the compiled kernel module
mkdir -p %{buildroot}/lib/modules/${KVER}/extra/maccel/
install -m 644 driver/maccel.ko %{buildroot}/lib/modules/${KVER}/extra/maccel/

%post
# Update module dependencies for running kernel
/sbin/depmod -a || true
/sbin/modprobe maccel || true

%preun
# Unload module before uninstall
/sbin/modprobe -r maccel 2>/dev/null || true

%postun
# Run depmod after removal
if [ $1 -eq 0 ]; then
    /sbin/depmod -a || true
fi

%files
/lib/modules/*/extra/maccel/maccel.ko

%changelog
* Sat Nov 08 2025 github-actions[bot]   <github-actions[bot]@users.noreply.github.com> - 0.5.6-1
- Update to maccel version 0.5.6
* Sat Nov 08 2025 github-actions[bot]   <github-actions[bot]@users.noreply.github.com> - 0.5.5-1
- Update to maccel version 0.5.5
* Fri Nov 07 2025 Maccel Builder <builder@maccel.local> - 0.5.6-1
- Initial kmod package for maccel
- Use upstream driver Makefile directly
- Simplify kernel version detection
- Remove stub file confusion

# akmod-maccel.spec - Automatic kernel module package for maccel mouse acceleration driver
# This spec file builds an akmod package that automatically rebuilds the kernel module
# when the kernel is updated, using Fedora's akmods system.

%define buildforkernels akmod
%define debug_package %{nil}

Name:           akmod-maccel
Version:        %(echo "${MACCEL_VERSION:-0.0.0}" | sed 's/^v//')
Release:        1%{?dist}
Summary:        Akmod package for maccel mouse acceleration kernel module

License:        GPL-2.0-or-later
URL:            https://github.com/Gnarus-G/maccel
Source0:        https://github.com/Gnarus-G/maccel/archive/v%{version}/maccel-%{version}.tar.gz

BuildRequires:  kmodtool
BuildRequires:  akmods
BuildRequires:  kernel-devel

Requires:       akmods
Requires:       kernel-devel

# kmodtool does its magic here
%{expand:%(kmodtool --target %{_target_cpu} --repo rpmfusion --kmodname %{name} %{?buildforkernels:--%{buildforkernels}} %{?kernels:--for-kernels "%{?kernels}"} 2>/dev/null) }

%description
This package provides the akmod package for the maccel mouse acceleration driver.
The akmod system automatically rebuilds the kernel module when the kernel is updated,
ensuring that maccel continues to work after kernel updates.

Maccel is a mouse acceleration driver for Linux that provides customizable mouse
acceleration curves and parameters through a kernel module and CLI tool.

%prep
%setup -q -n maccel-%{version}

# Copy the driver source to the build directory
mkdir -p _kmod_build_/maccel
cp -r driver/* _kmod_build_/maccel/

%build
# Prepare the driver source for akmods
# The actual kernel module build happens automatically via akmods

# Create a Makefile wrapper for akmods
cat > _kmod_build_/maccel/Makefile << 'EOF'
# Makefile for maccel kernel module (akmods wrapper)

obj-m := maccel.o

# Set FIXEDPT_BITS=64 for x86_64 architecture
ifeq ($$(shell uname -m),x86_64)
ccflags-y := -DFIXEDPT_BITS=64
endif

# Standard kernel module build
all:
	$$(MAKE) -C $$(KERNEL_SRC) M=$$(PWD) modules

clean:
	$$(MAKE) -C $$(KERNEL_SRC) M=$$(PWD) clean

install:
	$$(MAKE) -C $$(KERNEL_SRC) M=$$(PWD) modules_install

.PHONY: all clean install
EOF

%install
# Install driver source to /usr/src/akmods/ for automatic building
mkdir -p %{buildroot}%{_usrsrc}/akmods/maccel-%{version}
cp -r _kmod_build_/maccel/* %{buildroot}%{_usrsrc}/akmods/maccel-%{version}/

# Create akmod configuration
mkdir -p %{buildroot}%{_sysconfdir}/akmods
cat > %{buildroot}%{_sysconfdir}/akmods/maccel.conf << EOF
# Akmod configuration for maccel
MODULE_NAME="maccel"
MODULE_VERSION="%{version}"
MODULE_SOURCE_DIR="%{_usrsrc}/akmods/maccel-%{version}"
EOF

%post
# Trigger akmod build for all installed kernels
if [ -x /usr/sbin/akmods ]; then
    echo "Building maccel kernel module for installed kernels..."
    /usr/sbin/akmods --force --kernels $(uname -r)
    
    # Load the module if build was successful
    if [ -f /lib/modules/$(uname -r)/extra/maccel/maccel.ko* ]; then
        echo "Loading maccel kernel module..."
        /usr/sbin/modprobe maccel || true
    fi
fi

%preun
# Unload the module before uninstallation
if [ $1 -eq 0 ]; then
    if /usr/sbin/lsmod | grep -q maccel; then
        echo "Unloading maccel kernel module..."
        /usr/sbin/modprobe -r maccel || true
    fi
fi

%postun
# Clean up akmod builds on complete removal
if [ $1 -eq 0 ]; then
    rm -rf /usr/src/akmods/maccel-%{version}
fi

%files
%license LICENSE
%doc README.md
%{_usrsrc}/akmods/maccel-%{version}/
%config(noreplace) %{_sysconfdir}/akmods/maccel.conf

%changelog
# Changelog entries will be generated during build
# See https://github.com/Gnarus-G/maccel/releases for upstream changes

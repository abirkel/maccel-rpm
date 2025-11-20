# maccel.spec - CLI tool package for maccel mouse acceleration driver
# This spec file builds the userspace CLI tool that configures the maccel kernel module.

%global debug_package %{nil}

Name:           maccel
Version:        0.5.6
Release:        2%{?dist}
Summary:        CLI tool for maccel mouse acceleration driver
License:        GPL-2.0-or-later
URL:            https://github.com/Gnarus-G/maccel
Source0:        %{url}/archive/v%{version}/maccel-%{version}.tar.gz

BuildRequires:  rust
BuildRequires:  cargo
BuildRequires:  gcc
BuildRequires:  make

Requires:       (akmod-maccel or kmod-maccel)
Requires:       systemd-udev
Provides:       maccel-kmod-common = %{version}-%{release}

%description
Command-line interface for configuring the maccel mouse acceleration driver.

Maccel is a mouse acceleration driver for Linux that provides customizable mouse
acceleration curves and parameters. This package provides the CLI tool for
configuring the kernel module parameters.

The kernel module must be installed separately via akmod-maccel or kmod-maccel.

%prep
%setup -q -n maccel-%{version}

%build
# Build CLI with cargo from workspace root
# Set RUSTUP_TOOLCHAIN=stable to ensure stable toolchain is used
export RUSTUP_TOOLCHAIN=stable

# Build the release binary
cargo build --bin maccel --release

%install
# Install maccel binary
install -D -m 0755 target/release/maccel %{buildroot}%{_bindir}/maccel

# Install udev rules (use /usr/lib/udev/rules.d for Fedora)
install -D -m 0644 udev_rules/99-maccel.rules %{buildroot}%{_prefix}/lib/udev/rules.d/99-maccel.rules

# Install udev helper script (use _prefix/lib for udev helpers on Fedora)
install -D -m 0755 udev_rules/maccel_param_ownership_and_resets %{buildroot}%{_prefix}/lib/udev/maccel_param_ownership_and_resets

%pre
# Create maccel system group if it doesn't exist
getent group maccel >/dev/null || groupadd -r maccel 2>/dev/null || true

%post
# Reload udev rules
if [ -x /usr/bin/udevadm ]; then
    /usr/bin/udevadm control --reload-rules || true
    /usr/bin/udevadm trigger --subsystem-match=usb --subsystem-match=input || true
fi

%postun
# Reload udev rules after uninstall
if [ $1 -eq 0 ]; then
    if [ -x /usr/bin/udevadm ]; then
        /usr/bin/udevadm control --reload-rules || true
        /usr/bin/udevadm trigger --subsystem-match=usb --subsystem-match=input || true
    fi
fi

%files
%license LICENSE
%doc README.md
%{_bindir}/maccel
# Note: Using _prefix/lib/udev is correct for Fedora udev rules and helper scripts
%{_prefix}/lib/udev/rules.d/99-maccel.rules
%{_prefix}/lib/udev/maccel_param_ownership_and_resets

%changelog
* Thu Nov 20 2025 github-actions[bot]   <github-actions[bot]@users.noreply.github.com> - 0.5.6-2
- Rebuild for kernel compatibility
* Wed Nov 19 2025 github-actions[bot]   <github-actions[bot]@users.noreply.github.com> - 0.5.6-1
- Rebuild for kernel compatibility
* Wed Nov 19 2025 github-actions[bot]   <github-actions[bot]@users.noreply.github.com> - 0.5.6-3
- Rebuild for kernel compatibility
* Wed Nov 19 2025 github-actions[bot]   <github-actions[bot]@users.noreply.github.com> - 0.5.6-2
- Rebuild for kernel compatibility
* Sat Nov 08 2025 github-actions[bot]   <github-actions[bot]@users.noreply.github.com> - 0.5.6-1
- Update to maccel version 0.5.6
* Sat Nov 08 2025 github-actions[bot]   <github-actions[bot]@users.noreply.github.com> - 0.5.6-1
- Update to maccel version 0.5.6
* Sat Nov 08 2025 github-actions[bot]   <github-actions[bot]@users.noreply.github.com> - 0.5.5-1
- Update to maccel version 0.5.5
* Fri Nov 07 2025 Maccel Builder <builder@maccel.local> - 0.5.6-1
- Initial CLI package for maccel
- Fix hardcoded library paths to use proper macros
- Add systemd-udev dependency
- Simplify post-install messages
- Add error handling to group creation and udev commands


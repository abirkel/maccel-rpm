# maccel.spec - CLI tool package for maccel mouse acceleration driver
# This spec file builds the userspace CLI tool that configures the maccel kernel module.

%define debug_package %{nil}

Name:           maccel
Version:        %(echo "${MACCEL_VERSION:-0.0.0}" | sed 's/^v//')
Release:        1%{?dist}
Summary:        CLI tool for maccel mouse acceleration driver

License:        GPL-2.0-or-later
URL:            https://github.com/Gnarus-G/maccel
Source0:        https://github.com/Gnarus-G/maccel/archive/v%{version}/maccel-%{version}.tar.gz

BuildRequires:  rust
BuildRequires:  cargo
BuildRequires:  gcc
BuildRequires:  make

Requires:       (akmod-maccel or kmod-maccel)

%description
Command-line interface for configuring the maccel mouse acceleration driver.

Maccel is a mouse acceleration driver for Linux that provides customizable mouse
acceleration curves and parameters. This package provides the CLI tool for
configuring the kernel module parameters.

The kernel module must be installed separately via akmod-maccel or kmod-maccel.

%prep
%setup -q -n maccel-%{version}

%build
# Build CLI with cargo
cd cli

# Set RUSTUP_TOOLCHAIN=stable to ensure stable toolchain is used
export RUSTUP_TOOLCHAIN=stable

# Build the release binary
cargo build --release

# Return to parent directory
cd ..

%install
# Install maccel binary to %{_bindir}
install -D -m 0755 cli/target/release/maccel %{buildroot}%{_bindir}/maccel

# Install udev rules to %{_udevrulesdir}
install -D -m 0644 udev/99-maccel.rules %{buildroot}%{_udevrulesdir}/99-maccel.rules

# Install udev helper script to /usr/lib/udev/
install -D -m 0755 udev/maccel_param_ownership_and_resets %{buildroot}/usr/lib/udev/maccel_param_ownership_and_resets

%pre
# Create maccel system group
getent group maccel >/dev/null || groupadd -r maccel

%post
# Reload udev rules
if [ -x /usr/bin/udevadm ]; then
    echo "Reloading udev rules..."
    /usr/bin/udevadm control --reload-rules
    
    # Trigger udev for USB/input devices
    echo "Triggering udev for USB and input devices..."
    /usr/bin/udevadm trigger --subsystem-match=usb --subsystem-match=input
fi

# Print message about adding user to maccel group
cat << 'EOF'

=============================================================================
Maccel CLI has been installed successfully!

IMPORTANT: To use maccel, you need to add your user to the maccel group:

    sudo usermod -aG maccel $USER

Then log out and log back in for the group change to take effect.

After logging back in, you can use the maccel command to configure your
mouse acceleration settings.

For more information, visit: https://github.com/Gnarus-G/maccel
=============================================================================

EOF

%preun
# No special actions needed before uninstall

%postun
# Reload udev rules after uninstall
if [ $1 -eq 0 ]; then
    if [ -x /usr/bin/udevadm ]; then
        /usr/bin/udevadm control --reload-rules
        /usr/bin/udevadm trigger --subsystem-match=usb --subsystem-match=input
    fi
fi

%files
%license LICENSE
%doc README.md
%{_bindir}/maccel
%{_udevrulesdir}/99-maccel.rules
/usr/lib/udev/maccel_param_ownership_and_resets

%changelog
# Changelog entries will be generated during build
# See https://github.com/Gnarus-G/maccel/releases for upstream changes


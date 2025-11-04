# Maccel RPM Packaging

RPM packages for the [maccel](https://github.com/Gnarus-G/maccel) mouse acceleration driver for Fedora and RPM-based Linux distributions.

## Overview

This repository provides automated RPM packaging for maccel, a mouse acceleration driver consisting of a kernel module and CLI tool. Packages are built automatically via GitHub Actions when new maccel releases are detected.

## Packages

This repository builds three RPM packages:

- **akmod-maccel**: Automatic kernel module package that rebuilds for new kernels using akmods
- **kmod-maccel**: Kernel module package for specific kernel versions (optional, not built by default)
- **maccel**: CLI tool for configuring mouse acceleration parameters

## Repository Structure

```
maccel-rpm/
├── .github/
│   └── workflows/      # GitHub Actions workflows
├── .gitignore
├── specs/              # RPM spec files
└── README.md
```

## Installation

<!-- Installation instructions will be added after repository setup -->

### Prerequisites

- Fedora or compatible RPM-based distribution
- x86_64 architecture

### Repository Setup

Instructions for adding the maccel repository will be provided here.

### Package Installation

Instructions for installing maccel packages will be provided here.

### Post-Installation

Instructions for post-installation configuration will be provided here.

## Building Locally

Instructions for building RPM packages locally will be provided here.

## Contributing

This is a personal packaging project for maccel. Issues and pull requests are welcome.

## License

The packaging scripts and spec files in this repository are provided as-is. The maccel software itself is licensed under GPL-2.0-or-later. See the [upstream repository](https://github.com/Gnarus-G/maccel) for details.

## Upstream

- Maccel Repository: https://github.com/Gnarus-G/maccel
- Maccel Documentation: https://github.com/Gnarus-G/maccel#readme

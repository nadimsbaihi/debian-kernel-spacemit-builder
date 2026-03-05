# SpacemiT K1 Kernel Builder for Debian

Cross-compiles the [jmontleon/linux-spacemit](https://github.com/jmontleon/linux-spacemit) kernel
(used by Fedora's SpacemiT Koji builds) into installable Debian `.deb` packages.

Targets: Milk-V Jupiter, Muse Pi Pro, BananaPi F3, and other SpacemiT K1 boards.

## Quick Start

```bash
chmod +x build-spacemit-kernel.sh
./build-spacemit-kernel.sh
```

Packages land in `./output/`.

## Options

| Flag | Description               | Default           |
|------|---------------------------|--------------------|
| `-b` | Kernel branch             | `linux-6.18.y`    |
| `-j` | Parallel jobs (0 = all)   | `0`                |
| `-o` | Output directory          | `./output`         |
| `-v` | Deb package version       | `6.18.13-1`        |

Example:

```bash
./build-spacemit-kernel.sh -b linux-6.16.y -j8 -v 6.16.0-1
```

## Installing on Target

Copy the debs to your RISC-V board / image and install:

```bash
dpkg -i linux-image-6.18.13-spacemit_6.18.13-1_riscv64.deb
dpkg -i linux-headers-6.18.13-spacemit_6.18.13-1_riscv64.deb  # optional

# Regenerate initramfs if not done automatically
update-initramfs -c -k 6.18.13-spacemit

# Update bootloader
update-grub  # or however your board boots
```

## Notes

- The build cross-compiles from x86_64 → riscv64 using `gcc-riscv64-linux-gnu`.
- `make bindeb-pkg` produces a single `linux-image` deb with all modules
  (unlike Fedora's split into kernel-modules, kernel-modules-core, kernel-modules-extra).
- DTBs are installed to `/usr/lib/linux-image-<version>/` inside the deb.
- The postinst script automatically calls `update-initramfs` if available on the target.

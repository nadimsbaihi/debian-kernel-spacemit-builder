#!/usr/bin/env bash
#
# build-spacemit-kernel.sh
# Cross-compile the SpacemiT K1 kernel from jmontleon/linux-spacemit
# and produce installable Debian packages (.deb).
#
# Usage:
#   ./build-spacemit-kernel.sh              # defaults
#   ./build-spacemit-kernel.sh -j8          # limit to 8 cores
#   ./build-spacemit-kernel.sh -b linux-6.16.y   # different branch
#
set -euo pipefail

# ── Defaults (override with flags or env vars) ──────────────────────────────
KERNEL_BRANCH="${KERNEL_BRANCH:-linux-6.18.y}"
KERNEL_REPO="${KERNEL_REPO:-https://github.com/nadimsbaihi/linux-spacemit.git}"
LOCALVERSION="${LOCALVERSION:--spacemit}"
KDEB_PKGVERSION="${KDEB_PKGVERSION:-6.18.15-1}"
JOBS="${JOBS:-0}"                     # 0 = $(nproc) inside the container
OUTPUT_DIR="${OUTPUT_DIR:-./output}"
IMAGE_NAME="spacemit-kernel-builder"

# ── Parse flags ──────────────────────────────────────────────────────────────
while getopts "b:j:o:v:h" opt; do
    case $opt in
        b) KERNEL_BRANCH="$OPTARG" ;;
        j) JOBS="$OPTARG" ;;
        o) OUTPUT_DIR="$OPTARG" ;;
        v) KDEB_PKGVERSION="$OPTARG" ;;
        h)
            echo "Usage: $0 [-b branch] [-j jobs] [-o output_dir] [-v deb_version]"
            echo ""
            echo "  -b   Kernel branch   (default: $KERNEL_BRANCH)"
            echo "  -j   Parallel jobs   (default: 0 = all cores)"
            echo "  -o   Output dir      (default: ./output)"
            echo "  -v   Deb version     (default: $KDEB_PKGVERSION)"
            exit 0
            ;;
        *) echo "Unknown option: -$opt" >&2; exit 1 ;;
    esac
done

echo "============================================="
echo "  SpacemiT K1 Kernel Builder (Debian .deb)"
echo "============================================="
echo "  Branch:      ${KERNEL_BRANCH}"
echo "  Repo:        ${KERNEL_REPO}"
echo "  Version:     ${KDEB_PKGVERSION}"
echo "  Localver:    ${LOCALVERSION}"
echo "  Jobs:        ${JOBS:-auto}"
echo "  Output:      ${OUTPUT_DIR}"
echo "============================================="
echo ""

# ── Build the Docker image ───────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ">>> Building Docker image..."
docker build \
    --build-arg KERNEL_BRANCH="${KERNEL_BRANCH}" \
    --build-arg KERNEL_REPO="${KERNEL_REPO}" \
    --build-arg LOCALVERSION="${LOCALVERSION}" \
    --build-arg KDEB_PKGVERSION="${KDEB_PKGVERSION}" \
    --build-arg JOBS="${JOBS}" \
    -t "${IMAGE_NAME}" \
    "${SCRIPT_DIR}"

# ── Extract the .deb files ───────────────────────────────────────────────────
echo ""
echo ">>> Extracting .deb packages..."
mkdir -p "${OUTPUT_DIR}"

# Method: use a temporary container to copy files out
CONTAINER_ID=$(docker create "${IMAGE_NAME}")
docker cp "${CONTAINER_ID}:/out/." "${OUTPUT_DIR}/"
docker rm "${CONTAINER_ID}" > /dev/null

echo ""
echo ">>> Done! Packages:"
ls -lh "${OUTPUT_DIR}"/*.deb
echo ""
echo "Install on your RISC-V target with:"
echo "  dpkg -i ${OUTPUT_DIR}/linux-image-*.deb"
echo "  dpkg -i ${OUTPUT_DIR}/linux-headers-*.deb  # optional, for dkms"

#!/usr/bin/env bash
# build.sh - Portable builder script

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
: "''${OUTPUT_DIR:=./images}"
: "''${IMAGE_PREFIX:=nixos-rpi4}"
: "''${COMPRESSION_LEVEL:=19}"

# QEMU setup function
setup_qemu() {
    echo -e "''${YELLOW}⚙️ Setting up QEMU static binaries...''${NC}"
    
    # Check if binfmt is already setup
    if [ -f /proc/sys/fs/binfmt_misc/arm64 ] || [ -f /proc/sys/fs/binfmt_misc/qemu-aarch64 ]; then
        echo -e "''${GREEN}✅ ARM emulation already enabled''${NC}"
        return 0
    fi
    
    # Try to setup binfmt
    if command -v qemu-binfmt-setup >/dev/null 2>&1; then
        sudo qemu-binfmt-setup aarch64
        echo -e "''${GREEN}✅ QEMU ARM emulation configured''${NC}"
    else
        echo -e "''${YELLOW}⚠️  qemu-binfmt-setup not found, trying manual setup...''${NC}"
        
        # Manual binfmt registration
        if [ -d /proc/sys/fs/binfmt_misc ]; then
            echo ':qemu-aarch64:M::\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\xb7\x00:\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff:/usr/bin/qemu-aarch64-static:OCF' | \
            sudo tee /proc/sys/fs/binfmt_misc/register >/dev/null 2>&1 || true
        fi
    fi
    
    # Verify setup
    if [ -f /proc/sys/fs/binfmt_misc/arm64 ] || [ -f /proc/sys/fs/binfmt_misc/qemu-aarch64 ]; then
        echo -e "''${GREEN}✅ ARM emulation verified''${NC}"
    else
        echo -e "''${YELLOW}⚠️  ARM emulation may not work properly''${NC}"
        echo -e "''${YELLOW}   You may need to run: sudo nix shell nixpkgs#qemu-user -c qemu-binfmt-setup aarch64''${NC}"
    fi
}

usage() {
    cat << EOF
${GREEN}Raspberry Pi Image Builder${NC}

Usage: $0 [OPTIONS]

Options:
  -o, --output DIR      Output directory (default: ./images)
  -n, --name NAME       Image name prefix (default: nixos-rpi4)
  -c, --compress LEVEL  Compression level (1-19, default: 19)
  --no-setup           Skip QEMU setup
  -h, --help           Show this help
  --no-color           Disable colors

Examples:
  $0 -o ./builds -n my-rpi
  $0 --compress 10 --no-setup

EOF
}

# Parse arguments
NO_SETUP=false
while [[ $# -gt 0 ]]; do
    case $1 in
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -n|--name)
            IMAGE_PREFIX="$2"
            shift 2
            ;;
        -c|--compress)
            COMPRESSION_LEVEL="$2"
            shift 2
            ;;
        --no-setup)
            NO_SETUP=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        --no-color)
            RED=''; GREEN=''; YELLOW=''; NC=''
            shift
            ;;
        *)
            echo -e "''${RED}Unknown option: $1''${NC}"
            usage
            exit 1
            ;;
    esac
done

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Generate image name
IMAGE_NAME="''${IMAGE_PREFIX}-$(date +%Y%m%d-%H%M%S).img.zst"
LATEST_SYMLINK="latest.img.zst"

echo -e "''${GREEN}🔨 Starting Raspberry Pi image build...''${NC}"
echo -e "''${YELLOW}Target:''${NC} aarch64-linux"
echo -e "''${YELLOW}Output:''${NC} $OUTPUT_DIR/"
echo -e "''${YELLOW}Image:''${NC} $IMAGE_NAME"
echo ""

# Setup QEMU if not disabled
if ! $NO_SETUP; then
    setup_qemu
else
    echo -e "''${YELLOW}⏭️  Skipping QEMU setup''${NC}"
fi

# Build with Nix
export NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1

if ! nix build .#images.rpi4 --system aarch64-linux --out-link "$OUTPUT_DIR/latest-build"; then
    echo -e "''${RED}❌ Build failed!''${NC}"
    exit 1
fi

# Find the raw image
RAW_IMAGE=$(find "$OUTPUT_DIR/latest-build" -name "*.img" | head -1)
if [[ -z "$RAW_IMAGE" ]]; then
    echo -e "''${RED}❌ No image file found in build result!''${NC}"
    exit 1
fi

# Compress with zstd
echo -e "''${GREEN}📦 Compressing image (level $COMPRESSION_LEVEL)...''${NC}"
zstd -T0 -"$COMPRESSION_LEVEL" --rm "$RAW_IMAGE" -o "$OUTPUT_DIR/$IMAGE_NAME"

# Create symlinks
ln -sf "$IMAGE_NAME" "$OUTPUT_DIR/$LATEST_SYMLINK"
ln -sfn "$OUTPUT_DIR/latest-build" "$OUTPUT_DIR/latest"

# Cleanup
rm -f "$OUTPUT_DIR/latest-build"

# Show results
echo ""
echo -e "''${GREEN}✅ Build completed successfully!''${NC}"
echo -e "''${YELLOW}Image:''${NC}     $OUTPUT_DIR/$IMAGE_NAME"
echo -e "''${YELLOW}Symlink:''${NC}   $OUTPUT_DIR/$LATEST_SYMLINK"
echo -e "''${YELLOW}Size:''${NC}      $(du -h "$OUTPUT_DIR/$IMAGE_NAME" | cut -f1)"
echo ""

# Flash instructions
cat << EOF
To flash to SD card:

  sudo dd if=$OUTPUT_DIR/$IMAGE_NAME of=/dev/sdX bs=4M status=progress
  sync

Or use balenaEtcher or similar tool.

First boot credentials:
  Username: nixos
  Password: nixos
  SSH: ssh nixos@raspberrypi.local

EOF
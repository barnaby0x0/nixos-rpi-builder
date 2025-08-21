{
  description = "Raspberry Pi Image Builder - Packer-like tool";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        # Application portable
        packages.default = pkgs.writeShellApplication {
          name = "rpi-builder";
          runtimeInputs = with pkgs; [ qemu-user-static zstd ];
          text = ''
            set -e
            
            # Configuration
            OUTPUT_DIR="''${OUTPUT_DIR:-./images}"
            IMAGE_NAME="nixos-rpi4-$(date +%Y%m%d-%H%M%S).img.zst"
            TARGET_SYSTEM="aarch64-linux"
            
            echo "🔨 Building Raspberry Pi 4 image..."
            
            # Enable cross-compilation
            export NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1
            
            # Build the image
            nix build .#images.rpi4 --system "$TARGET_SYSTEM" --out-link "$OUTPUT_DIR/latest"
            
            # Find and compress the image
            RAW_IMAGE=$(find "$OUTPUT_DIR/latest" -name "*.img" | head -1)
            if [ -z "$RAW_IMAGE" ]; then
              echo "❌ No image found!"
              exit 1
            fi
            
            echo "📦 Compressing image..."
            zstd -T0 -19 --rm "$RAW_IMAGE" -o "$OUTPUT_DIR/$IMAGE_NAME"
            
            # Create symlink
            ln -sf "$IMAGE_NAME" "$OUTPUT_DIR/latest.img.zst"
            
            echo "✅ Build completed!"
            echo "📁 Image: $OUTPUT_DIR/$IMAGE_NAME"
            echo "🔗 Symlink: $OUTPUT_DIR/latest.img.zst"
            echo ""
            echo "To flash: sudo dd if=$OUTPUT_DIR/$IMAGE_NAME of=/dev/sdX bs=4M status=progress"
          '';
        };

        # Image definition
        images.rpi4 = self.nixosConfigurations.rpi4.config.system.build.sdImage;

        # NixOS configuration
        nixosConfigurations.rpi4 = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          modules = [
            "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
            ./configuration.nix
          ];
        };

        # Dev shell with all tools
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            qemu-user-static
            zstd
            parted
            util-linux
            self.packages.${system}.default
          ];
        };
      }
    );
}
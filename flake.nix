{
  description = "Raspberry Pi Image Builder - Packer-like tool";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

{
  outputs = { self, nixpkgs, ... }: {
    images.router = self.nixosConfigurations.router.config.system.build.sdImage;
    nixosConfigurations = {
      router = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
          ./configuration.nix
        ];
      };
    };
  };
}}
{
  description = "Raspberry Pi Image Builder - Packer-like tool";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };


  outputs = { self, nixpkgs, ... }: {
    lib = nixpkgs.lib;
    images.router = self.nixosConfigurations.router.config.system.build.sdImage;
    nixosConfigurations = {
      router = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
          ./configuration.nix
          {
              nixpkgs.crossSystem.system = "aarch64-linux";
            }
        ];
      };
    };
  };
}

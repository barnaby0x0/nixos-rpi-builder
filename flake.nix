{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixos-generators, ... }: {
    # Définition de la configuration NixOS
    nixosConfigurations.router = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
        ./configuration.nix
        # {
        #   boot.loader.grub.enable = false;
        #   boot.loader.raspberryPi = {
        #     enable = true;
        #     version = 4;
        #   };
        #   boot.kernelParams = ["console=ttyS0,115200n8" "console=ttyAMA0,115200n8" "console=tty0"];
        # }
      ];
    };

    # Définition des packages pour cross-compilation
    packages.x86_64-linux.sdImage = self.nixosConfigurations.router.config.system.build.sdImage;
  };
}
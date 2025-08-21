FROM nixos/nix:latest

# Install dependencies
RUN nix-env -iA nixpkgs.qemu-user
RUN nix-env -iA nixpkgs.zstd  
RUN nix-env -iA nixpkgs.git
RUN nix-env -iA nixpkgs.binutils

WORKDIR /build

COPY flake.nix /build/
COPY configuration.nix /build/

# ENTRYPOINT ["nix build .#images.router"]
# nix build .#images.router --system aarch64-linux --extra-experimental-features nix-command --extra-experimental-features flakes
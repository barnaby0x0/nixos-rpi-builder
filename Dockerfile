# Use Arch Linux base image
FROM archlinux:base-devel

# Install QEMU for aarch64 emulation and Nix
RUN pacman -Syu --noconfirm --needed \
    qemu-user-static \
    nix \
    && echo "build-users-group =" > /etc/nix/nix.conf

# Enable emulation for aarch64
RUN mkdir -p /usr/bin
RUN ln -sf /usr/bin/qemu-aarch64-static /usr/bin

# Initialize Nix and configure for aarch64
RUN nix-env --profile /nix/var/nix/profiles/default --install --attr nix

# Create a Nix worker user and set up the build environment
RUN useradd -m -G nixbld nixworker
USER nixworker
WORKDIR /home/nixworker

# Configure Nix for the user
RUN mkdir -p ~/.config/nix
RUN echo 'experimental-features = nix-command flakes' > ~/.config/nix/nix.conf

# Copy your flake into the container
COPY --chown=nixworker . .

# Build the flake for aarch64
CMD ["sh", "-c", "nix build --impure --system aarch64-linux .#nixosConfigurations.your-configuration.config.system.build.toplevel"]

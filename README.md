# Cloner le projet
git clone https://github.com/your-username/nixos-rpi-builder.git
cd nixos-rpi-builder

# Builder l'outil
nix build .#default

# Lancer le build (méthode 1)
./result/bin/rpi-builder

# Méthode 2 - avec le script wrapper
chmod +x build.sh
./build.sh --output ./my-images --compress 15

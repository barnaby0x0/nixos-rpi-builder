{ config, pkgs, ... }:

{
  imports = [
    "${pkgs.path}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
  ];

  # Base system
  networking.hostName = "nixos-rpi";
  system.stateVersion = "23.11";

  # Users
  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    initialPassword = "nixos";
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2E..." # Your SSH key here
    ];
  };

  # SSH
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
    settings.PermitRootLogin = "no";
  };

  # Raspberry Pi specific
  hardware.enableRedistributableFirmware = true;
  boot = {
    kernelPackages = pkgs.linuxKernel.packages.linux_rpi4;
    loader.grub.enable = false;
    loader.generic-extlinux-compatible.enable = true;
    kernelParams = [
      "console=ttyAMA0,115200"
      "console=tty1"
      "cma=256M"
    ];
  };

  # Optimizations
  nix.settings = {
    cores = 0; # Use all cores
    max-jobs = "auto";
    experimental-features = [ "nix-command" "flakes" ];
  };

  # Minimal system - remove unnecessary packages
  environment.defaultPackages = [ ];
  environment.systemPackages = with pkgs; [
    vim
    curl
    wget
    htop
    tmux
  ];

  # Auto resize filesystem on first boot
  sdImage = {
    compressImage = false; # We compress manually
    postBuildCommands = ''
      # Create resize script
      cat > $mountPoint/first-boot-resize.sh << 'EOF'
      #!/bin/sh
      parted /dev/mmcblk0 resizepart 2 100%
      resize2fs /dev/mmcblk0p2
      rm /first-boot-resize.sh
      systemctl disable first-boot-resize
      EOF
      
      chmod +x $mountPoint/first-boot-resize.sh
      
      # Systemd service to resize on first boot
      cat > $mountPoint/etc/systemd/system/first-boot-resize.service << 'EOF'
      [Unit]
      Description=Resize filesystem on first boot
      After=local-fs.target
      RequiresMountsFor=/var/lib/misc
      
      [Service]
      Type=oneshot
      ExecStart=/first-boot-resize.sh
      RemainAfterExit=yes
      
      [Install]
      WantedBy=multi-user.target
      EOF
      
      ln -s $mountPoint/etc/systemd/system/first-boot-resize.service \
           $mountPoint/etc/systemd/system/multi-user.target.wants/
    '';
  };
}
{ config, pkgs, lib, ... }: {
  sdImage.compressImage = false;
  system.stateVersion = "24.05"; # depends on the current NixOS version

  # Locale
  time.timeZone = "Europe/Paris"; # change me
  services.ntp.enable = true;

  networking = {
    defaultGateway = "10.10.0.1"; # change me;
    hostName = "router"; # change me
    interfaces.eth0.ipv4.addresses = [{
      address = "10.10.0.207"; # change me
      prefixLength = 24;
    }];
    nameservers = [ "1.1.1.1" ];

    firewall = {
      enable = true;
    };
  };

  # Users
  users.mutableUsers = false;
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP1oFq0GYt8j7vg2nNAJNzwBtqrdOUDp8CMQwLRiz4Vz user@ull" # change me
  ];

  # Enable ssh
  systemd.services.sshd.wantedBy = lib.mkOverride 40 [ "multi-user.target" ];
  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  # Networking
  networking.firewall.allowedTCPPorts = [ 22 ];


}

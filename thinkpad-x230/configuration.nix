{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../common/config/all.nix
    ../common/config/pc.nix
  ];

  nixpkgs.overlays = [
    (final: prev: {
      bun = prev.bun.overrideAttrs (oldAttrs: {
        src = prev.fetchurl {
          # We dynamically construct the URL to grab the 'baseline' version matching the version Nixpkgs expects
          url = "https://github.com/oven-sh/bun/releases/download/bun-v${oldAttrs.version}/bun-linux-x64-baseline.zip";
          # Note: You will hit a hash mismatch error the first time you run this.
          # Nix will tell you the 'got' hash. Copy that hash and replace the zeros below.
          hash = "sha256-f/CaSlGeggbWDXt2MHLL82Qvg3BpAWVYbTA/ryFpIXI=";
        };
      });
    })
  ];

  # Bootloader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;

  networking.hostName = "nixos"; # Define your hostname.
  networking.nameservers = [ "192.168.1.1" "1.1.1.1" "8.8.8.8" ];

  # Enable networking
  networking.networkmanager.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
   

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?

}

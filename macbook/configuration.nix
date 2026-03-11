{ config, pkgs, ... }:

{
  # Nix settings
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "acmyers" ];
  };

  # System packages (available to all users)
  environment.systemPackages = with pkgs; [
    helix
    git
  ];

  # Primary user for system defaults
  system.primaryUser = "acmyers";

  # Set default shell to nushell
  # (you'll still need to add it to /etc/shells and chsh manually once)
  environment.shells = [ pkgs.nushell ];

  # Garbage collection
  nix.gc = {
    automatic = true;
    interval = { Weekday = 0; Hour = 2; Minute = 0; }; # Sunday 2am
    options = "--delete-older-than 30d";
  };

  # Remap caps lock to escape
  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToEscape = true;
  };

  # macOS system preferences managed by nix-darwin
  system.defaults = {
    NSGlobalDomain = {
      AppleShowAllExtensions = true;
      InitialKeyRepeat = 15;
      KeyRepeat = 2;
    };
    dock = {
      autohide = true;
      show-recents = false;
    };
    finder = {
      AppleShowAllExtensions = true;
    };
  };

  # Used for backwards compat — don't change
  system.stateVersion = 6;
}

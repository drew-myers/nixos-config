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
    yubikey-manager
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

  # YubiKey U2F + Touch ID for sudo
  security.pam.services.sudo_local = {
    enable = true;
    text = ''
      auth       optional       ${pkgs.pam-reattach}/lib/pam/pam_reattach.so
      auth       sufficient     ${pkgs.pam_u2f}/lib/security/pam_u2f.so cue [cue_prompt=🔑 Tap YubiKey...]
      auth       sufficient     pam_tid.so
      auth       required       pam_opendirectory.so
    '';
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

  # Declarative homebrew — nix-darwin runs brew bundle for you
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
    };
    taps = [
      "nikitabobko/tap"
    ];
    brews = [
      "colima"
      "docker"
      "docker-compose"
      "awscli"
      "gh"
      "gnu-tar"
      "python3"
      "pam-u2f"
      "bat"
    ];
    casks = [
      "1password"
      "1password-cli"
      "ghostty"
      "nikitabobko/tap/aerospace"
      "firefox"
      "notion"
      "slack"
      "zoom"
    ];
  };

  # Used for backwards compat — don't change
  system.stateVersion = 6;
}

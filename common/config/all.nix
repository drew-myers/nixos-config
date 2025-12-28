# Generic config for all systems
{
  config,
  pkgs,
  ...
}:

let
  common-secrets = import ../secrets.nix;
in
{
  # Nixhelper
  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
  };  


  users.users.acmyers = {
    isNormalUser = true;
    hashedPassword = common-secrets.acmyers-pw;
    description = "Drew Myers";
    extraGroups = [ "networkmanager" "wheel" ];
  };

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  environment.systemPackages = with pkgs; [
    git
    helix
    wget
    git-crypt
  ];

  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    # Expose the Polkit policy for your user (required for system auth/fingerprint)
    polkitPolicyOwners = [ "acmyers" ];
  };
}

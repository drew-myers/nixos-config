{ config, pkgs, lib, ... }:

{
  imports = [
    ../common/home/all.nix
    ../common/home/pc.nix
  ];

  home.packages = with pkgs; [
    opencode
    gemini-cli
    claude-code
    alacritty
    fuzzel

    # Wayland Desktop Support
    waybar        # Status bar
    mako          # Notifications
    swaybg        # Wallpaper
    wl-clipboard  # Clipboard
    swaylock      # Lock screen
    swayidle      # Idle management
    brightnessctl # Brightness control
    pamixer       # Volume control
    pavucontrol   # GUI volume control
    grim          # Screenshots
    slurp         # Region selection
    polkit_gnome  # Auth agent
    networkmanagerapplet # Network Manager Applet
    
    # Fonts
    nerd-fonts.jetbrains-mono
    font-awesome
  ];

  xdg.configFile."niri/config.kdl".source = ./niri.kdl;

  programs.alacritty = {
    enable = true;
    settings = {
      font = {
        normal = {
          family = "JetBrainsMono Nerd Font";
          style = "Regular";
        };
        size = 10.0; # Smaller font size
      };
    };
  };
   
  home.stateVersion = "25.11";
}

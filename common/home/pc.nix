{
  config,
  pkgs,
  lib,
  ...
}: {
  home.packages = with pkgs; [
    neofetch
    nnn # terminal file manager
    glow # markdown previewer in terminal
    vesktop
  ];

  programs.kitty = lib.mkForce {
    enable = true;
    themeFile = "Arthur";
    settings = {
      font_size = 10;
    };
  };
}

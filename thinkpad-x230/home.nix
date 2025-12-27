{ config, pkgs, lib, ... }:

{
  imports = [
    ../common/home/all.nix
    ../common/home/pc.nix
  ];

  home.packages = with pkgs; [
    gemini-cli
  ];

  home.stateVersion = "25.11";
}

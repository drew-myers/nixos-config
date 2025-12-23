{ config, pkgs, lib, ... }:

{
  imports = [
    ../common/home/all.nix
    ../common/home/pc.nix
  ];

  home.stateVersion = "25.11";
}

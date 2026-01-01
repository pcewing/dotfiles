{ config, pkgs, ... }:

{
  home.username = "pewing";
  home.homeDirectory = "/home/pewing";
  home.stateVersion = "24.05";

  imports = [
    ../features/core.nix
  ];
}

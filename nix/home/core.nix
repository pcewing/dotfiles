{ config, pkgs, ... }:

{
  home.username = "pewing";
  home.homeDirectory = "/home/pewing";
  home.stateVersion = "24.05";

  imports = [
    ./dotfiles-links.nix
  ];

  home.packages = with pkgs; [
    git
    #neovim # Don't install this here because it will collide with the `programs.neovim.enable` below
    ripgrep
    fd
    tmux
    curl
    wget
    unzip
  ];

  programs.git.enable = true;
  programs.neovim.enable = true;
  programs.home-manager.enable = true;
}

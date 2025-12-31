{ config, pkgs, ... }:

{
  home.username = "pewing";
  home.homeDirectory = "/home/pewing";
  home.stateVersion = "24.05";

  home.packages = with pkgs; [
    git
    neovim
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

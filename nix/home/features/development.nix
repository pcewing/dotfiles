# This module provides a set of common software development tools for various
# languages. It can be enabled in a role to provide a baseline development
# environment.
{ config, pkgs, lib, ... }:

{
  options.development.enable = lib.mkEnableOption "development tools";

  config = lib.mkIf config.development.enable {
    home.packages = with pkgs; [
      #########
      # Build Systems
      #########
      meson
      ninja

      #########
      # Golang
      #########
      go
      gopls
      delve

      #########
      # Rust
      #########
      rustup

      #########
      # NodeJS
      #########
      nodejs
      nodePackages.npm

      #########
      # Java
      #########
      openjdk

      #########
      # .NET
      #########
      dotnet-sdk
    ];

    # Ensure GOPATH is set
    home.sessionVariables = {
      GOPATH = "$HOME/go";
    };

    # Add Go bin to PATH
    home.sessionPath = [
      "$HOME/go/bin"
    ];
  };
}

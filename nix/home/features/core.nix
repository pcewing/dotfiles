{ config, pkgs, lib, ... }:

let
  py = pkgs.python3.withPackages (ps: with ps; [
    pip
    pynvim
    mpd2
    black
    mypy
    isort
    flake8
    autoflake
    argcomplete
    json5
  ]);
in
{
  imports = [
    ./dotfiles-links.nix
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  nixpkgs.config.allowUnfree = true;

  home.packages = with pkgs; [
    #################################
    # Core utilities
    #################################
    cacert
    wget
    gnupg
    jq
    plocate
    fzf
    nettools
    unzip
    libuchardet
    xz

    ###############################
    # Basic command line utilities
    ###############################
    gnumake
    gcc
    cmake
    meson
    htop
    iotop
    universal-ctags
    ranger
    tmux
    neofetch
    id3v2
    calcurse

    #################
    # C/C++ tooling
    #################
    clang-tools

    #################
    # Search / utils
    #################
    ripgrep

    #################
    # Theming tool
    #################
    flavours

    #################
    # Python environment (ONE interpreter w/ all tools)
    #################
    py

    # Ruff is a Rust tool, top-level package
    ruff
  ];

  # Provide a stable `dot` command that always uses the nix Python env
  home.file.".local/bin/dot" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      exec "${py}/bin/python" "$HOME/dot/cli/dot.py" "$@"
    '';
  };

  # Ensure ~/.local/bin is on PATH so `dot` is found
  home.sessionPath = [
    "$HOME/.local/bin"
  ];

  programs.git.enable = true;
  programs.neovim.enable = true;
  programs.home-manager.enable = true;

  # Optional: generate a static completion file during activation
  home.activation.dotArgcomplete =
    lib.hm.dag.entryAfter ["writeBoundary"] ''
      if [ -x "$HOME/dot/cli/dot.py" ]; then
        mkdir -p "$HOME/.config/bash/completions"
        # Use the same python env as `dot` to guarantee argcomplete is available
        "${py}/bin/register-python-argcomplete" \
          --external-argcomplete-script "$HOME/dot/cli/dot.py" dot \
          > "$HOME/.config/bash/completions/dot"
      fi
    '';
}


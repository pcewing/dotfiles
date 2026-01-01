{ config, pkgs, ... }:

{
  imports = [
    ./dotfiles-links.nix
  ];

  # User-level defaults (safe; still OK if your dotfiles set these too)
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  # Needed for things like steam (and a few other packages you may want later).
  nixpkgs.config.allowUnfree = true;

  home.packages = with pkgs; [
    #################################
    # Core utilities
    #################################
    # TODO: apt-utils?
    cacert # apt: ca-certificates
    #curl # TODO: Don't think we need this here since the bootstrap script installs it system-wide
    wget
    gnupg
    jq
    # TODO: software-properties-common
    # TODO: apt-file
    # TODO: libfuse
    # TODO: Make sure this works
    # “locate” equivalent (note: the database update is typically system-level)
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
    # TODO: Installing both this and `gcc` causes an issue because they both
    # provide the same colliding ld.bfd file. For now, just only install
    # clang-tools but not the full compiler toolchain. We can try to figure out
    # how to have both side-by-side later on or maybe just make a different
    # profile for clang
    #clang
    clang-tools

    #########
    # Python
    #########
    python3
    python3Packages.pip
    python3Packages.pynvim
    python3Packages.mpd2
    python3Packages.black
    python3Packages.mypy
    python3Packages.isort
    python3Packages.flake8
    python3Packages.autoflake
    python3Packages.ruff
    python3Packages.argcomplete
    python3Packages.json5

    #################
    # Search / utils
    #################
    ripgrep

    #################
    # Theming tool
    #################
    flavours
  ];

  programs.git.enable = true;
  programs.neovim.enable = true;
  programs.home-manager.enable = true;
}

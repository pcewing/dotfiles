{ config, pkgs, ... }:

{
  home.username = "pewing";
  home.homeDirectory = "/home/pewing";
  home.stateVersion = "24.05";

  imports = [
    ./dotfiles-links.nix
  ];

  # Needed for things like steam (and a few other packages you may want later).
  nixpkgs.config.allowUnfree = true;

  home.packages = with pkgs; [
    #################################
    # Core utilities (your apt list)
    # TODO: COMMENT CLEANUP
    #################################
    ca-certificates
    curl
    wget
    gnupg
    jq
    unzip
    xz
    fzf
    nettools
    uchardet

    # TODO: Make sure this works
    # “locate” equivalent (note: the database update is typically system-level)
    plocate

    ###############################
    # Basic command line utilities
    ###############################
    gnumake
    gcc
    cmake
    meson
    htop
    iotop
    ripgrep
    fd
    tmux
    universal-ctags
    ranger
    neofetch
    id3v2
    calcurse

    # Editors/terminals
    # neovim is provided by programs.neovim below; don't add pkgs.neovim here.
    rxvt-unicode

    #################
    # C/C++ toolchain
    #################
    clang
    clang-tools

    #########
    # Python
    #########
    # TODO: Let's thoroughly test Python since this is a hairy and important one
    python3
    python3Packages.pip
    python3Packages.pynvim
    python3Packages.python-mpd2

    ########################
    # Desktop / GUI utilities
    # (we’ll later move these to a desktop profile)
    ########################
    font-awesome
    rofi
    dunst
    feh
    sxiv
    nitrogen
    pavucontrol
    picom
    scrot
    gucharmap
    keepassxc
    remmina
    usb-creator-gtk
    i3lock
    meld
    xclip
    wl-clipboard
    xdotool
    kitty
    libwebp

    ########
    # Media
    ########
    inkscape
    mpv
    vlc
    easytag
    blueman

    #########################
    # Music tooling (old script)
    #########################
    mpd
    ncmpcpp
    cava

    #########################
    # “youtube-dl” replacement
    #########################
    yt-dlp

    #########################
    # i3 / bar tooling (old i3gaps step)
    #
    # Note: "i3-gaps" as a separate project is largely obsolete; the gaps
    # patches were merged into i3 years ago. nixpkgs typically just uses i3.
    #########################
    i3
    i3status

    #########################
    # Gaming (old apt section)
    #########################
    steam
    steam-run
  ];

  programs.git.enable = true;
  programs.neovim.enable = true;
  programs.home-manager.enable = true;
}

{ config, pkgs, ... }:

{
  home.username = "pewing";
  home.homeDirectory = "/home/pewing";
  home.stateVersion = "24.05";

  # TODO: These might collide with my `config/env` or other files
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    TERMINAL = "kitty";
  };

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
    nettools # apt: net-tools
    unzip
    libuchardet # apt: uchardet
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
    rxvt-unicode
    flavours
    #ripgrep
    #fd

    #################
    # C/C++ toolchain
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
    # TODO: Let's thoroughly test Python since this is a hairy and important one
    python3
    python3Packages.pip
    python3Packages.pynvim
    #python3Packages.python-mpd2 # TODO: Replace with below?
    python3Packages.mpd2

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
    # TODO: There doesn't appear to be a Nix package for this. We could just
    # install it in the bootstrap script but we only want it on hosts with
    # desktop environments since it's a GTK GUI app. So, figure that out later.
    # Maybe we can just find an alternative app for making bootable USB drives.
    #usb-creator-gtk
    i3lock
    meld
    xclip
    wl-clipboard
    xdotool
    kitty
    #kitty-terminfo TODO: Is this not necessary in Nix?
    libwebp # apt: webp

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

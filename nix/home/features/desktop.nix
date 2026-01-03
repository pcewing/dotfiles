{ pkgs, ... }:

{
  imports = [
    ./python-environment.nix
  ];

  # Declare Python packages needed by desktop
  myPython.packages = with pkgs.python3Packages; [
    py3status
    mpd2
  ];

  home.sessionVariables = {
    TERMINAL = "kitty";
  };

  home.packages = with pkgs; [
    ########################
    # Desktop / GUI utilities
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
    i3lock
    meld
    xclip
    wl-clipboard
    xdotool
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
    # Music tooling (desktop-y)
    #########################
    mpd
    ncmpcpp
    cava

    #########################
    # Video download
    #########################
    yt-dlp

    #########################
    # Proprietary Software
    #########################
    bcompare
  ];
}

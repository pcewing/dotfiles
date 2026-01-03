{ pkgs, ... }:

{
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
    # i3 / bar tooling
    #########################
    py3status

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

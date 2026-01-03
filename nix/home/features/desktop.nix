{ pkgs, nixgl, ... }:

{
  home.sessionVariables = {
    TERMINAL = "kitty";
  };

  home.packages = (with pkgs; [
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
    # i3 / bar tooling
    #########################
    i3
    i3status

    #########################
    # Proprietary Software
    #########################
    bcompare
  ]) ++ [
    ########################
    # nixGL for OpenGL support
    ########################
    nixgl.packages.${pkgs.system}.nixGLIntel
    nixgl.packages.${pkgs.system}.nixGLNvidia
    nixgl.packages.${pkgs.system}.nixVulkanIntel
    nixgl.packages.${pkgs.system}.nixVulkanNvidia
  ];
}

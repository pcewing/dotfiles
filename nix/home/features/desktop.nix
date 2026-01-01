{ pkgs, ... }:
{
  home.packages = with pkgs; [
    rofi
    dunst
    feh
    picom
    scrot
    meld
    xclip
    wl-clipboard
    xdotool
    kitty
    # etc.
  ];
}

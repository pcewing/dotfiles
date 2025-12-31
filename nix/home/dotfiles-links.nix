{ config, lib, ... }:

let
  # core.nix is at ./nix/home/core.nix
  # config/ is at ./config (sibling to nix/)
  # so from ./nix/home/* => ../../config
  dotConfigDir = ../../config;

  link = { dst, srcPath }:
    if lib.hasPrefix ".config/" dst then
      { xdg = true; key = lib.removePrefix ".config/" dst; value = { source = srcPath; }; }
    else
      { xdg = false; key = dst; value = { source = srcPath; }; };

  mk = dstRel: srcRel:
    link { dst = dstRel; srcPath = dotConfigDir + "/${srcRel}"; };

  items = [
    (mk ".Xresources"                      "Xresources")
    (mk ".bash_profile"                    "bash_profile")
    (mk ".bashrc"                          "bashrc")
    (mk ".config/dunst/dunstrc"            "dunstrc")
    (mk ".env"                             "env")
    (mk ".gitconfig"                       "gitconfig")
    (mk ".gvimrc"                          "gvimrc")
    (mk ".config/i3/config"                "i3")
    (mk ".inputrc"                         "inputrc")
    (mk ".config/mpd/mpd.conf"             "mpd")
    (mk ".config/ncmpcpp/bindings"         "ncmpcpp/bindings")
    (mk ".config/ncmpcpp/config"           "ncmpcpp/config")
    (mk ".config/picom/picom.conf"         "picom.conf")
    (mk ".profile"                         "profile")
    (mk ".pulse/daemon.conf"               "pulse/daemon.conf")
    (mk ".config/py3status/config"         "py3status.conf")
    (mk ".config/ranger/rc.conf"           "rangerrc")
    (mk ".config/rofi/config.rasi"         "rofi/config.rasi")
    (mk ".config/rofi/base16.rasi"         "rofi/base16.rasi")
    (mk ".config/sway/config"              "sway")
    (mk ".swaysession"                     "swaysession")
    (mk ".tmux.conf"                       "tmux.conf")
    (mk ".vimrc"                           "vimrc")
    (mk ".xinitrc"                         "xinitrc")
    (mk ".xsession"                        "xsession")

    # directories
    (mk ".config/nvim"                     "nvim")
    (mk ".config/flavours"                 "flavours")

    # individual files under ~/.config
    (mk ".config/kitty/kitty.conf"         "kitty.conf")
    (mk ".config/alacritty/alacritty.yml"  "alacritty/alacritty.yml")
    (mk ".config/alacritty/base16.yml"     "alacritty/base16.yml")
    (mk ".config/alacritty/linux.yml"      "alacritty/linux.yml")
    (mk ".config/wezterm/wezterm.lua"      "wezterm.lua")
  ];

  xdgPairs = builtins.filter (x: x.xdg) items;
  homePairs = builtins.filter (x: !x.xdg) items;

  xdgAttr = lib.listToAttrs (map (x: { name = x.key; value = x.value; }) xdgPairs);
  homeAttr = lib.listToAttrs (map (x: { name = x.key; value = x.value; }) homePairs);
in
{
  xdg.enable = true;

  home.file = homeAttr;
  xdg.configFile = xdgAttr;
}

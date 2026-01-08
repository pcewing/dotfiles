{ config, lib, ... }:

let
    dotConfigDir = ../../../config;

    # Helper to classify a link as XDG-compliant (in .config) or a regular
    # home-relative dotfile.
    link =
        { dst, srcPath }:
        if lib.hasPrefix ".config/" dst then
            {
                xdg = true;
                key = lib.removePrefix ".config/" dst;
                value = {
                    source = srcPath;
                };
            }
        else
            {
                xdg = false;
                key = dst;
                value = {
                    source = srcPath;
                };
            };

    # Helper to create a link item for the `items` list.
    mk =
        dstRel: srcRel:
        link {
            dst = dstRel;
            srcPath = dotConfigDir + "/${srcRel}";
        };

    # List of all files and directories to be linked into the home directory.
    items = [
        (mk ".Xresources" "Xresources")
        (mk ".bash_profile" "bash_profile")
        (mk ".bashrc" "bashrc")
        (mk ".config/Code/User/settings.json" "vscode/settings.json")
        (mk ".config/alacritty/alacritty.yml" "alacritty.yml")
        (mk ".config/alacritty/base16.yml" "alacritty/base16.yml")
        (mk ".config/alacritty/linux.yml" "alacritty/linux.yml")
        (mk ".config/dunst/dunstrc" "dunstrc")
        (mk ".config/i3/config" "i3")
        (mk ".config/kitty/kitty.conf" "kitty.conf")
        (mk ".config/mpd/mpd.conf" "mpd")
        (mk ".config/ncmpcpp/bindings" "ncmpcpp/bindings")
        (mk ".config/ncmpcpp/config" "ncmpcpp/config")
        (mk ".config/picom/picom.conf" "picom.conf")
        (mk ".config/py3status/config" "py3status.conf")
        (mk ".config/ranger/rc.conf" "rangerrc")
        (mk ".config/rofi/base16.rasi" "rofi/base16.rasi")
        (mk ".config/rofi/config.rasi" "rofi/config.rasi")
        (mk ".config/sway/config" "sway")
        (mk ".config/wezterm/wezterm.lua" "wezterm.lua")
        (mk ".env" "env")
        (mk ".gitconfig" "gitconfig")
        (mk ".gvimrc" "gvimrc")
        (mk ".inputrc" "inputrc")
        (mk ".profile" "profile")
        (mk ".pulse/daemon.conf" "pulse/daemon.conf")
        (mk ".swaysession" "swaysession")
        (mk ".tmux.conf" "tmux.conf")
        (mk ".vimrc" "vimrc")
        (mk ".xinitrc" "xinitrc")
        (mk ".xsession" "xsession")

        # directories
        (mk ".config/flavours" "flavours")
        (mk ".config/nvim" "nvim")
    ];

    # Separate items into XDG and home-relative lists.
    xdgPairs = builtins.filter (x: x.xdg) items;
    homePairs = builtins.filter (x: !x.xdg) items;

    # Convert the lists to attribute sets suitable for home-manager options.
    xdgAttr = lib.listToAttrs (
        map (x: {
            name = x.key;
            value = x.value;
        }) xdgPairs
    );
    homeAttr = lib.listToAttrs (
        map (x: {
            name = x.key;
            value = x.value;
        }) homePairs
    );
in
{
    xdg.enable = true;

    home.file = homeAttr;
    xdg.configFile = xdgAttr;
}

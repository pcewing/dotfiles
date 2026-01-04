{ pkgs, lib, ... }:

{
    imports = [ ../lib/python-environment.nix ];

    # Declare Python packages needed by desktop
    myPython.packageFns = [
        (
            ps: with ps; [
                py3status
                # mpd2 is already included from core.nix
            ]
        )
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
        arandr

        # Even though kitty is our primary terminal emulator now, install urxvt as
        # a backup because kitty's dependence on 3D acceleration has been
        # problematic in the past
        rxvt-unicode

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
        (ncmpcpp.override { visualizerSupport = true; })
        cava

        #########################
        # Video download
        #########################
        yt-dlp

        #########################
        # Proprietary Software
        #########################
        bcompare

        #########################
        # System Utilities
        #########################
        ventoy
    ];

    # Make sure mpd runtime directories exist or it will complain on the first
    # startup
    home.activation.createMpdDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p "$HOME/.mpd/playlists" "$HOME/.local/share/mpd"
    '';
}

#!/usr/bin/env bash

# This file makes it easy to test out new themes without mucking with
# Xresources

merge_theme() {
    color00="#16130f" # black
    color08="#5a5047" # black   (light)
    color01="#826d57" # red
    color09="#826d57" # red     (light)
    color02="#57826d" # green
    color10="#57826d" # green   (light)
    color03="#6d8257" # yellow
    color11="#6d8257" # yellow  (light)
    color04="#6d5782" # blue
    color12="#6d5782" # blue    (light)
    color05="#82576d" # magenta
    color13="#82576d" # magenta (light)
    color06="#576d82" # cyan
    color14="#576d82" # cyan    (light)
    color07="#a39a90" # white
    color15="#dbd6d1" # white   (light)

    foreground="$color07"
    background="$color00"
    cursor="$color07"

    xrdb -merge <<EOF
*.foreground:   $foreground
*.background:   $background
*.cursorColor:  $cursor
*.color0:       $color00
*.color8:       $color08
*.color1:       $color01
*.color9:       $color09
*.color2:       $color02
*.color10:      $color10
*.color3:       $color03
*.color11:      $color11
*.color4:       $color04
*.color12:      $color12
*.color5:       $color05
*.color13:      $color13
*.color6:       $color06
*.color14:      $color14
*.color7:       $color07
*.color15:      $color15
EOF
}

merge_theme


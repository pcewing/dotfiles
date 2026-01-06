{ pkgs, ... }:
{
    # IMPROVEMENT: Removed redundant nixpkgs.config.allowUnfree = true since it's
    # already set in core.nix which is always imported alongside gaming.nix

    home.packages = with pkgs; [
        steam
        steam-run

        runelite
    ];
}

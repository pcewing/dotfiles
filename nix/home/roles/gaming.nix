{ pkgs, ... }:
{
    # Allow proprietary packages for gaming (e.g., Steam)
    nixpkgs.config.allowUnfree = true;

    home.packages = with pkgs; [
        steam
        steam-run

        runelite
    ];
}

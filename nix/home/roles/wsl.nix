{ pkgs, ... }:
{
  # TODO
  # Example WSL tweaks; add real ones as you need them.
  home.sessionVariables = {
    BROWSER = "wslview";
  };

  # Often you *don’t* want X11/Wayland stuff here.
}

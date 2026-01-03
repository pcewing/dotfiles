{ config, pkgs, lib, ... }:

{
  options.myPython = {
    packages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "Python packages to include in the unified environment";
    };
  };

  config = {
    # Build a unified Python environment with all requested packages
    home.packages = lib.mkIf (config.myPython.packages != []) [
      (pkgs.python3.withPackages (ps: config.myPython.packages))
    ];
  };
}

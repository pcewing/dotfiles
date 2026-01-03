{ config, pkgs, lib, ... }:

let
  # Collect all Python package functions from features
  allPyPkgs = ps: lib.flatten (map (f: f ps) config.myPython.packageFns);
in
{
  options.myPython = {
    packageFns = lib.mkOption {
      type = lib.types.listOf (lib.types.functionTo (lib.types.listOf lib.types.package));
      default = [];
      description = "List of functions that take python packages and return packages to include";
    };
  };

  config = {
    # Build a unified Python environment with all requested packages
    home.packages = lib.mkIf (config.myPython.packageFns != []) [
      (pkgs.python3.withPackages allPyPkgs)
    ];
  };
}

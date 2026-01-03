{ config, pkgs, lib, ... }:

let
  # Collect all Python package functions from features
  allPyPkgs = ps: lib.flatten (map (f: f ps) config.myPython.packageFns);
  
  # Build the unified Python environment
  pythonEnv = pkgs.python3.withPackages allPyPkgs;
in
{
  options.myPython = {
    packageFns = lib.mkOption {
      type = lib.types.listOf (lib.types.functionTo (lib.types.listOf lib.types.package));
      default = [];
      description = "List of functions that take python packages and return packages to include";
    };
    
    environment = lib.mkOption {
      type = lib.types.package;
      description = "The unified Python environment (read-only)";
      readOnly = true;
    };
  };

  config = {
    # Expose the Python environment for other modules to reference
    myPython.environment = pythonEnv;
    
    # Build a unified Python environment with all requested packages
    home.packages = lib.mkIf (config.myPython.packageFns != []) [
      pythonEnv
    ];
  };
}

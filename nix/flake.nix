{
  description = "Paul's Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixgl = {
      url = "github:nix-community/nixGL";
    };
  };

  outputs = { self, nixpkgs, home-manager, nixgl, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      homeConfigurations = {
        personal-desktop = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ 
            ./home/hosts/personal-desktop.nix
          ];
          extraSpecialArgs = { nixGLPackages = nixgl.packages.${system}; };
        };

        work-desktop = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ 
            ./home/hosts/work-desktop.nix
          ];
          extraSpecialArgs = { nixGLPackages = nixgl.packages.${system}; };
        };

        personal-wsl = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./home/hosts/personal-wsl.nix ];
        };

        work-wsl = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./home/hosts/work-wsl.nix ];
        };

        personal-server = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./home/hosts/personal-server.nix ];
        };

        work-server = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./home/hosts/work-server.nix ];
        };
      };
    };
}

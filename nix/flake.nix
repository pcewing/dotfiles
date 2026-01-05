{
    description = "Paul's Home Manager configuration";

    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

        home-manager = {
            url = "github:nix-community/home-manager/release-24.05";
            inputs.nixpkgs.follows = "nixpkgs";
        };
    };

    outputs =
        {
            self,
            nixpkgs,
            home-manager,
            ...
        }:
        let
            system = "x86_64-linux";
            pkgs = import nixpkgs { inherit system; };

            # Load host definitions from JSON
            hostsData = builtins.fromJSON (builtins.readFile ./hosts.json);

            # Convert role name to module path
            roleToModule = role: ./home/roles/${role}.nix;

            # Generate a home-manager configuration for a single host
            mkHostConfig =
                hostName: hostConfig:
                home-manager.lib.homeManagerConfiguration {
                    inherit pkgs;
                    modules = [
                        {
                            home.username = hostConfig.username;
                            home.homeDirectory = "/home/${hostConfig.username}";
                            home.stateVersion = "24.05";

                            imports = map roleToModule hostConfig.roles;
                        }
                    ];
                };

            # Generate all homeConfigurations from the JSON
            homeConfigurations = builtins.mapAttrs mkHostConfig hostsData.hosts;
        in
        {
            inherit homeConfigurations;
        };
}

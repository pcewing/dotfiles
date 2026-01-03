{ pkgs, ... }:

{
  home.packages = with pkgs; [
    #########
    # Golang
    #########
    go
    gopls
    delve

    #########
    # Rust
    #########
    rustup

    #########
    # NodeJS
    #########
    nodejs
    nodePackages.npm

    #########
    # Java
    #########
    openjdk

    #########
    # .NET
    #########
    dotnet-sdk

    #########
    # Docker
    #########
    docker
    docker-compose
  ];

  # Ensure GOPATH is set
  home.sessionVariables = {
    GOPATH = "$HOME/go";
  };

  # Add Go bin to PATH
  home.sessionPath = [
    "$HOME/go/bin"
  ];
}

{ config, pkgs, lib, ... }:

let
  wpr = pkgs.callPackage ../packages/wpr.nix { };
  nvim-markdown = pkgs.callPackage ../packages/nvim-markdown.nix { };
in
{
  imports = [
    ../lib/dotfiles-links.nix
    ../lib/python-environment.nix
    ../features/development.nix
  ];

  # Enable the development feature
  development.enable = true;

  # Declare Python packages needed by core
  myPython.packageFns = [
    (ps: with ps; [
      pip
      pynvim
      mpd2
      black
      mypy
      isort
      flake8
      autoflake
      argcomplete
      json5
    ])
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  nixpkgs.config.allowUnfree = true;

  home.packages = with pkgs; [
    #################################
    # Core utilities
    #################################
    cacert
    wget
    gnupg
    jq
    plocate
    fzf
    nettools
    unzip
    libuchardet
    xz
    dos2unix

    ###############################
    # Basic command line utilities
    ###############################
    gnumake
    gcc
    cmake
    htop
    iotop
    universal-ctags
    ranger
    tmux
    neofetch
    id3v2
    calcurse
    vim
    tree-sitter

    #################
    # Nix tooling
    #################
    nixfmt-rfc-style

    #################
    # C/C++ tooling
    #################
    clang-tools

    #################
    # Search / utils
    #################
    ripgrep

    #################
    # Theming tool
    #################
    flavours

    # Ruff is a Rust tool, top-level package
    ruff

    #################
    # Custom packages
    #################
    wpr
  ];

  # Provide a stable `dot` command that always uses the unified Python env
  home.file.".local/bin/dot" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      # Find python3 from the unified environment in PATH
      exec python3 "$HOME/dot/cli/dot.py" "$@"
    '';
  };

  # Ensure ~/.local/bin is on PATH so `dot` is found
  home.sessionPath = [
    "$HOME/.local/bin"
  ];

  programs.git.enable = true;

  programs.neovim = {
    enable = true;
    defaultEditor = true;
  
    plugins = with pkgs.vimPlugins; [
      fzf-vim
  
      telescope-nvim
      plenary-nvim
      popup-nvim
  
      nvim-treesitter.withAllGrammars
      # If we want to trim this down, we could do something like this:
      #nvim-treesitter.withPlugins (p: [ p.c p.java ]))
      # And copy what we used to have in our treesitter.lua file. But just installing all grammars is fine for now.
  
      ultisnips
      vim-snippets
  
      nvim-markdown # The custom nvim-markdown plugin
  
      vim-clang-format
      nvim-lspconfig
  
      copilot-vim
      
      base16-vim
      vim-puppet
      vim-go
      vim-csharp
      emmet-vim
      vim-vinegar
      vim-flake8
      vim-glsl
      Jenkinsfile-vim-syntax
      plantuml-syntax
      # This isn't the right name in Nix but I use Cassandra so
      # infrequently I'm just commenting this out. We can fix if we ever need
      # it again.
      #cql-vim
      vim-fugitive
      # Also doesn't appear to have a nix package yet
      #mesonic
  
      nvim-cmp
      lspsaga-nvim
      lualine-nvim
    ];
  
    extraPackages = with pkgs; [
      fzf
      ripgrep
      fd
      clang-tools
      nodejs # needed for copilot + some LSP tooling
    ];
  };

  programs.home-manager.enable = true;

  # Optional: generate a static completion file during activation
  home.activation.dotArgcomplete =
    lib.hm.dag.entryAfter ["writeBoundary"] ''
      if [ -x "$HOME/dot/cli/dot.py" ]; then
        mkdir -p "$HOME/.config/bash/completions"
        # Use the unified Python environment directly
        ${config.myPython.environment}/bin/register-python-argcomplete \
          --external-argcomplete-script "$HOME/dot/cli/dot.py" dot \
          > "$HOME/.config/bash/completions/dot"
      fi
    '';

  # Update flavours base16 schemes and templates on activation
  home.activation.flavoursUpdate =
    lib.hm.dag.entryAfter ["writeBoundary"] ''
      if command -v flavours >/dev/null 2>&1; then
        echo "Updating flavours schemes and templates..."
        # flavours update can be noisy and sometimes fails on first run, so we
        # suppress errors and output
        ${pkgs.flavours}/bin/flavours update all >/dev/null 2>&1 || true
      fi
    '';
}


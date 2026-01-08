{
    config,
    pkgs,
    lib,
    ...
}:

let
    wpr = pkgs.callPackage ../packages/wpr.nix { };
    nvim-markdown = pkgs.callPackage ../packages/nvim-markdown.nix { };
    cql-vim = pkgs.callPackage ../packages/cql-vim.nix { };
    mesonic = pkgs.callPackage ../packages/mesonic.nix { };
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
        (
            ps: with ps; [
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
            ]
        )
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
    home.sessionPath = [ "$HOME/.local/bin" ];

    programs.git.enable = true;

    programs.neovim = {
        enable = true;
        defaultEditor = true;

        plugins = with pkgs.vimPlugins; [
            Jenkinsfile-vim-syntax
            base16-vim
            copilot-vim
            cql-vim
            emmet-vim
            fzf-vim
            lspsaga-nvim
            lualine-nvim
            mesonic
            nvim-cmp
            nvim-lspconfig
            nvim-markdown
            nvim-treesitter.withAllGrammars
            plantuml-syntax
            plenary-nvim
            popup-nvim
            telescope-nvim
            ultisnips
            vim-clang-format
            vim-csharp
            vim-flake8
            vim-fugitive
            vim-glsl
            vim-go
            vim-puppet
            vim-snippets
            vim-vinegar
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
    home.activation.dotArgcomplete = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if [ -x "$HOME/dot/cli/dot.py" ]; then
          mkdir -p "$HOME/.config/bash/completions"
          # Use the unified Python environment directly
          ${config.myPython.environment}/bin/register-python-argcomplete \
            --external-argcomplete-script "$HOME/dot/cli/dot.py" dot \
            > "$HOME/.config/bash/completions/dot"
        fi
    '';

    # Update flavours base16 schemes and templates on activation
    home.activation.flavoursUpdate = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if command -v flavours >/dev/null 2>&1; then
          echo "Updating flavours schemes and templates..."
          # flavours update can be noisy and sometimes fails on first run, so we
          # suppress errors and output
          ${pkgs.flavours}/bin/flavours update all >/dev/null 2>&1 || true
        fi
    '';
}

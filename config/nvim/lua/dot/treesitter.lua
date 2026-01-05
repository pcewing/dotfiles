local Log = require('dot.log')

local M = {}

function M.configure()
    local status, TreesitterConfigs = pcall(require, 'nvim-treesitter.configs')
    if not status  then
        Log.warn('Failed to load nvim-treesitter.configs module')
        return
    end

    TreesitterConfigs.setup({
        highlight = {
            enable = true,
            disable = {
                -- As of 2024-05-21, treesitter syntax highlighting for
                -- Markdown files has been causing problems so just disable it
                -- and use the built-in regex syntax highlighting. I'm doing
                -- this instead of removing it entirely from the list below
                -- because there are warnings in `:checkhealth` for lspsaga if
                -- markdown and markdown_inline aren't installed.
                "markdown",
            },
            additional_vim_regex_highlighting = false,
        },
        indent = {
            enable = false,
            disable = {},
        },
        -- The source of truth for the available parsers lives in this file:
        -- https://github.com/nvim-treesitter/nvim-treesitter/blob/master/lua/nvim-treesitter/parsers.lua
        --
        -- Alternatively, `ensure_installed = "all"` is supported but that
        -- downloads a ton of parsers I don't care about and that were occasionally
        -- causing errors.
        ensure_installed = {
            -- Leave this empty because Nix will install the grammars into the
            -- Nix store and we don't want the Treesitter plugin trying to
            -- install them at runtime because it will fail due to missing
            -- write permissions
        }
    })
end

return M

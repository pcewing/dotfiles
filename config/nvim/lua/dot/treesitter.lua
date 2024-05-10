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
            disable = {},
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
            "bash",
            "c",
            "c_sharp",
            "cmake",
            "commonlisp",
            "cpp",
            "css",
            "csv",
            "disassembly",
            "dockerfile",
            "elixir",
            "erlang",
            "gdscript",
            "git_rebase",
            "gitattributes",
            "gitcommit",
            "git_config",
            "gitignore",
            "go",
            "godot_resource",
            "gomod",
            "gosum",
            "gowork",
            "groovy",
            "hcl",
            "html",
            "ini",
            "java",
            "javascript",
            "json",
            "latex",
            "lua",
            "make",
            -- TODO: This seems to have broken so disable it for now. Between the
            -- default Vim markdown syntax script and the nvim-markdown plugin, we
            -- don't really need this anyways.
            --"markdown",
            "meson",
            "proto",
            "puppet",
            "python",
            "toml",
            "vim",
            "xml",
            "yaml",
        }
    })
end

return M

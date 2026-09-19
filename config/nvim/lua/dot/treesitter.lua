local Log = require('dot.log')

local M = {}

function M.configure()
    -- Load the nvim-treesitter core module
    local status, treesitter = pcall(require, 'nvim-treesitter')
    if not status then
        Log.warn('Failed to load nvim-treesitter module')
        return
    end

    -- Call setup
    treesitter.setup()

    -- The source of truth for the available parsers lives in this file:
    -- https://github.com/nvim-treesitter/nvim-treesitter/blob/master/lua/nvim-treesitter/parsers.lua
    --
    -- Alternatively, `ensure_installed = "all"` is supported but that
    -- downloads a ton of parsers I don't care about and that were occasionally
    -- causing errors.
    local ensure_installed = {
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
        "markdown",
        "markdown_inline",
        "meson",
        "proto",
        "puppet",
        "python",
        "toml",
        "vim",
        "xml",
        "yaml",
    }

    -- Install missing parsers asynchronously
    treesitter.install(ensure_installed)

    -- Enable Native Tree-sitter Highlighting via FileType autocommand
    vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("UserTreesitterConfig", { clear = true }),
        callback = function(args)
            local buf = args.buf
            local ft = vim.bo[buf].filetype

            ---- Keep your 2024-05-21 override: use built-in regex highlighting for Markdown
            --if ft == "markdown" then
            --    vim.sequential_glance_fallback = true -- Optional flag if you handle fallback rules
            --    return
            --end

            -- Check if a valid tree-sitter parser is loaded for this filetype
            local lang = vim.treesitter.language.get_lang(ft) or ft
            local has_parser = pcall(vim.treesitter.language.add, lang)

            if has_parser then
                vim.treesitter.start(buf, lang)
            end
        end,
    })
    -- Central configuration for handling specific filetypes
    local filetype_rules = {
        fzf      = { ignore = true },
        netrw    = { ignore = true },

        -- Example: Apply the fallback flag to markdown (replaces your old commented out logic)
        --markdown = { fallback = true }, 
    }

    -- Enable Native Tree-sitter Highlighting via FileType autocommand
    vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("UserTreesitterConfig", { clear = true }),
        callback = function(args)
            local buf = args.buf
            local ft = vim.bo[buf].filetype

            -- Get the rules matching the current filetype (if any)
            local rule = filetype_rules[ft]

            if rule then
                -- 1. Check if the filetype should be skipped completely
                if rule.ignore then
                    return
                end

                -- 2. Check if the fallback flag should be enabled
                if rule.fallback then
                    vim.sequential_glance_fallback = true
                    return -- Exit early since we are dropping back to standard highlighting
                end
            end

            -- Check if a valid tree-sitter parser is loaded for this filetype
            local lang = vim.treesitter.language.get_lang(ft) or ft
            local has_parser = pcall(vim.treesitter.language.add, lang)

            if has_parser then
                -- Catch internal start exceptions if the underlying binary is corrupt or missing
                local success, err = pcall(vim.treesitter.start, buf, lang)

                if not success then
                    print(string.format(
                        'ERROR: Failed to run treesitter autocmd on filetype "%s". Add to `filetype_rules` if LSP/Highlighting support isn\'t needed.', 
                        ft
                    ))
                end
            end
        end,
    })
  end

return M

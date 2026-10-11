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

    -- Lookup set of parsers we actually expect to be present
    local expected_parsers = {}
    for _, parser in ipairs(ensure_installed) do
        expected_parsers[parser] = true
    end

    -- Install missing parsers asynchronously
    treesitter.install(ensure_installed)

    -- Central configuration for handling specific filetypes
    local filetype_rules = {
        fzf      = { ignore = true },
        netrw    = { ignore = true },
        -- NOTE: `.txt` files are detected as filetype `text`, not `txt`
        text     = { ignore = true },

        -- Example: Apply the fallback flag to markdown (replaces your old commented out logic)
        --markdown = { fallback = true }, 
    }

    -- Enable Native Tree-sitter Highlighting via FileType autocommand
    local treesitter_group = vim.api.nvim_create_augroup("UserTreesitterConfig", { clear = true })
    vim.api.nvim_create_autocmd("FileType", {
        group = treesitter_group,
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

            -- Check if a valid tree-sitter parser is loaded for this filetype.
            --
            -- NOTE: `vim.treesitter.language.add()` does not throw when a parser
            -- is missing, it returns `nil, err`. So the boolean returned by
            -- `pcall` is not a valid "has parser" check on its own.
            local lang = vim.treesitter.language.get_lang(ft) or ft
            local ok, has_parser = pcall(vim.treesitter.language.add, lang)
            has_parser = ok and has_parser == true

            -- Parsers listed in `ensure_installed` are expected to be present, so
            -- failures for those are worth surfacing. A filetype we never asked a
            -- parser for (plain text, json5, ...) is just noise.
            local expected = expected_parsers[lang] == true

            if not has_parser then
                if expected then
                    print(string.format(
                        'ERROR: Treesitter parser "%s" for filetype "%s" was expected but could not be loaded. Try `:TSInstall %s`.',
                        lang, ft, lang
                    ))
                else
                    Log.debug(string.format(
                        'No treesitter parser for filetype "%s" (language "%s"); skipping highlighting',
                        ft, lang
                    ))
                end

                return
            end

            -- Catch internal start exceptions if the underlying binary is corrupt or missing
            local success, err = pcall(vim.treesitter.start, buf, lang)

            if not success then
                if expected then
                    print(string.format(
                        'ERROR: Failed to run treesitter autocmd on filetype "%s": %s',
                        ft, err
                    ))
                else
                    Log.debug(string.format(
                        'Failed to run treesitter autocmd on filetype "%s": %s',
                        ft, err
                    ))
                end
            end
        end,
    })
  end

return M

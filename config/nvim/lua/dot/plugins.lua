local vim = vim
local Plug = vim.fn['plug#']

local Log = require('dot.log')
local Notifications = require('dot.notifications')
local VimPlug = require('dot.vim_plug')

-- Function to list snippets and allow FZF selection
-- Not currently that useful because it shows all snippets and the list is
-- massive and most of them I would never use, like all of the licensing
-- snippets. Maybe find a way to make this better. A simple solution could be
-- to make a regex filter to remove the ones we don't care about.
local function show_snippets()
    local snippets = vim.fn['UltiSnips#SnippetsInCurrentScope'](1) -- Get available snippets

    -- If no snippets available, notify the user
    if vim.tbl_isempty(snippets) then
        print('No snippets available for this filetype.')
        return
    end

    -- Prepare snippets for FZF display
    local fzf_snippets = {}
    for trigger, info in pairs(snippets) do
        local description = info.description or ''
        table.insert(fzf_snippets, trigger .. ' - ' .. description)
    end

    -- Use FZF to select a snippet
    vim.fn['fzf#run']({
        source = fzf_snippets,
        sink = function(choice)
            if not choice then
                return
            end

            local snippet_trigger = choice:match('^(%S+)')
            if not snippet_trigger then
                return
            end

            -- UltiSnips expands the snippet whose trigger sits immediately before
            -- the cursor, so the trigger has to be in the buffer *before* we ask it
            -- to expand. Defer until the FZF window has closed, then insert the
            -- trigger, leave the cursor right after it, and expand.
            vim.schedule(function()
                vim.cmd('startinsert')
                local cursor = vim.api.nvim_win_get_cursor(0)
                local row, col = cursor[1], cursor[2]
                vim.api.nvim_buf_set_text(0, row - 1, col, row - 1, col, { snippet_trigger })
                vim.api.nvim_win_set_cursor(0, { row, col + #snippet_trigger })
                vim.cmd('call UltiSnips#ExpandSnippetOrJump()')
            end)
        end,
    })
end

local M = {}

-- Plugins are declared with Plug() and then configured in the order listed
-- here, so order is significant: a later spec's configure can rely on an earlier
-- one having run. (A string-keyed table iterated with pairs() would run them in
-- a different order on every launch.)
--
-- Each spec has a name (for the log), an init function that declares the
-- plugin's Plug() lines, and optionally an is_enabled function and a configure
-- function that runs after plug#end().
local plugins = {
    {
        name = 'copilot',
        is_enabled = function()
            return os.getenv('NVIM_COPILOT_ENABLED') == '1'
        end,
        init = function()
            Plug('github/copilot.vim')
        end,
        configure = function()
            -- Don't use tab to accept Copilot suggestions which conflicts with
            -- snippets. I'm not sure why `expr` and `replace_keycodes` are
            -- necessary but this is copied from:
            -- https://github.com/github/copilot.vim/blob/53d3091be388ff1edacdb84421ccfa19a446a84d/doc/copilot.txt#L119-L132
            vim.keymap.set('i', '<C-J>', 'copilot#Accept("\\<CR>")', {
                expr = true,
                replace_keycodes = false,
            })
            vim.g.copilot_no_tab_map = true

            vim.g.copilot_filetypes = {
                -- Don't enable copilot in markdown files; it generally makes
                -- bad predictions
                markdown = false,
            }
        end,
    },

    {
        name = 'fzf',
        init = function()
            Plug('junegunn/fzf', { ['dir'] = '~/.fzf', ['do'] = './install --bin' })
            Plug('junegunn/fzf.vim')
        end,
        configure = function()
            -- The one exception to the <leader>f* scheme below; it's used too
            -- often to retire (and matches config/vimrc)
            vim.keymap.set('n', '<Leader>o', '<cmd>Files<CR>', { desc = 'Find file (fzf)' })

            -- Find mappings. The LSP workspace symbol picker, <leader>fm, is
            -- mapped in lsp.lua because it needs an attached server.
            vim.keymap.set('n', '<leader>fo', '<cmd>Files<CR>', { desc = 'Find file (fzf)' })
            vim.keymap.set('n', '<leader>ft', '<cmd>Tags<CR>', { desc = 'Find tag (fzf)' })
            vim.keymap.set('n', '<leader>fg', '<cmd>RG<CR>', { desc = 'Live grep (fzf)' })
            vim.keymap.set('n', '<leader>fb', '<cmd>Buffers<CR>', { desc = 'Find buffer (fzf)' })
            vim.keymap.set('n', '<leader>fh', '<cmd>Helptags<CR>', { desc = 'Find help tag (fzf)' })
            vim.keymap.set('n', '<leader>fs', show_snippets, { desc = 'Find and expand snippet (fzf)' })
            vim.keymap.set('n', '<leader>fw', '<cmd>Windows<CR>', { desc = 'Find window (fzf)' })
            vim.keymap.set('n', '<leader>f<Tab>', require('dot.fzf_tabs').pick, { desc = 'Find tab (fzf)' })
            vim.keymap.set(
                'n',
                '<leader>fc',
                require('dot.compile_commands').pick,
                { desc = 'Choose compile_commands.json for clangd (fzf)' }
            )
        end,
    },

    {
        name = 'nvim_treesitter',
        init = function()
            -- Sometimes the automatic :TSUpdate won't run successfully and then it
            -- won't rerun. If cryptic treesitter errors show up after running
            -- :PlugUpdate, try running :TSUpdate manually
            Plug('nvim-treesitter/nvim-treesitter', { ['do'] = ':TSUpdate' })
        end,
        configure = function()
            local Treesitter = require('dot.treesitter')
            Treesitter.configure()
        end,
    },

    {
        name = 'ultisnips',
        init = function()
            Plug('SirVer/ultisnips')
            Plug('honza/vim-snippets')
        end,
        configure = function()
            vim.g.UltiSnipsExpandTrigger = '<tab>'
            vim.g.UltiSnipsJumpForwardTrigger = '<c-j>'
            vim.g.UltiSnipsJumpBackwardTrigger = '<c-k>'

            vim.keymap.set('n', '<leader>ue', '<cmd>UltiSnipsEdit<CR>', { desc = 'Edit snippets for this filetype' })
        end,
    },

    {
        name = 'clang_format',
        init = function()
            Plug('rhysd/vim-clang-format')
        end,
        configure = function()
            -- Format the current C/C++ file with clang-format (Uses vim-clang-format plugin)
            vim.g['clang_format#detect_style_file'] = 1

            -- This uses ':' rather than <cmd> so that leaving visual mode passes
            -- the selection to the command as a '<,'> range.
            vim.api.nvim_create_autocmd('FileType', {
                -- clear = true keeps a config reload from stacking duplicate
                -- autocmds
                group = vim.api.nvim_create_augroup('dot_clang_format', { clear = true }),
                pattern = { 'c', 'cpp' },
                callback = function(args)
                    vim.keymap.set('x', '<Leader>q', ':ClangFormat<CR>', {
                        buffer = args.buf,
                        desc = 'Format selection with clang-format',
                    })
                end,
            })
        end,
    },

    {
        name = 'lsp_config',
        init = function()
            Plug('neovim/nvim-lspconfig')
        end,
        configure = function()
            local Lsp = require('dot.lsp')
            Lsp.configure()

            vim.keymap.set('n', '<leader>ls', '<cmd>lsp stop<CR>', { desc = 'Stop LSP clients for the buffer' })
            vim.keymap.set('n', '<leader>li', '<cmd>DisplayLSPStatus<CR>', { desc = 'Show LSP status' })
        end,
    },

    {
        name = 'other',
        init = function()
            -- Colorschemes
            Plug('chriskempson/base16-vim')

            Plug('rodjek/vim-puppet')
            Plug('mattn/emmet-vim')
            Plug('tpope/vim-vinegar')
            Plug('nvie/vim-flake8')
            Plug('tikhomirov/vim-glsl')
            Plug('martinda/Jenkinsfile-vim-syntax')
            Plug('aklt/plantuml-syntax')
            Plug('elubow/cql-vim')
            Plug('tpope/vim-fugitive')
            Plug('igankevich/mesonic')
        end,
    },
}

function M.init()
    if not VimPlug.is_installed() then
        Notifications.add('vim-plug is not installed; install it via `:InstallVimPlug`')
        return
    end

    -- Only plugins declared between plug#begin and plug#end are configured
    local enabled = {}

    vim.call('plug#begin')
    for _, plugin in ipairs(plugins) do
        if plugin.is_enabled == nil or plugin.is_enabled() then
            Log.debug('initializing ' .. plugin.name .. ' plugin')
            plugin.init()
            table.insert(enabled, plugin)
        else
            Log.debug('skip initializing ' .. plugin.name .. ' plugin because it is disabled')
        end
    end
    vim.call('plug#end')

    for _, plugin in ipairs(enabled) do
        if plugin.configure ~= nil then
            Log.debug('configuring ' .. plugin.name .. ' plugin')
            plugin.configure()
        end
    end
end

return M

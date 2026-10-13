local vim = vim
local Plug = vim.fn["plug#"]

local Log           = require('dot.log')
local Notifications = require('dot.notifications')
local Util          = require('dot.util')
local VimPlug       = require('dot.vim_plug')

-- Function to list snippets and allow FZF selection
-- Not currently that useful because it shows all snippets and the list is
-- massive and most of them I would never use, like all of the licensing
-- snippets. Maybe find a way to make this better. A simple solution could be
-- to make a regex filter to remove the ones we don't care about.
local function show_snippets()
  local snippets = vim.fn["UltiSnips#SnippetsInCurrentScope"](1)  -- Get available snippets

  -- If no snippets available, notify the user
  if vim.tbl_isempty(snippets) then
    print("No snippets available for this filetype.")
    return
  end

  -- Prepare snippets for FZF display
  local fzf_snippets = {}
  for trigger, info in pairs(snippets) do
    local description = info.description or ""
    table.insert(fzf_snippets, trigger .. " - " .. description)
  end

  -- Use FZF to select a snippet
  vim.fn["fzf#run"]({
    source = fzf_snippets,
    sink = function(choice)
      if not choice then
        return
      end

      local snippet_trigger = choice:match("^(%S+)")
      if not snippet_trigger then
        return
      end

      -- UltiSnips expands the snippet whose trigger sits immediately before
      -- the cursor, so the trigger has to be in the buffer *before* we ask it
      -- to expand. Defer until the FZF window has closed, then insert the
      -- trigger, leave the cursor right after it, and expand.
      vim.schedule(function()
        vim.cmd("startinsert")
        local cursor = vim.api.nvim_win_get_cursor(0)
        local row, col = cursor[1], cursor[2]
        vim.api.nvim_buf_set_text(0, row - 1, col, row - 1, col, { snippet_trigger })
        vim.api.nvim_win_set_cursor(0, { row, col + #snippet_trigger })
        vim.cmd("call UltiSnips#ExpandSnippetOrJump()")
      end)
    end
  })
end

local M = {}

local plugins = {
    copilot = {
        is_enabled = function()
            return os.getenv("NVIM_COPILOT_ENABLED") == "1"
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
                replace_keycodes = false
            })
            vim.g.copilot_no_tab_map = true

            vim.g.copilot_filetypes = {
                -- Don't enable copilot in markdown files; it generally makes
                -- bad predictions
                markdown = false
            }
        end
    },

    fzf = {
        init = function()
            Plug('junegunn/fzf', { ['dir'] = '~/.fzf', ['do'] = './install --bin' })
            Plug('junegunn/fzf.vim')
        end,
        configure = function()
            -- We should remove this eventually in favor of the below
            vim.keymap.set('n', '<Leader>o', '<cmd>Files<CR>', { desc = 'Find file (fzf)' })

            vim.keymap.set('n', '<leader>ft', '<cmd>Tags<CR>', { desc = 'Find tag (fzf)' })
            vim.keymap.set('n', '<leader>fo', '<cmd>Files<CR>', { desc = 'Find file (fzf)' })
            vim.keymap.set('n', '<leader>fs', show_snippets, { desc = 'Find and expand snippet (fzf)' })
        end
    },

    telescope = {
        init = function()
            Plug('nvim-telescope/telescope.nvim')
        end,
        configure = function()
            vim.keymap.set('n', '<leader>tf', '<cmd>Telescope find_files<CR>', { desc = 'Find file (Telescope)' })
            vim.keymap.set('n', '<leader>tt', '<cmd>Telescope tags<CR>', { desc = 'Find tag (Telescope)' })
            vim.keymap.set('n', '<leader>ts', '<cmd>Telescope lsp_dynamic_workspace_symbols<CR>', { desc = 'Find LSP workspace symbol (Telescope)' })
            vim.keymap.set('n', '<leader>tg', '<cmd>Telescope live_grep<CR>', { desc = 'Live grep (Telescope)' })
            vim.keymap.set('n', '<leader>tb', '<cmd>Telescope buffers<CR>', { desc = 'Find buffer (Telescope)' })
            vim.keymap.set('n', '<leader>th', '<cmd>Telescope help_tags<CR>', { desc = 'Find help tag (Telescope)' })
        end
    },

    nvim_treesitter = {
        init = function()
            -- Sometimes the automatic :TSUpdate won't run successfully and then it
            -- won't rerun. If cryptic treesitter errors show up after running
            -- :PlugUpdate, try running :TSUpdate manually
            Plug('nvim-treesitter/nvim-treesitter', { ['do'] = ':TSUpdate'})
        end,
        configure = function()
            local Treesitter = require('dot.treesitter')
            Treesitter.configure()
        end
    },

    ultisnips = {
        init = function()
            Plug('SirVer/ultisnips')
            Plug('honza/vim-snippets')
        end,
        configure = function()
            vim.g.UltiSnipsExpandTrigger = "<tab>"
            vim.g.UltiSnipsJumpForwardTrigger = "<c-j>"
            vim.g.UltiSnipsJumpBackwardTrigger = "<c-k>"

            vim.keymap.set('n', '<leader>ue', '<cmd>UltiSnipsEdit<CR>', { desc = 'Edit snippets for this filetype' })
        end
    },

    clang_format = {
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
        end
    },

    lsp_config = {
        init = function()
            Plug('neovim/nvim-lspconfig')
        end,
        configure = function()
            local Lsp = require('dot.lsp')
            Lsp.configure()

            vim.keymap.set('n', '<leader>ls', '<cmd>LspStop<CR>', { desc = 'Stop LSP clients' })
        end
    },

    other = {
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
            Plug('nvim-lua/plenary.nvim')
        end
    },
}

function M.init()
    if not VimPlug.is_installed() then
        Notifications.add("vim-plug is not installed; install it via `:InstallVimPlug`")
        return
    end

    vim.call('plug#begin')

    for plugin_name, plugin in pairs(plugins) do
        M._init_plugin(plugin_name, plugin)
    end

    vim.call('plug#end')

    for plugin_name, plugin in pairs(plugins) do
        M._configure_plugin(plugin_name, plugin)
    end
end

function M._init_plugin(plugin_name, plugin)
    if plugin.is_enabled ~= nil and not plugin.is_enabled() then
        Log.debug('skip initializing ' .. plugin_name .. ' plugin because it is disabled')
        return
    end

    Log.debug('initializing ' .. plugin_name .. ' plugin')

    if plugin.init == nil then
        Log.warn('plugin ' .. plugin_name .. ' has no init function')
        Notifications.add('plugin ' .. plugin_name .. ' has no init function')
        return
    end

    local init_result = plugin.init()
    if init_result == nil or init_result == true then
        plugin.initialized = true
    end
end

function M._configure_plugin(plugin_name, plugin)
    if plugin.initialized == nil or not plugin.initialized then
        Log.debug('skip configuring ' .. plugin_name .. ' plugin because it is not initialized')
        return
    end

    Log.debug('configuring ' .. plugin_name .. ' plugin')

    if plugin.configure ~= nil then
        plugin.configure()
    end
end

return M

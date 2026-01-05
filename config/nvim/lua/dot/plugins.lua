local vim = vim

local Log           = require('dot.log')
local Map           = require('dot.map')
local Notifications = require('dot.notifications')
local Util          = require('dot.util')

-- Function to list snippets and allow FZF selection
-- Not currently that useful because it shows all snippets and the list is
-- massive and most of them I would never use, like all of the licensing
-- snippets. Maybe find a way to make this better. A simple solution could be
-- to make a regex filter to remove the ones we don't care about.
function ShowSnippets()
  local filetype = vim.bo.filetype  -- Get the current filetype
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
      if choice then
        local snippet_trigger = choice:match("^(%S+)")
        vim.cmd("call UltiSnips#ExpandSnippetOrJump()")
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(snippet_trigger, true, false, true), 'm', true)
      end
    end
  })
end

local M = {}

local plugins = {
    copilot = {
        is_enabled = function()
            return os.getenv("NVIM_COPILOT_ENABLED") == "1"
        end,
        configure = function()
            -- Don't use tab to accept Copilot suggestions which conflicts with
            -- snippets. Not using my Map.imap() function here because it
            -- doesn't support passing through the `replace_keycodes` and `expr`
            -- options. (TODO: Add that support)
            -- I'm not sure why those are necessary but this is copied from:
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
        configure = function()
            -- We should remove this eventually in favor of the below
            Map.nnoremap('<Leader>o', ':Files<CR>')

            Map.nnoremap('<leader>ft', ':Tags<cr>')
            Map.nnoremap('<leader>fo', ':Files<cr>')

            -- TODO: Copy/pasted from ChatGPT, clean up to use the Map module
            -- like above
            -- Map the function to a keybinding (e.g., <leader>s)
            vim.api.nvim_set_keymap("n", "<leader>fs", "<cmd>lua ShowSnippets()<CR>", { noremap = true, silent = true })
        end
    },

    telescope = {
        configure = function()
            Map.nnoremap('<leader>tf', ':Telescope find_files<cr>')
            Map.nnoremap('<leader>tt', ':Telescope tags<cr>')
            Map.nnoremap('<leader>ts', ':Telescope lsp_dynamic_workspace_symbols<cr>')
            Map.nnoremap('<leader>tg', ':Telescope live_grep<cr>')
            Map.nnoremap('<leader>tb', ':Telescope buffers<cr>')
            Map.nnoremap('<leader>th', ':Telescope help_tags<cr>')
        end
    },

    nvim_treesitter = {
        configure = function()
            local Treesitter = require('dot.treesitter')
            Treesitter.configure()
        end
    },

    ultisnips = {
        configure = function()
            vim.g.UltiSnipsExpandTrigger = "<tab>"
            vim.g.UltiSnipsJumpForwardTrigger = "<c-j>"
            vim.g.UltiSnipsJumpBackwardTrigger = "<c-k>"

            Map.nnoremaps('<leader>ue', ':UltiSnipsEdit<CR>')

        end
    },

    nvim_markdown = {
        configure = function()
            vim.g.vim_markdown_frontmatter = 1

            -- This is <tab> by default which conflicts with UltiSnips
            -- TODO: Should we only do this in markdown files?
            Map.imap('<Plug>', '<Plug>Markdown_Jump')
        end
    },

    clang_format = {
        configure = function()
            -- Format the current C/C++ file with clang-format (Uses vim-clang-format plugin)
            vim.g['clang_format#detect_style_file'] = 1
            Map.ft_vnoremap('c,cpp', '<Leader>q', ':ClangFormat<CR>')
        end
    },

    lsp_config = {
        configure = function()
            local LspClangd = require('dot.lsp_clangd')
            local LspGopls = require('dot.lsp_gopls')
            local LspJedi = require('dot.lsp_jedi')

            LspClangd.configure()
            LspGopls.configure()
            LspJedi.configure()

            Map.nnoremap('<leader>ls', ':LspStop<cr>')
        end
    },
}

function M.init()
    for plugin_name, plugin in pairs(plugins) do
        if plugin.is_enabled ~= nil and not plugin.is_enabled() then
            Log.debug('skip configuring ' .. plugin_name .. ' plugin because it is disabled')
        else
            Log.debug('configuring ' .. plugin_name .. ' plugin')
            if plugin.configure ~= nil then
                plugin.configure()
            end
        end
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

    init_result = plugin.init()
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

local vim = vim
local Plug = vim.fn["plug#"]

local Log           = require('dot.log')
local Map           = require('dot.map')
local Notifications = require('dot.notifications')
local Util          = require('dot.util')
local VimPlug       = require('dot.vim_plug')

local M = {}

local plugins = {
--    copilot = {
--        init = function()
--            if os.getenv("NVIM_COPILOT_ENABLED") == "1" then
--                Plug('github/copilot.vim')
--                Log.info("copilot plugin enabled")
--            else
--                Log.info("copilot plugin disabled")
--            end
--        end,
--        configure = function()
--            if os.getenv("NVIM_COPILOT_ENABLED") == "1" then
--                Log.info("configuring copilot plugin")
--                vim.g.copilot_filetypes = {
--                    -- Don't enable copilot in markdown files; it generally makes
--                    -- bad predictions and conflicts with UltiSnips tab completion
--                    markdown = false
--                }
--            end
--        end
--    },

    fzf = {
        init = function()
            Plug('junegunn/fzf', { ['dir'] = '~/.fzf', ['do'] = './install --bin' })
            Plug('junegunn/fzf.vim')
        end,
        configure = function()
            -- We should remove this eventually in favor of the below
            Map.nnoremap('<Leader>o', ':Files<CR>')

            Map.nnoremap('<leader>ft', ':Tags<cr>')
            Map.nnoremap('<leader>fo', ':Files<cr>')
        end
    },

    telescope = {
        init = function()
            Plug('nvim-telescope/telescope.nvim')
        end,
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

            Map.nnoremaps('<leader>ue', ':UltiSnipsEdit<CR>')
        end
    },

    nvim_markdown = {
        init = function()
            Plug('ixru/nvim-markdown')
        end,
        configure = function()
            vim.g.vim_markdown_frontmatter = 1

            -- This is <tab> by default which conflicts with UltiSnips
            -- TODO: Should we only do this in markdown files?
            Map.imap('<Plug>', '<Plug>Markdown_Jump')
        end
    },

    clang_format = {
        init = function()
            Plug('rhysd/vim-clang-format')
        end,
        configure = function()
            -- Format the current C/C++ file with clang-format (Uses vim-clang-format plugin)
            vim.g['clang_format#detect_style_file'] = 1
            Map.ft_vnoremap('c,cpp', '<Leader>q', ':ClangFormat<CR>')
        end
    },

    lsp_config = {
        init = function()
            Plug('neovim/nvim-lspconfig')
        end,
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

    other = {
        init = function()
            -- Colorschemes
            Plug('chriskempson/base16-vim')

            Plug('rodjek/vim-puppet')
            Plug('fatih/vim-go')
            Plug('OrangeT/vim-csharp')
            Plug('mattn/emmet-vim')
            Plug('tpope/vim-vinegar')
            Plug('nvie/vim-flake8')
            Plug('tikhomirov/vim-glsl')
            Plug('martinda/Jenkinsfile-vim-syntax')
            Plug('aklt/plantuml-syntax')
            Plug('elubow/cql-vim')
            Plug('tpope/vim-fugitive')
            Plug('igankevich/mesonic')
            Plug('hrsh7th/nvim-cmp')
            Plug('nvim-lua/popup.nvim')
            Plug('nvim-lua/plenary.nvim')
            Plug('glepnir/lspsaga.nvim')
            Plug('hoob3rt/lualine.nvim')
        end
    },
}

function M.init()
    if not VimPlug.is_installed() then
        Notifications.add("vim-plug is not installed; install it via `:lua install_vim_plug()`")
        return
    end

    -- Ever since switching from init.vim to init.lua, it doesn't seem like
    -- Neovim autoloads the plug.vim file anymore. I'm not sure why and don't
    -- have time right now to dig into it so just manually source it for now.
    VimPlug.source()

    vim.call('plug#begin')

    for plugin_name, plugin in pairs(plugins) do
        if plugin.init then
            plugin.init()
        end
    end

    vim.call('plug#end')

    for plugin_name, plugin in pairs(plugins) do
        if plugin.configure then
            plugin.configure()
        end
    end
end

return M

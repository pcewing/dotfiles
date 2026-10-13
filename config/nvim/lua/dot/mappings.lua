local Util = require('dot.util')

local M = {}

function M._tabs()
    -- Open current file in a second tab and make it the last tab
    vim.keymap.set('n', '<leader><tab>c', '<cmd>tab split | tabmove<CR>', { desc = 'Open file in a new last tab' })

    -- Fuzzy find opener for windows/tabs
    vim.keymap.set('n', '<leader><tab>o', '<cmd>Windows<CR>', { desc = 'Find window (fzf)' })

    -- Next/Previous
    vim.keymap.set('n', '<leader><tab>n', '<cmd>tabnext<CR>', { desc = 'Next tab' })
    vim.keymap.set('n', '<leader><tab>p', '<cmd>tabprevious<CR>', { desc = 'Previous tab' })

    -- Close tabs to right
    vim.keymap.set('n', '<leader><tab>q', '<cmd>CloseTabsToRight<CR>', { desc = 'Close tabs to the right' })

    -- Tab navigation
    vim.keymap.set('n', '<A-F1>', '1gt', { desc = 'Go to tab 1' })
    vim.keymap.set('n', '<A-F2>', '2gt', { desc = 'Go to tab 2' })
    vim.keymap.set('n', '<A-F3>', '3gt', { desc = 'Go to tab 3' })
    vim.keymap.set('n', '<A-F4>', '4gt', { desc = 'Go to tab 4' })
    vim.keymap.set('n', '<A-F5>', '5gt', { desc = 'Go to tab 5' })
    vim.keymap.set('n', '<A-F6>', '6gt', { desc = 'Go to tab 6' })
    vim.keymap.set('n', '<A-F7>', '7gt', { desc = 'Go to tab 7' })
    vim.keymap.set('n', '<A-F8>', '8gt', { desc = 'Go to tab 8' })
    vim.keymap.set('n', '<A-F9>', '9gt', { desc = 'Go to tab 9' })
    vim.keymap.set('n', '<A-F0>', '10gt', { desc = 'Go to tab 10' })

    -- Tab navigation alternative
    vim.keymap.set('n', '<leader>1', '1gt', { desc = 'Go to tab 1' })
    vim.keymap.set('n', '<leader>2', '2gt', { desc = 'Go to tab 2' })
    vim.keymap.set('n', '<leader>3', '3gt', { desc = 'Go to tab 3' })
    vim.keymap.set('n', '<leader>4', '4gt', { desc = 'Go to tab 4' })
    vim.keymap.set('n', '<leader>5', '5gt', { desc = 'Go to tab 5' })
    vim.keymap.set('n', '<leader>6', '6gt', { desc = 'Go to tab 6' })
    vim.keymap.set('n', '<leader>7', '7gt', { desc = 'Go to tab 7' })
    vim.keymap.set('n', '<leader>8', '8gt', { desc = 'Go to tab 8' })
    vim.keymap.set('n', '<leader>9', '9gt', { desc = 'Go to tab 9' })
    vim.keymap.set('n', '<leader>0', '10gt', { desc = 'Go to tab 10' })
end

function M._buffers()
    vim.keymap.set('n', '<Leader>bn', '<cmd>bn<CR>', { desc = 'Next buffer' })
    vim.keymap.set('n', '<Leader>bp', '<cmd>bp<CR>', { desc = 'Previous buffer' })
    vim.keymap.set('n', '<Leader>bf', ':n<Space>', { desc = 'Edit file(s) (:next)' })
    vim.keymap.set('n', '<Leader>bd', '<cmd>bd<CR>', { desc = 'Delete buffer' })
    vim.keymap.set('n', '<leader>bl', ':ls<CR>:buffer<Space>', { desc = 'List buffers and pick one' })

    -- TODO: This has nothing to do with buffers
    vim.keymap.set('n', '<Leader>be', '<cmd>Ex<CR>', { desc = 'Open file explorer (netrw)' })
end

function M._quickfix()
    vim.keymap.set('n', '<Leader>cn', '<cmd>cn<CR>', { desc = 'Next quickfix item' })
    vim.keymap.set('n', '<Leader>cp', '<cmd>cp<CR>', { desc = 'Previous quickfix item' })
    vim.keymap.set('n', '<Leader>co', '<cmd>copen<CR>', { desc = 'Open quickfix list' })
    vim.keymap.set('n', '<Leader>cc', '<cmd>cclose<CR>', { desc = 'Close quickfix list' })
end

-- TODO: We can probably delete these; I very rarely remember to use them
function M._syntax()
    vim.keymap.set('n', '<leader>ssx', ':set syntax=', { desc = 'Set syntax' })
    vim.keymap.set('n', '<leader>ssg', '<cmd>set syntax=groovy<CR>', { desc = 'Set syntax to groovy' })
end

function M._resize()
    -- Resize current focused window
    vim.keymap.set('n', '<leader><Up>', '<cmd>resize +5<CR>', { desc = 'Increase window height' })
    vim.keymap.set('n', '<leader><Down>', '<cmd>resize -5<CR>', { desc = 'Decrease window height' })
    vim.keymap.set('n', '<leader><Right>', '<cmd>vertical resize +5<CR>', { desc = 'Increase window width' })
    vim.keymap.set('n', '<leader><Left>', '<cmd>vertical resize -5<CR>', { desc = 'Decrease window width' })
end

function M._misc()
    -- Run gmake
    vim.keymap.set('n', '<Leader>m', '<cmd>make<CR>', { desc = 'Run :make' })

    -- Generate ctags
    vim.keymap.set('n', '<Leader>[', '<cmd>!ctags -R<CR>', { desc = 'Generate ctags' })

    -- Save out all buffers
    vim.keymap.set('n', '<leader>w', '<cmd>wa<CR>', { desc = 'Save all buffers' })

    -- Clear search highlighting
    vim.keymap.set('n', '<leader><Esc>', '<cmd>noh<CR>', { desc = 'Clear search highlighting' })

    -- Print the current file path
    vim.keymap.set('n', '<leader>p', '<cmd>echo @%<CR>', { desc = 'Print current file path' })

    -- Copy file path and line number of current line to clipboard
    vim.keymap.set('n', '<leader>y', Util.copy_file_and_line, { desc = 'Copy file:line to clipboard' })

    -- Copy visual selection to clipboard as a Markdown code snippet. This uses
    -- ':' rather than <cmd> so that leaving visual mode passes the selection
    -- to the command as a '<,'> range.
    vim.keymap.set('x', 'Y', ':CopyCodeSnippet<CR>', { desc = 'Copy selection as Markdown snippet' })

    -- Execute normal command on visual selection
    vim.keymap.set('x', '<leader>n', ':normal<Space>', { desc = 'Run :normal on selection' })

    -- Format the current Python file with black
    vim.api.nvim_create_autocmd('FileType', {
        -- clear = true keeps a config reload from stacking duplicate autocmds
        group = vim.api.nvim_create_augroup('dot_mappings', { clear = true }),
        pattern = 'python',
        callback = function(args)
            vim.keymap.set('n', '<Leader>q', Util.format_current_python_file, {
                buffer = args.buf,
                desc = 'Format file with black',
            })
        end,
    })
end

function M.init()
    -- Set the Leader key. I leave the leader key as '\' and remap ' ' to it
    -- instead of setting ' ' as the leader. This makes showcmd more useful.
    -- remap = true is required so that the resulting <Leader> keypress
    -- triggers the <Leader> mappings.
    vim.keymap.set('', '<Space>', '<Leader>', { remap = true, desc = 'Leader' })

    M._tabs()
    M._buffers()
    M._quickfix()
    M._syntax()
    M._resize()
    M._misc()

    -- Reload/edit config. <leader>x opens the repo's copy rather than
    -- stdpath('config'): on Windows the config is copied there read-only by
    -- `dot links init`, and edits belong in the repo.
    vim.keymap.set('n', '<leader>x', '<cmd>e ~/dot/config/nvim/init.lua<CR>', { desc = 'Edit Neovim config' })
    vim.keymap.set('n', '<leader>r', Util.reload_config, { desc = 'Reload Neovim config' })
end

return M

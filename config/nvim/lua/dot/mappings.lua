local Map = require('dot.map')

local M = {}

function M._tabs()
    -- Open current file in a second tab and make it the last tab
    Map.nnoremap('<leader><tab>c', ':tab split<CR>:tabm<CR>')

    -- Fuzzy find opener for windows/tabs
    Map.nnoremap('<leader><tab>o', ':Windows<cr>')

    -- Next/Previous
    Map.nnoremap('<leader><tab>n', ':tabnext<cr>')
    Map.nnoremap('<leader><tab>p', ':tabprevious<cr>')

    -- Close tabs to right
    Map.nnoremap('<leader><tab>q', ':CloseTabsToRight<cr>')

    -- Tab navigation
    Map.nnoremap('<A-F1>', '1gt')
    Map.nnoremap('<A-F2>', '2gt')
    Map.nnoremap('<A-F3>', '3gt')
    Map.nnoremap('<A-F4>', '4gt')
    Map.nnoremap('<A-F5>', '5gt')
    Map.nnoremap('<A-F6>', '6gt')
    Map.nnoremap('<A-F7>', '7gt')
    Map.nnoremap('<A-F8>', '8gt')
    Map.nnoremap('<A-F9>', '9gt')
    Map.nnoremap('<A-F0>', '10gt')

    -- Tab navigation alternative
    Map.nnoremap('<leader>1', '1gt')
    Map.nnoremap('<leader>2', '2gt')
    Map.nnoremap('<leader>3', '3gt')
    Map.nnoremap('<leader>4', '4gt')
    Map.nnoremap('<leader>5', '5gt')
    Map.nnoremap('<leader>6', '6gt')
    Map.nnoremap('<leader>7', '7gt')
    Map.nnoremap('<leader>8', '8gt')
    Map.nnoremap('<leader>9', '9gt')
    Map.nnoremap('<leader>0', '10gt')
end

function M._buffers()
    Map.nnoremap('<Leader>bn', ':bn<CR>')
    Map.nnoremap('<Leader>bp', ':bp<CR>')
    Map.nnoremap('<Leader>bf', ':n<Space>')
    Map.nnoremap('<Leader>bd', ':bd<CR>')
    Map.nnoremap('<leader>bl', ':ls<cr>:buffer<space>')

    -- TODO: This has nothing to do with buffers
    Map.nnoremap('<Leader>be', ':Ex<CR>')
end

function M._quickfix()
    Map.nnoremap('<Leader>cn', ':cn<CR>')
    Map.nnoremap('<Leader>cp', ':cp<CR>')
    Map.nnoremap('<Leader>co', ':copen<CR>')
    Map.nnoremap('<Leader>cc', ':cclose<CR>')
end

-- TODO: We can probably delete these; I very rarely remember to use them
function M._syntax()
    Map.nnoremap('<leader>ssx', ':set syntax=')
    Map.nnoremap('<leader>ssg', ':set syntax=groovy<cr>')
end

function M._resize()
    -- Resize current focused window
    Map.nnoremaps('<leader><Up>', ':resize +5<cr>')
    Map.nnoremaps('<leader><Down>', ':resize -5<cr>')
    Map.nnoremaps('<leader><Right>', ':vertical resize +5<cr>')
    Map.nnoremaps('<leader><Left>', ':vertical resize -5<cr>')
end

function M._misc()
    -- Run gmake
    Map.nnoremap('<Leader>m', ':make<CR>')

    -- Generate ctags
    Map.nnoremap('<Leader>[', ':!ctags -R<CR>')

    -- Save out all buffers
    Map.nnoremaps('<leader>w', ':wa<cr>')

    -- Clear search highlighting
    Map.nnoremaps('<leader><esc>', ':noh<cr>')

    -- Print the current file path
    Map.nnoremaps('<leader>p', ':echo @%<cr>')

    -- Copy file path and line number of current line to clipboard
    Map.nnoremaps('<leader>y', ':lua copy_file_and_line()<cr>')

    -- Execute normal command on visual selection
    Map.xnoremap('<leader>n', ':normal<space>')

    -- Format the current Python file with black
    Map.ft_nnoremap('python', '<Leader>q', ':lua format_current_python_file()<CR>')
end

function M.init()
    -- Set the Leader key. I leave the leader key as '\' and remap ' ' to it
    -- instead of setting ' ' as the leader. This makes showcmd more useful.
    Map.map('<Space>', '<Leader>')

    M._tabs()
    M._buffers()
    M._quickfix()
    M._syntax()
    M._resize()
    M._misc()

    -- Reload/edit config
    Map.nnoremaps('<leader>x', ':e ~/dot/config/nvim/init.lua<cr>')
    Map.nnoremaps('<leader>r', ':lua reload_config()<CR>')
end

return M

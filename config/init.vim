lua <<EOF

vim.opt.number = true                       -- Show line numbers
vim.opt.backspace = "indent,eol,start"      -- Make backspace behave as expected in insert mode
vim.opt.history = 1000                      -- Increase :cmdline history
vim.opt.showcmd = true                      -- Show incomplete commands
vim.opt.showmode = true                     -- Show current mode
vim.opt.gcr = "a:blinkon0"                  -- Disable cursor blink
vim.opt.visualbell = true                   -- No sounds
vim.opt.autoread = true                     -- Reload files changed outside vim
vim.opt.autowrite = true                    -- Write the file on :make
vim.opt.hidden = false                      -- Hide buffer instead of closing it
vim.opt.splitright = true                   -- When splitting vertically, the new pane should be on the right
vim.opt.splitbelow = true                   -- When splitting horizontally, the new pane should be on the bottom
vim.opt.ruler = true                        -- Show the line & column number at cursor
vim.opt.pastetoggle = "<F2>"                -- See: http://vim.wikia.com/wiki/Toggle_auto-indenting_for_code_paste
vim.opt.clipboard = "unnamed,unnamedplus"   -- Use system clipboard if possible
vim.opt.cursorline = true                   -- Add a visual indicator to the line the cursor is on
vim.opt.joinspaces = false                  -- Don't insert an extra space after periods when joining lines

-- Indentation
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.smarttab = true
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.tabstop = 4
vim.opt.expandtab = true

EOF

if has('nvim')
    set laststatus=3              " Use global status line (Only supported in nvim 0.7+)
else
    set laststatus=2              " Always display the status line
endif

lua <<EOF

-- Set the Leader key. I leave the leader key as '\' and remap ' ' to it
-- instead of setting ' ' as the leader. This is so that showcmd is actually
-- useful.
--map <Space> <Leader>
vim.keymap.set(' ', '<Space>', '<Leader>')

EOF


" Install vim-plug automatically on Linux if it isn't already
if has('unix')
    if has('nvim')
        if empty(glob('~/.local/share/nvim/site/autoload/plug.vim'))
            silent !curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs
                \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
            autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
        endif
    else
        if empty(glob('~/.vim/autoload/plug.vim'))
            silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
                \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
            autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
        endif
    endif
endif

filetype plugin on

" Load Plugins
call plug#begin('~/.config/nvim/plugged')

" Colorschemes
Plug 'https://github.com/dracula/vim.git'
"Plug 'joshdick/onedark.vim'

Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --bin' }
Plug 'junegunn/fzf.vim'
"Plug 'elixir-lang/vim-elixir'
"Plug 'slashmili/alchemist.vim'
"Plug 'editorconfig/editorconfig-vim'
"Plug 'Valloric/YouCompleteMe'

Plug 'fatih/vim-go'
Plug 'OrangeT/vim-csharp'
Plug 'mattn/emmet-vim'
Plug 'tpope/vim-vinegar'
Plug 'nvie/vim-flake8'
Plug 'tikhomirov/vim-glsl'
Plug 'martinda/Jenkinsfile-vim-syntax'
Plug 'aklt/plantuml-syntax'
Plug 'elubow/cql-vim'
Plug 'tpope/vim-fugitive'
Plug 'sirver/UltiSnips'
Plug 'honza/vim-snippets'
Plug 'igankevich/mesonic'
Plug 'rhysd/vim-clang-format'

if has('nvim')
    " New plugins to use neovim 0.5 features
    Plug 'neovim/nvim-lspconfig'
    Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
    Plug 'nvim-lua/completion-nvim'
    Plug 'nvim-lua/popup.nvim'
    Plug 'nvim-lua/plenary.nvim'
    Plug 'glepnir/lspsaga.nvim'
    Plug 'hoob3rt/lualine.nvim'
    Plug 'nvim-telescope/telescope.nvim'
endif

call plug#end()

" vim-clang-format
let g:clang_format#detect_style_file = 1
autocmd FileType c,cpp vnoremap <buffer><Leader>q :ClangFormat<CR>

" UltiSnips
let g:UltiSnipsExpandTrigger="<c-space>"
let g:UltiSnipsJumpForwardTrigger="<c-b>"
let g:UltiSnipsJumpBackwardTrigger="<c-z>"
nnoremap <Leader>se :UltiSnipsEdit<CR>

" FZF
nnoremap <Leader>o :Files<CR>
nnoremap <leader>t :Tags<cr>

" Telescope
nnoremap <leader>ff <cmd>Telescope find_files<cr>
nnoremap <leader>ft <cmd>Telescope tags<cr>
"nnoremap <leader>fg <cmd>Telescope live_grep<cr>
"nnoremap <leader>fb <cmd>Telescope buffers<cr>
"nnoremap <leader>fh <cmd>Telescope help_tags<cr>

nnoremap <Leader>m :make<CR>

nnoremap <Leader>bn :bn<CR>
nnoremap <Leader>bp :bp<CR>
nnoremap <Leader>be :Ex<CR>
nnoremap <Leader>bf :n<Space>
nnoremap <Leader>bd :bd<CR>

nnoremap <Leader>cn :cn<CR>
nnoremap <Leader>cp :cp<CR>
nnoremap <Leader>co :copen<CR>
nnoremap <Leader>cc :cclose<CR>

nmap <leader>ls :ls<cr>:buffer<space>

nnoremap <leader>ssx :set syntax=
nnoremap <leader>ssg :set syntax=groovy<cr>

nnoremap <Leader>[ :!ctags -R<CR>

nnoremap <silent> <leader><Up> :resize +5<cr>
nnoremap <silent> <leader><Down> :resize -5<cr>
nnoremap <silent> <leader><Right> :vertical resize +5<cr>
nnoremap <silent> <leader><Left> :vertical resize -5<cr>

nnoremap <leader><tab> :tabnew<CR>
nnoremap <A-F1> 1gt
nnoremap <A-F2> 2gt
nnoremap <A-F3> 3gt
nnoremap <A-F4> 4gt
nnoremap <A-F5> 5gt
nnoremap <A-F6> 6gt
nnoremap <A-F7> 7gt
nnoremap <A-F8> 8gt
nnoremap <A-F9> 9gt
nnoremap <A-F0> 10gt
nnoremap <leader><F1> 1gt
nnoremap <leader><F2> 2gt
nnoremap <leader><F3> 3gt
nnoremap <leader><F4> 4gt
nnoremap <leader><F5> 5gt
nnoremap <leader><F6> 6gt
nnoremap <leader><F7> 7gt
nnoremap <leader><F8> 8gt
nnoremap <leader><F9> 9gt
nnoremap <leader><F0> 10gt

" Save out buffers
nnoremap <silent> <leader>w :wa<cr>

" Clear search highlighting
nnoremap <silent> <leader><esc> :noh<cr>

" Print the current file path
nnoremap <silent> <leader>p :echo @%<cr>

" Copy file path and line number of current line to clipboard
nnoremap <silent> <leader>y :let @+ = join([expand('%'),  line(".")], ':')<cr>

silent! colorscheme dracula
hi CursorLine cterm=NONE ctermbg=black

if has('win32')
    set background=dark
else
    " On Non-Windows operating systems, use the host window's background. This
    " allows for transparency if the terminal emulator has that configured.
    hi Normal guibg=NONE ctermbg=NONE
endif

if has('nvim')
    nnoremap <silent> <leader>x :e ~/.config/nvim/init.vim<cr>
else
    nnoremap <silent> <leader>x :e ~/.vimrc<cr>
endif

" Source lua files in Neovim
if has('nvim')
    luafile ~/dot/config/nvim/treesitter.lua
    luafile ~/dot/config/nvim/lsp_go.lua
    luafile ~/dot/config/nvim/lsp_cpp.lua
endif

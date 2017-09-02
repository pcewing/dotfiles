" General Config
set nocompatible
set number                      "Line numbers are good
set backspace=indent,eol,start  "Allow backspace in insert mode
set history=1000                "Store lots of :cmdline history
set showcmd                     "Show incomplete cmds down the bottom
set showmode                    "Show current mode down the bottom
set gcr=a:blinkon0              "Disable cursor blink
set visualbell                  "No sounds
set autoread                    "Reload files changed outside vim
set laststatus=2                "Always display the status line
set hidden                      "Hide buffer instead of closing it
set pastetoggle=<F2>            "Paste without being smart
set splitbelow
set splitright

" Indentation
set autoindent
set smartindent
set smarttab
set shiftwidth=2
set softtabstop=2
set tabstop=2
set expandtab

set ruler

filetype plugin on

" Add a visual indicator to the line the cursor is on.
function s:SetCursorLine()
  set cursorline
  hi CursorLine cterm=NONE ctermbg=black
endfunction
autocmd VimEnter * call s:SetCursorLine()

" Load Plugins
call plug#begin('~/.config/nvim/plugged')

" Fuzzy File Finder is awesome for opening files by name.
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'

" Solarized > all.
Plug 'altercation/vim-colors-solarized'

" Code Completion
Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }

" Language support.
Plug 'elixir-lang/vim-elixir'
Plug 'slashmili/alchemist.vim'

" Omnisharp and its dependencies
Plug 'tpope/vim-dispatch'
Plug 'vim-syntastic/syntastic'
Plug 'OmniSharp/omnisharp-vim'

Plug 'OrangeT/vim-csharp'
Plug 'tpope/vim-vinegar'
Plug 'editorconfig/editorconfig-vim'

" PEP8 Linter
Plug 'nvie/vim-flake8'

call plug#end()

" Configure Plugins

" Deoplete
" Use deoplete.
let g:deoplete#enable_at_startup = 1

" OmniSharp Setup
let g:OmniSharp_selector_ui = 'fzf'

" Colors and Theme
silent! colorscheme solarized
set background=dark

hi Normal guibg=NONE ctermbg=NONE

" Set the Leader key. I leave the leader key as '\' and remap ' ' to it
" instead of setting ' ' as the leader. This is so that showcmd is actually
" useful.
map <Space> <Leader>

" Buffer Controls
" All buffer controls begin with <Leader>b
"  - n : Next buffer
"  - p : Previous buffer
"  - e : Open explorer in a new buffer
"  - f : Open file in a new buffer
"  - d : Unload the buffer (Fails if there are unwritten changes)
nnoremap <Leader>bn :bn<CR>
nnoremap <Leader>bp :bp<CR>
nnoremap <Leader>be :Ex<CR>
nnoremap <Leader>bf :n<Space>
nnoremap <Leader>bd :bd<CR>

" Grep Controls
" All grep controls begin with <Leader>g
"  - l : Grep for literal string
"  - r : Grep for regex string
nnoremap <Leader>gl :grep<Space>-F<Space>-R<space>'
nnoremap <Leader>gr :grep<Space>-R<Space>'

" Quickfix Controls
" All quickfix controls begin with <Leader>c
"  - n : Move to next quickfix
"  - p : Move to previous quickfix
"  - o : Open the quickfix list
"  - c : Close the quickfix list
nnoremap <Leader>cn :cn<CR>
nnoremap <Leader>cp :cp<CR>
nnoremap <Leader>co :copen<CR>
nnoremap <Leader>cc :cclose<CR>

" General Controls
"  - n : Write current buffer
nnoremap <Leader>w :w<CR>

" Open FZF
nnoremap <Leader>o :FZF<CR>

" Leader Copy/Paste Controls
" These haven't been working as expected so I'm excluding for now.
"vmap <Leader>y "+y
"vmap <Leader>d "+d
"vmap <Leader>p "+p
"vmap <Leader>P "+P
"nmap <Leader>p "+p
"nmap <Leader>P "+P

nmap <leader>ls :ls<cr>:buffer<space>

nnoremap <leader>ssx :set syntax=
nnoremap <leader>ssg :set syntax=groovy<cr>

nnoremap <silent> <leader><Up> :resize +5<cr>
nnoremap <silent> <leader><Down> :resize -5<cr>
nnoremap <silent> <leader><Right> :vertical resize +5<cr>
nnoremap <silent> <leader><Left> :vertical resize -5<cr>

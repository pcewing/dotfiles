filetype plugin on

" Load Plugins
call plug#begin('~/.config/nvim/plugged')

" Fuzzy File Finder is awesome
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'

" Color scheme
Plug 'altercation/vim-colors-solarized'

" Code Completion
Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }

" Language support.
Plug 'elixir-lang/vim-elixir'
Plug 'slashmili/alchemist.vim'
Plug 'fatih/vim-go'

" Omnisharp and its dependencies
Plug 'tpope/vim-dispatch'
Plug 'vim-syntastic/syntastic'
Plug 'OmniSharp/omnisharp-vim'

Plug 'OrangeT/vim-csharp'
Plug 'tpope/vim-vinegar'
Plug 'editorconfig/editorconfig-vim'

Plug 'mattn/emmet-vim'

" PEP8 Linter
Plug 'nvie/vim-flake8'

call plug#end()

" Deoplete
let g:deoplete#enable_at_startup = 1

" OmniSharp
let g:OmniSharp_selector_ui = 'fzf'


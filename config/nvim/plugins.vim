filetype plugin on

" Load Plugins
call plug#begin('~/.config/nvim/plugged')

Plug 'altercation/vim-colors-solarized'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
Plug 'elixir-lang/vim-elixir'
Plug 'slashmili/alchemist.vim'
Plug 'fatih/vim-go'
Plug 'OrangeT/vim-csharp'
Plug 'mattn/emmet-vim'
Plug 'tpope/vim-vinegar'
Plug 'editorconfig/editorconfig-vim'
Plug 'nvie/vim-flake8'
Plug 'martinda/Jenkinsfile-vim-syntax'

call plug#end()


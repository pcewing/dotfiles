set nocompatible

" Show line numbers
set number

"Allow backspace in insert mode
set backspace=indent,eol,start

"Increase :cmdline history
set history=1000

"Show incomplete commands
set showcmd

"Show current mode
set showmode

"Disable cursor blink
set gcr=a:blinkon0

"No sounds
set visualbell

"Reload files changed outside vim
set autoread

"Write the file on :make
set autowrite

"Always display the status line
set laststatus=2

"Hide buffer instead of closing it
set nohidden

"Toggle whether or not vim formats when pasting from clipboard
set pastetoggle=<F2>

" When splitting vertically, the new pane should be on the right
set splitright

" When splitting horizontally, the new pane should be on the bottom
set splitbelow

" Indentation
set autoindent
set smartindent
set smarttab
set shiftwidth=4
set softtabstop=4
set tabstop=4
set expandtab

set ruler

set clipboard=unnamed,unnamedplus


" Set the Leader key. I leave the leader key as '\' and remap ' ' to it
" instead of setting ' ' as the leader. This is so that showcmd is actually
" useful.
map <Space> <Leader>

" Setup vim-go mappings
autocmd FileType go nmap <Leader>gor :GoRun<CR>
autocmd FileType go nmap <Leader>gob :GoBuild<CR>

" Buffer Controls (b)
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

" Grep Controls (g)
"  - l : Grep for literal string
"  - r : Grep for regex string
nnoremap <Leader>gl :grep<Space>-F<Space>-R<space>'
nnoremap <Leader>gr :grep<Space>-R<Space>'

" Quickfix Controls (c)
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

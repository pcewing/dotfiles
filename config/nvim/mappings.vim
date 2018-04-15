" Set the Leader key. I leave the leader key as '\' and remap ' ' to it
" instead of setting ' ' as the leader. This is so that showcmd is actually
" useful.
map <Space> <Leader>

nnoremap <Leader>bn :bn<CR>
nnoremap <Leader>bp :bp<CR>
nnoremap <Leader>be :Ex<CR>
nnoremap <Leader>bf :n<Space>
nnoremap <Leader>bd :bd<CR>

nnoremap <Leader>cn :cn<CR>
nnoremap <Leader>cp :cp<CR>
nnoremap <Leader>co :copen<CR>
nnoremap <Leader>cc :cclose<CR>

nnoremap <leader><tab>h  :tabfirst<CR>
nnoremap <leader><tab>j  :tabnext<CR>
nnoremap <leader><tab>k  :tabprev<CR>
nnoremap <leader><tab>l  :tablast<CR>
nnoremap <leader><tab>e  :tabedit<Space>
nnoremap <leader><tab>n  :tabnext<Space>
nnoremap <leader><tab>m  :tabm<Space>
nnoremap <leader><tab>d  :tabclose<CR>

nmap <leader>ls :ls<cr>:buffer<space>

nnoremap <leader>ssx :set syntax=
nnoremap <leader>ssg :set syntax=groovy<cr>

nnoremap <Leader>gl :grep<Space>-F<Space>-R<space>'
nnoremap <Leader>gr :grep<Space>-R<Space>'

nnoremap <silent> <leader><Up> :resize +5<cr>
nnoremap <silent> <leader><Down> :resize -5<cr>
nnoremap <silent> <leader><Right> :vertical resize +5<cr>
nnoremap <silent> <leader><Left> :vertical resize -5<cr>

vnoremap <Leader>n :normal<Space>

" FZF
nnoremap <Leader>o :FZF<CR>
nnoremap <silent> <leader>t :Tags<cr>

" Setup vim-go mappings
autocmd FileType go nmap <Leader>gor :GoRun<CR>
autocmd FileType go nmap <Leader>gob :GoBuild<CR>


set t_Co=256
set background=dark
colorscheme desert
set guicursor+=n-v-c:blinkon0
set go-=T
"set go-=m
set guifont=DejaVu\ Sans\ Mono:h10
"nnoremap <Space> <C-f>
"nnoremap <S-Space> <C-b>
nnoremap <C-Up> :silent! let &guifont = substitute(
 \ &guifont,
 \ ':h\zs\d\+',
 \ '\=eval(submatch(0)+1)',
 \ '')<CR>
nnoremap <C-Down> :silent! let &guifont = substitute(
 \ &guifont,
 \ ':h\zs\d\+',
 \ '\=eval(submatch(0)-1)',
 \ '')<CR>

set vb t_vb=

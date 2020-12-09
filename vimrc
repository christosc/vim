set nocompatible 
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'
"Plugin 'Valloric/YouCompleteMe'
Plugin 'tomasiser/vim-code-dark'
Plugin 'dunstontc/vim-vscode-theme'
Plugin 'dracula/vim'
Plugin 'jnurmine/Zenburn'
Plugin 'nanotech/jellybeans.vim'
Plugin 'tomasr/molokai'
Plugin 'nathanalderson/yang.vim'
Plugin 'ludovicchabant/vim-lawrencium'
Plugin 'tpope/vim-repeat'
Plugin 'tpope/vim-unimpaired'




" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required
" To ignore plugin indent changes, instead use:
"filetype plugin on

"set runtimepath^=~/.vim/bundle/ctrlp.vim

set fo-=t
syntax on
set t_Co=256 
set tags=./tags,tags,~/work/tags

let g:columnlimit=101
function! g:ToggleColorColumn()
  if &colorcolumn != ''
    set colorcolumn&  "setlocal colorcolumn&
  else
    let &colorcolumn=g:columnlimit  "setlocal colorcolumn=81
  endif
endfunction


let mapleader = ","
nnoremap <silent> <leader>c :call g:ToggleColorColumn()<CR>
set pastetoggle=<F2>
"nnoremap <silent> <F3> :redir @a<CR>:g//<CR>:redir END<CR>:new<CR>:put! a<CR>
command! -nargs=? Filter let @a='' | execute 'g/<args>/y A' | new | setlocal bt=nofile | put! a
highlight ColorColumn ctermbg=DarkGrey
inoremap jj <Esc>

set background=dark
noremap <Leader>a :call CurtineIncSw()<CR>
set path=.,**
set incsearch
nnoremap <silent> <space> :set hls!<cr>
nnoremap <silent> <F3> :set hls!<cr>
let g:loaded_matchparen=1
set ignorecase
" Ignore case for buffer names
set wildignorecase
set smartcase
set linebreak
noremap j gj
noremap k gk
noremap 0 g0
noremap $ g$
set bs=2
set autoindent
set smartindent
"noremap <Leader>s :update<CR>
noremap <Leader>s :update<CR>
set mouse=v
set exrc
set secure
set laststatus=2
set ruler

" find files and populate the quickfix list
fun! FindFiles(filename)
  let error_file = tempname()
  silent exe '!find . -name "'.a:filename.'" | xargs file | sed "s/:/:1:/" > '.error_file
  set errorformat=%f:%l:%m
  exe "cfile ". error_file
  copen
  call delete(error_file)
endfun
command! -nargs=1 FindFile call FindFiles(<q-args>)

set grepprg=grep\ -nI\ --exclude-dir={.hg,.git}\ $*\ /dev/null"

" Count the occurrences of the word under cursor
map ,* *<C-O>:%s///gn<CR>

" use X11 clipboard for yank and paste
"set clipboard=unnamedplus

" work-around to copy selected text to system clipboard
" and prevent it from clearing clipboard when using ctrl+z (depends on xsel)
" and when quitting vim.
if executable("xsel")

  function! PreserveClipboard()
    call system("xsel -ib", getreg('+'))
  endfunction

  function! PreserveClipboadAndSuspend()
    call PreserveClipboard()
    suspend
  endfunction

  autocmd VimLeave * call PreserveClipboard()
  nnoremap <silent> <c-z> :call PreserveClipboadAndSuspend()<cr>
  vnoremap <silent> <c-z> :<c-u>call PreserveClipboadAndSuspend()<cr>

endif

set ttymouse=xterm2

set et
set ts=4
set sw=4
set sts=4  " feels like if working with tabs!

set listchars=eol:$,tab:>-,trail:~,extends:>,precedes:<
noremap <F5> :set list!<CR>
inoremap <F5> <C-o>:set list!<CR>
cnoremap <F5> <C-c>:set list!<CR>
setglobal complete=.,w,b,u
set mouse=a
nnoremap <Leader>l :ls<CR>
nnoremap <Leader>bp :bp<CR>
nnoremap <Leader>bn :bn<CR>
nnoremap <Leader>cn :cn<CR>
nnoremap <Leader>cp :cp<CR>
nnoremap <Leader>co :copen<CR>
nnoremap <Leader>cc :ccl<CR>
nnoremap <Leader>cf :cfirst<CR>

nnoremap <Leader>tp :tabp<CR>
nnoremap <Leader>tn :tabn<CR>

" bind \ (backward slash) to grep shortcut
command! -nargs=1 Gr exec ':silent! grep'.<args>|redraw!
command! -nargs=1 Grep exec ':silent! :grep'.<args>|redraw!|copen
command! -nargs=1 GrDef exec ':silent! grep "::'.<args>.'"'

nnoremap <leader>gf :grep! "\b<cword>\b" -r %:h<CR>:copen<CR>
nnoremap <leader>gp :grep! "\b<cword>\b" -r %:p:h:h<CR>:copen<CR>
nnoremap <leader>g. :grep! "\b<cword>\b" -r .<CR>:copen<CR>
nnoremap <leader>o :vimg /\<<c-r>=expand('<cword>')<CR>\>/j %<CR>:copen<CR>
nnoremap <leader>O :vimg /\<<c-r>=expand('<cword>')<CR>\>\C/j %<CR>:copen<CR>
nnoremap T :silent! grep "::<cword>\b" -r .<CR>:redraw!<CR>
nnoremap <leader>l :lcd %:p:h<CR>
nnoremap <leader>L :lcd %:p:h:h<CR>
nnoremap <silent><leader>d /\w\s\+\(\w\+::\)\{,1}<c-r>=expand('<cword>')<CR>(\\|\(\*\\|>\\|&\)\(\s*\\|\(\s*\w\+::\)\)<c-r>=expand('<cword>')<CR>(<CR>
nnoremap <silent><leader>D :silent! lgrep! "\\w\\s\\+\\(\\w\\+::\\)\\?<cword>(\\\|\\(\\*\\\|>\\\|&\\)\\(\\s*\\\|\\(\\s*\\w\\+::\\)\\)<cword>(" -r %:p:h<CR>:redraw!<CR>:silent! llast<CR>

command! -nargs=1 Def /\w\s\+\(\w\+::\)\{,1}<args>(\|\(\*\|>\|&\)\(\s*\|\(\s*\w\+::\)\)<args>(

function! GrepRec(pat)
    silent! execute 'lgrep! "\\w\\s\\+\\(\\w\\+::\\)\\?' . a:pat . '(\\\|\\(\\*\\\|>\\\|&\\)\\(\\s*\\\|\\(\\s*\\w\\+::\\)\\)' . a:pat . '(" -r ' . expand("%:p:h")
    redraw!
    silent! llast
endfunction

command! -nargs=1 Defr call GrepRec("<args>")

set keymap=greek_mac
set iminsert=0
set imsearch=-1
"inoremap <C-\> <C-^>
inoremap <C-l> <C-^>
set noeb vb t_vb=  "silence the audible bell
nnoremap <Leader>b# :b#<CR>
nnoremap <Leader>a :A<CR>
nnoremap <Leader>e :e!<CR>
set encoding=utf-8
setglobal fileencoding=utf-8

autocmd BufRead,BufNewFile *.cpp,*.c,*.h,*.hpp setlocal tw=80
autocmd! BufWinEnter quickfix setlocal nowinfixheight

" Don't take tags and included files into account in completing words.
" I dont' use tags anyway.
set complete-=t
set complete-=i

function! ToggleQuickFix()
    if empty(filter(getwininfo(), 'v:val.quickfix'))
        copen
    else
        cclose
    endif
endfunction

nnoremap <silent> <F4> :call ToggleQuickFix()<cr>

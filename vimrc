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
"colorscheme desert
"colorscheme codedark
"colorscheme desert256
syntax on
"syntax off
"set t_Co=0 
set t_Co=256 
"set tags=./tags;,tags;/data/$USER 

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
"set stl+=%{expand('%:~:.')}
"colorscheme zenburn
"let g:solarized_termcolors=256
"colorscheme desert256
highlight ColorColumn ctermbg=DarkGrey
"inoremap jj <Esc>
"inoremap jk <Esc>
"inoremap kj <Esc>
"inoremap jj <Esc>

" nnoremap <Space> <C-f>
set background=dark
"colorscheme codedark
"colorscheme morning
noremap <Leader>a :call CurtineIncSw()<CR>
"nnoremap <silent> <F5> :let _s=@/ <Bar> :%s/\s\+$//e <Bar> :let @/=_s <Bar> :nohl <Bar> :unlet _s <CR>
noremap <F4> :set hlsearch!<CR>
set path=.,**
"set path+=**
"set path+=~/work/sw/**
"set wildignore+=*/build/*
"set wildignore+=*/.hg/*
"set incsearch
"set hlsearch
"nnoremap <silent> <space> :set hls!<cr>
nnoremap <silent> <F3> :set hls!<cr>
let g:loaded_matchparen=1
set ignorecase
set smartcase
set linebreak
map <C-j> gj
map <C-k> gk
"map j gj
"map k gk
"map <C-4> g$
"map <C-6> g^
"map <C-0> g^
"map <C-j> gj
"map <C-k> gk
"map <C-4> g$
"map <C-6> g^
"map <C-0> g^
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

"autocmd BufEnter * :syntax sync fromstart

"set tags=./tags;
set tags=tags;
"set grepprg=grep\ --exclude-dir={[uU]nittests,[tT]est,build,hg}\ --exclude=tags\ -In
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

" The terminal cannot distinguish <Space> and <S-Space>, so this cannot be
" defined:
" nnoremap <S-Space> <C-b>

set ttymouse=xterm2

"nnoremap <C-J> <C-W><C-J>
"nnoremap <C-K> <C-W><C-K>
"nnoremap <C-L> <C-W><C-L>
"nnoremap <C-H> <C-W><C-H>

"set splitbelow
"set splitright
"set title
set hidden " if set when doing :bd it will just hide the buffer...
set et
set ts=4
set sw=4

nnoremap <Leader>oc :e %<.c<CR>
nnoremap <Leader>oC :e %<.cpp<CR>
nnoremap <Leader>oh :e %<.h<CR>
nnoremap <Leader>oH :e %<.hpp<CR>

set listchars=eol:$,tab:>-,trail:~,extends:>,precedes:<
noremap <F5> :set list!<CR>
inoremap <F5> <C-o>:set list!<CR>
cnoremap <F5> <C-c>:set list!<CR>
"set complete-=i
"set notagrelative
setglobal complete=.,w,b,u
set mouse=a
"autocmd InsertEnter,InsertLeave * set cul!
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

"set cscopequickfix=s-,c-,d-,i-,t-,e-,a-

" Open automatically the quickfix window every time we do a grep.
"augroup qf
"    autocmd!
"    autocmd QuickFixCmdPost * cwindow
"augroup END

" bind \ (backward slash) to grep shortcut
command -nargs=1 Gr exec ':silent! grep'.<args>|redraw!
command -nargs=1 Grep exec ':silent! :grep'.<args>|redraw!|copen
command -nargs=1 GrDef exec ':silent! grep "::'.<args>.'"'

"nnoremap K :grep! "\b<cword>\b" -r .<CR>:cw<CR>
"nnoremap <leader>g :lgrep! "\b<cword>\b" -r %:p:h<CR>:lopen<CR>
"nnoremap <leader>p :lgrep! "\b<cword>\b" -r %:p:h:h<CR>:lopen<CR>
nnoremap <leader>g :lgrep! "\b<cword>\b" -r .<CR>:lopen<CR>
nnoremap <leader>p :lgrep! "\b<cword>\b" -r .<CR>:lopen<CR>
nnoremap <leader>o :lvimg /\<<c-r>=expand('<cword>')<CR>\>/j %<CR>:lopen<CR>
nnoremap T :silent! grep "::<cword>\b" -r .<CR>:redraw!<CR>
nnoremap <leader>l :lcd %:p:h<CR>
nnoremap <leader>L :lcd %:p:h:h<CR>
nnoremap <silent><leader>d /\w\(\s\\|\*\\|>\)\+<c-r>=expand('<cword>')<CR>\><CR>

" If there are more than one matching lines select the last one, since the
" first one might be just a forward declaration.
nnoremap <leader>D :silent lgrep "\w[[:space:]*>]\+<cword>\b" -r %:p:h<CR>:redraw!<CR>:llast<CR>
"nnoremap T :GrDef "<cword>\b"
"nnoremap K :grep! "\<<C-R><C-W>\>"<CR>:cw<CR>

"set showtabline=2
"set nowrapscan

set keymap=greek_mac
set iminsert=0
set imsearch=-1
inoremap <C-\> <C-^>
set vb t_vb=  "silence the audible bell
nnoremap <Leader>b# :b#<CR>
nnoremap <Leader>a :A<CR>


"-------------- STATUSLINE -----------------------
"
" Default statusline with ruler (as given in :help statusline)
" is the following:
"      set statusline=%<%f\ %h%m%r%=%-14.(%l,%c%V%)\ %P
"

"set statusline=%t\ %h%m%r\ %14.((%l,%c%V%))\ %P
"set statusline=%t\ %h%m%r\ %14.(%l,%c%V%)\ %P

"set statusline=%<%t\ %h%m%r%=%14.(%l,%c%V%)\ %P

"set statusline=%t\ %h%m%r\ %14.P
"set statusline=%t\ %h%m%r
"set statusline=%t\ %h%m%r

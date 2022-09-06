" When started as "evim", evim.vim will already have done these settings, bail
" out.
if v:progname =~? "evim"
  finish
endif

" Get the defaults that most users want.
source $VIMRUNTIME/defaults.vim

" Don't highlight literals within C comments (set by defaults.vim).
unlet c_comment_strings

if has("vms")
  set nobackup		" do not keep a backup file, use versions instead
else
  set backup		" keep a backup file (restore to previous version)
  if has('persistent_undo')
    set undofile	" keep an undo file (undo changes after closing)
  endif
endif

"if &t_Co > 2 || has("gui_running")
"  " Switch on highlighting the last used search pattern.
"  set hlsearch
"endif

" Put these in an autocmd group, so that we can delete them easily.
augroup vimrcEx
  au!

  " For all text files set 'textwidth' to 78 characters.
  autocmd FileType text setlocal textwidth=78
augroup END

" Add optional packages.
"
" The matchit plugin makes the % command work better, but it is not backwards
" compatible.
" The ! means the package won't be loaded right away but when plugins are
" loaded during initialization.
if has('syntax') && has('eval')
  packadd! matchit
endif
set nocompatible 
filetype off                  " required

" set the runtime path to include Vundle and initialize
if has('win32')
    set rtp+=~/vimfiles/bundle/Vundle.vim
else
    set rtp+=~/.vim/bundle/Vundle.vim
endif

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
Plugin 'preservim/tagbar'
Plugin 'morhetz/gruvbox'
"Plugin 'godlygeek/tabular'
"Plugin 'plasticboy/vim-markdown'
"Plugin 'vim-syntastic/syntastic'




" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required
" To ignore plugin indent changes, instead use:
"filetype plugin on

"set runtimepath^=~/.vim/bundle/ctrlp.vim

set fo-=t
set fo+=j
syntax on
set t_Co=256 
" Unbind some useless/annoying default key bindings.
nmap Q <Nop> " 'Q' in normal mode enters Ex mode. You almost never want this.
"set number
"set relativenumber
"colorscheme molokai
colorscheme desert256
"colorscheme solarize/
"set tags=./tags,tags,~/work/tags
"set tags=./tags;~/work/main_repo
" Begin looking for tags from current file's directory and walk up the
" hiearchy until root directory.
set tags=./tags;~/work
set synmaxcol=500

let g:columnlimit=101
function! g:ToggleColorColumn()
  if &colorcolumn != ''
    set colorcolumn&  "setlocal colorcolumn&
  else
    let &colorcolumn=g:columnlimit  "setlocal colorcolumn=81
  endif
endfunction


let mapleader = "\<Space>"
nnoremap <silent> <leader>c :call g:ToggleColorColumn()<CR>
set pastetoggle=<F2>
"nnoremap <silent> <F3> :redir @a<CR>:g//<CR>:redir END<CR>:new<CR>:put! a<CR>
command! -nargs=? Filter let @a='' | execute 'g/<args>/y A' | new | setlocal bt=nofile | put! a
highlight ColorColumn ctermbg=DarkGrey
"inoremap jj <Esc>

set background=dark
"set background=light
noremap <Leader>a :call CurtineIncSw()<CR>
set path=.,**
set incsearch
"noremap <F1> <Nop>
"noremap <silent> <space> :set hls!<cr>
noremap <silent> <F3> :set hls!<cr>
let g:loaded_matchparen=1
set ignorecase
set tagcase=smart
" Ignore case for buffer names
set wildignorecase
set fileignorecase
set smartcase
set linebreak
"noremap j gj
"noremap k gk
"noremap 0 g0
"noremap $ g$
set bs=2
set autoindent
set smartindent
"noremap <Leader>s :update<CR>
noremap <Leader>w :write<CR>
set mouse=v
set exrc
set secure
set laststatus=2
set ruler
set ttyfast
"set lazyredraw

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

" To exclude Emacs temporary files beginning with a '#' symbol, it was
" necessary to escape # character with shellescape as shown, because it was
" getting expanded to the 'alternate' buffer name.
let &grepprg="grep -nI --exclude='*~' --exclude=tags\ --exclude=TAGS --exclude-dir={.hg,.git} --exclude=" . shellescape("#", 1) . "'*' --exclude='*.orig'"
"set grepprg='grep -nI --exclude-dir={.hg,.git} $*'

" Count the occurrences of the word under cursor
map ,* *<C-O>:%s///gn<CR>

" use X11 clipboard for yank and paste
"set clipboard=unnamedplus

" work-around to copy selected text to system clipboard
" and prevent it from clearing clipboard when using ctrl+z (depends on xsel)
" and when quitting vim.
"if executable("xsel")
"
"  function! PreserveClipboard()
"    call system("xsel -ib", getreg('+'))
"  endfunction
"
"  function! PreserveClipboadAndSuspend()
"    call PreserveClipboard()
"    suspend
"  endfunction
"
"  autocmd VimLeave * call PreserveClipboard()
"  nnoremap <silent> <c-z> :call PreserveClipboadAndSuspend()<cr>
"  vnoremap <silent> <c-z> :<c-u>call PreserveClipboadAndSuspend()<cr>
"
"endif

set ttymouse=xterm2

set et
set ts=4
set sw=4
set sts=4  " feels like if working with tabs!
set shiftround
set smarttab
set showcmd

set listchars=eol:$,tab:>-,trail:~,extends:>,precedes:<
noremap <F5> :set list!<CR>
inoremap <F5> <C-o>:set list!<CR>
cnoremap <F5> <C-c>:set list!<CR>
setglobal complete=.,w,b,u
set mouse=a
"nnoremap <Leader>l :ls<CR>
"nnoremap <Leader>bp :bp<CR>
"nnoremap <Leader>bn :bn<CR>
"nnoremap <Leader>cn :cn<CR>
"nnoremap <Leader>cp :cp<CR>
"nnoremap <Leader>co :copen<CR>
"nnoremap <Leader>cc :ccl<CR>
"nnoremap <Leader>cf :cfirst<CR>
"
"nnoremap <Leader>tp :tabp<CR>
"nnoremap <Leader>tn :tabn<CR>

" bind \ (backward slash) to grep shortcut
command! -nargs=1 Gr exec ':silent! grep'.<args>|redraw!
command! -nargs=1 Grep exec ':silent! :grep'.<args>|redraw!|copen
command! -nargs=1 GrDef exec ':silent! grep "::'.<args>.'"'

"" Search mappings using quickfix list
"nnoremap <silent><leader>gf :grep! "\b<cword>\b" -r %:h<CR>:botright cwindow<CR>
"nnoremap <leader>gp :grep! "\b<cword>\b" -r %:p:h:h<CR>:botright cwindow<CR>
"nnoremap <leader>g. :grep! "\b<cword>\b" -r .<CR>:botright cwindow<CR>
"nnoremap <leader>o :vim /\<<c-r>=expand('<cword>')<CR>\>/j %<CR>:botright cwindow<CR>
"nnoremap <leader>O :vim /\<<c-r>=expand('<cword>')<CR>\>\C/j %<CR>:botright cwindow<CR>

" Search mappings using quickfix list
nnoremap <silent><leader>gf :lgrep! "\b<cword>\b" -r %:h<CR>:lopen<CR>
nnoremap <leader>gp :lgrep! "\b<cword>\b" -r %:p:h:h<CR>:lopen<CR>
nnoremap <leader>g. :lgrep! "\b<cword>\b" -r .<CR>:lopen<CR>
nnoremap <leader>o :lvim /\<<c-r>=expand('<cword>')<CR>\>/j %<CR>:lopen<CR>
nnoremap <leader>O :lvim /\<<c-r>=expand('<cword>')<CR>\>\C/j %<CR>:lopen<CR>

"nnoremap T :silent! grep "::<cword>\b" -r .<CR>:redraw!<CR>
nnoremap <leader>l :lcd %:p:h<CR>
nnoremap <leader>L :lcd %:p:h:h<CR>
nnoremap <leader>lo :lopen<CR>
nnoremap <leader>lc :lclose<CR>
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
inoremap <C-\> <C-^>
"inoremap <silent><ESC> <ESC>:set iminsert=0<CR>
function! ToggleKeymap()
    if &keymap=='greek_mac'
        set keymap=
    else
        set keymap=greek_mac
    endif
endfunction

nnoremap <C-\> :call ToggleKeymap()<cr>

set noeb vb t_vb=  "silence the audible bell
nnoremap <Leader>b# :b#<CR>
set termencoding=utf-8
set encoding=utf-8
setglobal fileencoding=utf-8

autocmd BufRead,BufNewFile *.cpp,*.c,*.h,*.hpp setlocal tw=80
"autocmd! BufWinEnter quickfix setlocal nowinfixheight

" Don't take tags and included files into account in completing words.
" I dont' use tags anyway.
set complete-=t
set complete-=i

function! ToggleQuickFix()
    if empty(filter(getwininfo(), 'v:val.quickfix'))
        botright cwindow
    else
        cclose
    endif
endfunction

nnoremap <silent> <F4> :call ToggleQuickFix()<cr>
set noerrorbells
"set wildmenu
"set wildmode=longest:full,full
set title
"set shortmess=a
set shortmess-=S  "Show [x/y] for search results

if has('clipboard')     " If the feature is available
  set clipboard=unnamed " copy to the system clipboard

  if has('unnamedplus')
    set clipboard+=unnamedplus
  endif
endif

" Setting to indent wrapped lines
if exists('+breakindent')
  set breakindent
  "set breakindentopt=shift:2
endif

nmap <F8> :TagbarToggle<CR>

" Functions for status line config since these functions aren't loaded
" when the vimrc is sourced
function! CurrentTag(...)
  if exists('g:tagbar_iconchars')
    return call('tagbar#currenttag', a:000)
  else
    return ''
  endif
endfunction

function! SyntasticStatuslineFlag()
  return ''
endfunction

let g:tagbar_width = max([25, winwidth(0) / 5])
let g:tagbar_ctags_bin="/data/chryssoc/bin/ctags"
" Left Side
"set statusline=
"set statusline+=%#IncSearch#%{&paste?'\ \ PASTE\ ':''}%*
"set statusline+=\ %.50f
"set statusline+=\ %m
"set statusline+=\ %r
"set statusline+=%=
"" Right Side
"set statusline+=%{CurrentTag('%s\ <\ ','','')}
"set statusline+=%y
"set statusline+=\ \ %P
"set statusline+=-%l
"set statusline+=-%c
"set statusline+=%#warningmsg#
"set statusline+=%{SyntasticStatuslineFlag()}
"set statusline+=%*
"set statusline=%<%f\ %h%m%r\ \ %-9(%l,%c%V%)\ %P

"let g:syntastic_always_populate_loc_list = 1
"let g:syntastic_auto_loc_list = 1
"let g:syntastic_check_on_open = 1
"let g:syntastic_check_on_wq = 0

"set statusline+=\ %#ErrorMsg#%{SyntasticStatuslineFlag()}%*
"let g:syntastic_cpp_include_dirs = ['/home/chryssoc/work/main_repo/y/include','/home/chryssoc/work/main_repo/vobs/dsl/sw/include','/home/chryssoc/work/main_repo/y/src/']
"let g:syntastic_cpp_config_file = '~/.syntastic_cpp_config'
"let g:syntastic_quiet_messages = { 'regex': 'generated.*h' }
"let g:syntastic_cpp_compiler_options = ' -std=c++11'
"let g:syntastic_debug = 3
"let g:syntastic_debug = 1
"let g:syntastic_cpp_remove_include_errors = 1
runtime macros/matchit.vim
"set scrolloff&  "Revert value from defaults.vim

noremap <Up> <Nop>
noremap <Down> <Nop>
noremap <Left> <Nop>
noremap <Right> <Nop>

set hidden
"set t_ut=""

" Auto-detect Freemarker (ftl) file type.
augroup filetypedetect
  au BufNewFile,BufRead *.ftl setf ftl
augroup END

"set autochdir

" Use a line cursor within insert mode and a block cursor everywhere else.
"
" Reference chart of values:
"   Ps = 0  -> blinking block.
"   Ps = 1  -> blinking block (default).
"   Ps = 2  -> steady block.
"   Ps = 3  -> blinking underline.
"   Ps = 4  -> steady underline.
"   Ps = 5  -> blinking bar (xterm).
"   Ps = 6  -> steady bar (xterm).
let &t_SI = "\e[6 q"
let &t_EI = "\e[2 q"

" YAML files by default don't get indented correctly. This fixes the issue.
autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab

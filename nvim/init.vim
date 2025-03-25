call plug#begin()
" List your plugins here
" Plug 'tpope/vim-sensible'
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}  " We recommend updating the parsers on update
Plug 'neovim/nvim-lspconfig'
Plug 'folke/trouble.nvim'
Plug 'nvim-telescope/telescope.nvim'

call plug#end()


" Toggle colorcolumn
function! ToggleColorColumn()
    if &colorcolumn != ''
        set colorcolumn=
    else
        let &colorcolumn = g:columnlimit
    endif
endfunction
nnoremap <silent> <leader>c :call ToggleColorColumn()<CR>

" Find files and populate the quickfix list
function! FindFiles(filename)
    let error_file = tempname()
    silent execute '!find . -name "'.a:filename.'" | xargs file | sed "s/:/:1:/" > '.error_file
    set errorformat=%f:%l:%m
    execute 'cfile '.error_file
    copen
    call delete(error_file)
endfunction
command! -nargs=1 FindFile call FindFiles(<q-args>)

" Potentially toggle quickfix window
function! ToggleQuickFix()
    if empty(filter(getwininfo(), 'v:val.quickfix'))
        botright cwindow
    else
        cclose
    endif
endfunction

nnoremap <silent> <F4> :call ToggleQuickFix()<CR>

" Potential "other" files finder
function! FindOtherFiles()
    let l:src_ext = expand('%:e')
    if l:src_ext ==# 'cpp'
        let l:target_ext = 'hpp'
    elseif l:src_ext == 'hpp'
        let l:tgt_ext = 'cpp'
    elseif l:src_ext == 'c'
        let l:tgt_ext = 'h'
    else
        echo "Unknown extension"
        return
    endif
    let l:basename = expand('%:t:r')
    let l:other_file = l:basename . '.' . l:tgt_ext
    execute ':find ' . l:other_file
endfunction
command! FindOther call FindOtherFiles()

" Setting indentation and tabs
set expandtab
set tabstop=4
set shiftwidth=4
set softtabstop=4
set shiftround
set smarttab
set showcmd
set ignorecase
set smartcase
set signcolumn=yes

" Set grep program
"set grepprg=grep\ -nI\ --exclude='*~'\ --exclude-dir={.hg,.git}\ $*

" Complete option settings
set complete-=t
set complete-=i

" Toggle wrap
let g:wrapenabled = 0
function! ToggleWrap()
    if g:wrapenabled
        set nowrap nolist nolinebreak
        unmap j
        unmap k
        unmap 0
        unmap ^
        unmap $
        let g:wrapenabled = 0
    else
        set wrap linebreak nolist
        noremap j gj
        noremap k gk
        noremap 0 g0
        noremap ^ g^
        noremap $ g$
        let g:wrapenabled = 1
    endif
endfunction

map <leader>W :call ToggleWrap()<CR>

" Status line example
set statusline=%<%f\ %h%m%r\ %14.(%l,%c%V%)\ %P

function! SwitchToOtherFile(others, cmd)
    let nOthers = len(a:others)
    if nOthers == 0
        throw "File extension unknown"
    endif
    try
        " echom a:others[0]
        execute a:cmd . ' ' . a:others[0]
    catch /E345:/
        if nOthers > 1
            " echom a:others[1]
            execute a:cmd . ' ' . a:others[1]
        endif
    endtry
endfunction

" Find potential "other" files:
"    .cpp => .h,.hpp
"    .hpp => .cpp
"    .c   => .h
"    .h   => .cpp,.c
" It uses the find command, which should have the 'path' variable
" appropriately set.
function! PotentialOtherFiles(filepath)
    let tgt_ext = ""
    let src_ext = fnamemodify(a:filepath, ":e")
    if src_ext ==# "cpp"
        let tgt_ext = "hpp"
    elseif src_ext ==# "hpp"
        let tgt_ext = "cpp"
    elseif src_ext ==# "c"
        let tgt_ext = "h"
    elseif src_ext ==# "h"
        let tgt_ext = "c"
    else
        echo "Unknown file extension."
    endif
    let files = []
    if tgt_ext != ""
        let basename = fnamemodify(a:filepath, ":t:r")
        call add(files, basename . "." . tgt_ext)
        if src_ext ==# "cpp"
            call add(files, basename . ".h")
        elseif src_ext ==# "h"
            call add(files, basename . ".cpp")
        endif
    endif
    return files
endfunction

" Use :fin[d] %:t:r.hpp or %:t:r.cpp to switch between header and
" implementation files. (See also :help expand.)
" Searches recursively relative to current directory of vim.
set path=include/**,src/**,export/**,source/**,../include/**,../export/**,../src/**,../source/**

command! A call SwitchToOtherFile(PotentialOtherFiles(expand('%')), 'find')
command! AS call SwitchToOtherFile(PotentialOtherFiles(expand('%')), 'sfind')
command! AV call SwitchToOtherFile(PotentialOtherFiles(expand('%')), 'vert sfind')

noremap <F1> :update<cr>
noremap <silent> <F3> :set hls!<cr>
"nnoremap <silent> <F2> :set paste!<CR>
"inoremap <silent> <F2> <ESC>:set paste!<CR>i

" Search mappings using quickfix list
nnoremap <silent><leader>gf :grep! "\b<cword>\b" -r %:h<CR>:botright copen<CR>
nnoremap <leader>gp :grep! "\b<cword>\b" -r %:p:h:h<CR>:botright copen<CR>
nnoremap <leader>g. :grep! "\b<cword>\b" <CR>:copen<CR>
nnoremap <leader>o :vim /\<<c-r>=expand('<cword>')<CR>\>/j %<CR>:botright copen<CR>
nnoremap <leader>O :vim /\<<c-r>=expand('<cword>')<CR>\>\C/j %<CR>:botright copen<CR>

autocmd BufReadPost quickfix nnoremap <buffer> <CR> <CR>
"set number relativenumber

lua <<EOF
require'nvim-treesitter.configs'.setup{highlight={enable=true}}  -- At the bottom of your init.vim, keep all configs on one line
local lspconfig = require('lspconfig')
local on_attach = function(client, bufnr)
    -- Enable LSP-driven autocompletion
    vim.lsp.completion.enable(true, client.id, bufnr, { autotrigger = true })
end
require('lspconfig').clangd.setup {
    on_attach = on_attach,
    cmd = { "clangd", "--background-index" }, -- Optional: indexes in background
}
lspconfig.clangd.setup({
  cmd = {'clangd', '--background-index', '--clang-tidy', '--log=verbose'},
  init_options = {
    fallbackFlags = { '-std=c++17' },
  },
})
vim.lsp.set_log_level("debug")
vim.keymap.set('n', '<leader>d', vim.diagnostic.open_float, { noremap = true, silent = true, desc = 'Show diagnostics' })
--vim.api.nvim_create_autocmd('LspAttach', {
--  desc = 'Enable LSP completion',
--  callback = function(event)
--    local client_id = event.data and event.data.client_id
--    if client_id then
--      vim.lsp.completion.enable(true, client_id, event.buf, { autotrigger = true })
--    end
--  end,
--})
--vim.keymap.set('n', 'gd', vim.lsp.buf.definition, {})
--vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, {})
vim.keymap.set('n', '<leader>a', ':ClangdSwitchSourceHeader<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<leader>r', vim.lsp.buf.references, { noremap = true, silent = true })

-- Gets the path of the cpp file corresponding to the current symlinked header file.
local function GetCppFilepathAfterResolvingSymlink()
    local resolved_filename = vim.fn.resolve(vim.fn.expand('%:p'))
    --print(resolved_filename)
    local resolved_dir = vim.fn.fnamemodify(resolved_filename, ':h')
    --print(resolved_dir)
    local bname = vim.fn.fnamemodify(resolved_filename, ':t')
    --print(bname)
    local bname_wo_ext = vim.fn.fnamemodify(bname, ':r')
    --print(bname_wo_ext)
    return resolved_dir .. '/' .. bname_wo_ext .. '.cpp'
end

-- Calls GetCppFilepathAfterResolvingSymlink() as a command
vim.api.nvim_create_user_command('EditLinkedCppFile', function()
  local file = GetCppFilepathAfterResolvingSymlink()
  if file and file ~= "" then
    vim.cmd("edit " .. vim.fn.fnameescape(file))
  else
    print("No file path returned")
  end
end, {})
vim.keymap.set('n', '<leader>lc', ':EditLinkedCppFile<CR>', { noremap = true, silent = true })
EOF

" This statusline show the targeted filepath when the file is symlinked and
" also it shows it relatively to the current working directory.
set statusline=%<%{fnamemodify(resolve(expand('%:p')),\ ':~:.')}\ %h%m%r%=%-14.(%l,%c%V%)\ %P


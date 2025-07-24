" INSTALLATION
" ============
" Since I had issues with the prebuilt binaries not finding the appropriate
" version of glibc, I succeeded in building it from the source, like this:
"
" $ git clone https://github.com/neovim/neovim
" $ cd neovim
" $ git checkout stable
" $ make CMAKE_BUILD_TYPE=RelWithDebInfo CMAKE_INSTALL_PREFIX=/data/chryssoc
" $ make install
"
" The binary will be installed under /data/chryssoc/bin.

call plug#begin()
" List your plugins here
" Plug 'tpope/vim-sensible'
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}  " We recommend updating the parsers on update
"Plug 'neovim/nvim-lspconfig'
Plug 'folke/trouble.nvim'
Plug 'nvim-telescope/telescope.nvim'
Plug 'nvim-lua/plenary.nvim'
"Plug 'itchyny/lightline.vim'
Plug 'nvim-telescope/telescope-fzf-native.nvim', { 'do': 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release' }
" If you want to have icons in your statusline choose one of these
Plug 'nvim-tree/nvim-web-devicons'
Plug 'phleet/vim-mercenary'
Plug 'hedyhli/outline.nvim'
"Plug 'github/copilot.vim'
"Plug 'zbirenbaum/copilot.lua'
Plug 'nvim-lua/plenary.nvim'
"Plug 'CopilotC-Nvim/CopilotChat.nvim'

" Not so sure what all these do. Copy-pasting them from the instructions of Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/cmp-cmdline'
Plug 'hrsh7th/nvim-cmp'
Plug 'hrsh7th/cmp-nvim-lsp'
"Plug 'zbirenbaum/copilot-cmp'

" For vsnip users.
Plug 'hrsh7th/cmp-vsnip'
Plug 'hrsh7th/vim-vsnip'


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
set completeopt+=popup
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
nnoremap <silent><leader>gf :grep! "\b<cword>\b" <CR>:botright copen<CR>
nnoremap <leader>gp :grep! "\b<cword>\b" <CR>:botright copen<CR>
nnoremap <leader>g. :grep! "\b<cword>\b" <CR>:copen<CR>
nnoremap <leader>o :vim /\<<c-r>=expand('<cword>')<CR>\>/j %<CR>:botright copen<CR>
nnoremap <leader>O :vim /\<<c-r>=expand('<cword>')<CR>\>\C/j %<CR>:botright copen<CR>

autocmd BufReadPost quickfix nnoremap <buffer> <CR> <CR>
"set number relativenumber

" FAQ lsp-faq
" Q: How to force-reload LSP?
" A: Stop all clients, then reload the buffer.
"
" :lua vim.lsp.stop_client(vim.lsp.get_clients())
" :edit

lua <<EOF
require'nvim-treesitter.configs'.setup{
    highlight={enable=true},
    -- enable indentation
    indent = { enable = true },
}  -- At the bottom of your init.vim, keep all configs on one line

--local lspconfig = require('lspconfig')
--local on_attach = function(client, bufnr)
--    -- Enable LSP-driven autocompletion
--    vim.lsp.completion.enable(true, client.id, bufnr, { autotrigger = true })
--end
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

local function find_project_root()
  local compile_db = vim.fs.find('compile_commands.json', { upward = true })[1]
  if compile_db then
    return vim.fs.dirname(compile_db)
  end

  local vc_dir = vim.fs.find({'.hg', '.git'}, { upward = true })[1]
  if vc_dir then
    return vim.fs.dirname(vc_dir)
  end

  return vim.fn.getcwd()
end

-- Function to start the clangd language server
local function start_clangd()
  local root_dir = find_project_root()

  -- Avoid starting multiple clients for the same root_dir
  for _, client in ipairs(vim.lsp.get_clients({ name = 'clangd' })) do
    if client.config.root_dir == root_dir then
      return -- Already started for this project
    end
  end

  local config = {
    name = 'clangd',
    cmd = { "clangd", "--log=verbose", "--pretty" },
    filetypes = { 'c', 'cpp', 'objc', 'objcpp', 'h', 'hpp' },
    root_dir = root_dir,
    on_init = function(client)
      print('LSP started:', client.name)
    end,
  }

  vim.lsp.start(config)
end

function SwitchSourceHeader()
    local bufnr = 0  -- Current buffer
    local uri = vim.uri_from_bufnr(bufnr)  -- Get the URI of the current file
    local params = { uri = uri }  -- Parameters for the LSP request

    vim.lsp.buf_request(bufnr, "textDocument/switchSourceHeader", params, function(err, result)
        if err then
            print("Error switching file: " .. err.message)
            return
        end
        if result then
            local target_uri = result  -- URI of the corresponding file
            local target_path = vim.uri_to_fname(target_uri)  -- Convert URI to file path
            vim.cmd("edit " .. target_path)  -- Open the file in the current window
        else
            print("No corresponding file found")
        end
    end)
end

-- Map a key to switch between source and header files
vim.keymap.set('n', '<Leader>a', SwitchSourceHeader, { noremap = true, silent = true })
vim.keymap.set('n', '<leader>r', vim.lsp.buf.references, { noremap = true, silent = true })


-- Create an autocommand to start clangd when relevant files are opened
vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
  pattern = { "*.c", "*.cpp", "*.cc", "*.h", "*.hpp", "*.objc", "*.objcpp" },
  callback = function(args)
    local buf = args.buf
    if not vim.lsp.get_clients({ bufnr = buf })[1] then
      local root = find_project_root()
      vim.lsp.start({
        name = "clangd",
        cmd = { "clangd", "--log=verbose", "--pretty" },
        root_dir = root,
      })
    end
  end,
})

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

local function GetCppFilepathAfterResolvingSymlink()
    local original_filename = vim.fn.expand('%:p')
    local extension = vim.fn.fnamemodify(original_filename, ':e')
    local resolved_filename = vim.fn.resolve(original_filename)
    --print(resolved_filename)
    local resolved_dir = vim.fn.fnamemodify(resolved_filename, ':h')
    --print(resolved_dir)
    local bname = vim.fn.fnamemodify(resolved_filename, ':t')
    --print(bname)
    local bname_wo_ext = vim.fn.fnamemodify(bname, ':r')
    --print(bname_wo_ext)
    print(resolved_dir .. '/' .. bname_wo_ext .. '.' .. extension)
    return resolved_dir .. '/' .. bname_wo_ext .. '.' .. extension
end

local function resolvedFilepath()
    local resolved_filename = vim.fn.resolve(vim.fn.expand('%:p'))
    --return vim.fn.fnamemodify(resolved_filepath, ':~:.');
    return "MITSOS"
end

-- Calls GetCppFilepathAfterResolvingSymlink() as a command
vim.api.nvim_create_user_command('EditLinkedCppFile', function()
  local file = GetCppFilepathAfterResolvingSymlink()
  if file and file ~= "" then
    -- First delete the current buffer, because it seems that it detects that it's
    -- opening the same file and eventually does not open the linked file.
    -- First get the current buffer number
    local buf = vim.api.nvim_get_current_buf()
    -- Delete the current buffer
    vim.api.nvim_buf_delete(buf, { force = false })
    -- Open the linked file
    vim.cmd("edit " .. vim.fn.fnameescape(file))
  else
    print("No file path returned")
  end
end, {})
vim.keymap.set('n', '<leader>lc', ':EditLinkedCppFile<CR>', { noremap = true, silent = true })

local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope find files' })
vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })
vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })
vim.keymap.set('n', '<Leader>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', { noremap = true, silent = true })

require("outline").setup({})
vim.keymap.set("n", "<leader>o", "<cmd>Outline<CR>", { desc = "Toggle Outline" })

require'nvim-web-devicons'.setup {
 -- your personal icons can go here (to override)
 -- you can specify color or cterm_color instead of specifying both of them
 -- DevIcon will be appended to `name`
 override = {
  zsh = {
    icon = "",
    color = "#428850",
    cterm_color = "65",
    name = "Zsh"
  }
 };
 -- globally enable different highlight colors per icon (default to true)
 -- if set to false all icons will have the default icon's color
 color_icons = true;
 -- globally enable default icons (default to false)
 -- will get overriden by `get_icons` option
 default = true;
 -- globally enable "strict" selection of icons - icon will be looked up in
 -- different tables, first by filename, and if not found by extension; this
 -- prevents cases when file doesn't have any extension but still gets some icon
 -- because its name happened to match some extension (default to false)
 strict = true;
 -- set the light or dark variant manually, instead of relying on `background`
 -- (default to nil)
 variant = "light|dark";
 -- same as `override` but specifically for overrides by filename
 -- takes effect when `strict` is true
 override_by_filename = {
  [".gitignore"] = {
    icon = "",
    color = "#f1502f",
    name = "Gitignore"
  }
 };
 -- same as `override` but specifically for overrides by extension
 -- takes effect when `strict` is true
 override_by_extension = {
  ["log"] = {
    icon = "",
    color = "#81e043",
    name = "Log"
  }
 };
 -- same as `override` but specifically for operating system
 -- takes effect when `strict` is true
 override_by_operating_system = {
  ["apple"] = {
    icon = "",
    color = "#A2AAAD",
    cterm_color = "248",
    name = "Apple",
  },
 };
};

require'nvim-treesitter.configs'.setup {
  textobjects = {
    select = {
      enable = true,

      -- Automatically jump forward to textobj, similar to targets.vim
      lookahead = true,

      keymaps = {
        -- You can use the capture groups defined in textobjects.scm
        ["af"] = "@function.outer",
        ["if"] = "@function.inner",
        ["ac"] = "@class.outer",
        -- You can optionally set descriptions to the mappings (used in the desc parameter of
        -- nvim_buf_set_keymap) which plugins like which-key display
        ["ic"] = { query = "@class.inner", desc = "Select inner part of a class region" },
        -- You can also use captures from other query groups like `locals.scm`
        ["as"] = { query = "@local.scope", query_group = "locals", desc = "Select language scope" },
      },
      -- You can choose the select mode (default is charwise 'v')
      --
      -- Can also be a function which gets passed a table with the keys
      -- * query_string: eg '@function.inner'
      -- * method: eg 'v' or 'o'
      -- and should return the mode ('v', 'V', or '<c-v>') or a table
      -- mapping query_strings to modes.
      selection_modes = {
        ['@parameter.outer'] = 'v', -- charwise
        ['@function.outer'] = 'V', -- linewise
        ['@class.outer'] = '<c-v>', -- blockwise
      },
      -- If you set this to `true` (default is `false`) then any textobject is
      -- extended to include preceding or succeeding whitespace. Succeeding
      -- whitespace has priority in order to act similarly to eg the built-in
      -- `ap`.
      --
      -- Can also be a function which gets passed a table with the keys
      -- * query_string: eg '@function.inner'
      -- * selection_mode: eg 'v'
      -- and should return true or false
      include_surrounding_whitespace = true,
    },
  },
}

local has_words_before = function()
  if vim.api.nvim_buf_get_option(0, "buftype") == "prompt" then return false end
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  return (col ~= 0 and vim.api.nvim_buf_get_text(0, line-1, 0, line-1, col, {})[1]:match("^%s*$") == nil)
end

local capabilities = require('cmp_nvim_lsp').default_capabilities()

vim.keymap.set('n', '<leader>ff', function()
  require('telescope.builtin').find_files({ cwd = find_project_root() })
end, { desc = 'Find files in specified project root' })

vim.lsp.set_log_level("trace")

-- Function to list resolved filepaths of all listed buffers.
local function list_buffers()
  local bufs = vim.api.nvim_list_bufs()  -- Get all buffer handles
  local lines = {}                      -- Table to accumulate output lines

  for _, buf in ipairs(bufs) do
    -- Only process buffers that are listed
    if vim.api.nvim_buf_get_option(buf, "buflisted") then
      local name = vim.api.nvim_buf_get_name(buf)
      if name == "" then
        table.insert(lines, string.format("%d: [No Name]", buf))
      else
        -- Resolve symlinks then make filename prettier (e.g. abbreviating home directory)
        local resolved = vim.fn.fnamemodify(vim.fn.resolve(name), ":~:.")
        table.insert(lines, string.format("%d: %s", buf, resolved))
      end
    end
  end

  -- Print the output as separate lines
  print(table.concat(lines, "\n"))
end

-- Create a user command "Lls" that calls the list_buffers function.
vim.api.nvim_create_user_command("Lls", list_buffers, {})
vim.api.nvim_create_user_command("LspStop", 'lua vim.lsp.stop_client(vim.lsp.get_clients())', {})

EOF
" END OF LUA INIT SEGMENT

" This statusline show the targeted filepath when the file is symlinked and
" also it shows it relatively to the current working directory.
set statusline=%<%{fnamemodify(resolve(expand('%:p')),\ ':~:.')}\ %h%m%r%=%-14.(%l,%c%V%)\ %P
nnoremap <leader>rp :echo fnamemodify(resolve(expand('%:p')), ':~:.')<CR>


-- INSTALLATION
-- ============
-- Since I had issues with the prebuilt binaries not finding the appropriate
-- version of glibc, I succeeded in building it from the source, like this:
--
-- $ git clone https://github.com/neovim/neovim
-- $ cd neovim
-- $ git tag -l # look for the latest version
-- $ git checkout v0.11.3
-- $ make CMAKE_BUILD_TYPE=Release CMAKE_INSTALL_PREFIX=/data/chryssoc
-- $ make install
--
-- The binary will be installed under /data/chryssoc/bin.

-- Plugin management with vim-plug
vim.cmd([[
call plug#begin()
" List your plugins here
" Plug 'tpope/vim-sensible'
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}  " We recommend updating the parsers on update
Plug 'neovim/nvim-lspconfig'
Plug 'folke/trouble.nvim'
Plug 'nvim-telescope/telescope.nvim'
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-lualine/lualine.nvim'
Plug 'nvim-telescope/telescope-fzf-native.nvim', { 'do': 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release' }
" If you want to have icons in your statusline choose one of these
Plug 'nvim-tree/nvim-web-devicons'
Plug 'phleet/vim-mercenary'
Plug 'stevearc/aerial.nvim'
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
]])

-- Vimscript functions (keeping as-is for now, can be converted to Lua later)
vim.cmd([[
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
]])

-- Basic settings
vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.shiftround = true
vim.opt.smarttab = true
vim.opt.showcmd = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.signcolumn = "yes"
vim.opt.completeopt:append("popup")

-- Complete option settings
vim.opt.complete:remove("t")
vim.opt.complete:remove("i")

-- More Vimscript functions (keeping as-is)
vim.cmd([[
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
]])

-- Path settings
vim.opt.path = "include/**,src/**,export/**,source/**,../include/**,../export/**,../src/**,../source/**"

-- Commands
vim.api.nvim_create_user_command('A', function()
  vim.cmd("call SwitchToOtherFile(PotentialOtherFiles(expand('%')), 'find')")
end, {})

vim.api.nvim_create_user_command('AS', function()
  vim.cmd("call SwitchToOtherFile(PotentialOtherFiles(expand('%')), 'sfind')")
end, {})

vim.api.nvim_create_user_command('AV', function()
  vim.cmd("call SwitchToOtherFile(PotentialOtherFiles(expand('%')), 'vert sfind')")
end, {})

-- Key mappings
vim.keymap.set('n', '<F1>', ':update<cr>', { noremap = true })
vim.keymap.set('n', '<F3>', ':set hls!<cr>', { noremap = true, silent = true })

-- Search mappings using quickfix list
vim.keymap.set('n', '<leader>gf', ':grep! "\\b<cword>\\b" <CR>:botright copen<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<leader>gp', ':grep! "\\b<cword>\\b" <CR>:botright copen<CR>', { noremap = true })
vim.keymap.set('n', '<leader>g.', ':grep! "\\b<cword>\\b" <CR>:copen<CR>', { noremap = true })
vim.keymap.set('n', '<leader>o', ':vim /\\<<c-r>=expand(\'<cword>\')<CR>\\>/j %<CR>:botright copen<CR>', { noremap = true })
vim.keymap.set('n', '<leader>O', ':vim /\\<<c-r>=expand(\'<cword>\')<CR>\\>\\C/j %<CR>:botright copen<CR>', { noremap = true })

-- Autocmd for quickfix
vim.api.nvim_create_autocmd("BufReadPost", {
  pattern = "quickfix",
  callback = function()
    vim.keymap.set('n', '<CR>', '<CR>', { buffer = true })
  end
})

-- LSP and plugin configuration
vim.lsp.set_log_level("debug")
vim.keymap.set('n', '<leader>d', vim.diagnostic.open_float, { noremap = true, silent = true, desc = 'Show diagnostics' })

-- Project root finding function
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

-- Configure clangd with lspconfig
require'lspconfig'.clangd.setup{
  cmd = { "clangd", "--log=verbose", "--pretty" },
  filetypes = { 'c', 'cpp', 'objc', 'objcpp', 'h', 'hpp' },
  root_dir = function(fname)
    return find_project_root()
  end,
  capabilities = require('cmp_nvim_lsp').default_capabilities(),
  on_init = function(client)
    print('LSP started:', client.name)
  end,
}

-- Switch source/header function
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

-- LSP keymaps
vim.keymap.set('n', '<Leader>a', SwitchSourceHeader, { noremap = true, silent = true })
vim.keymap.set('n', '<leader>r', vim.lsp.buf.references, { noremap = true, silent = true })

-- Symlink handling functions
local function GetCppFilepathAfterResolvingSymlink()
    local original_filename = vim.fn.expand('%:p')
    local extension = vim.fn.fnamemodify(original_filename, ':e')
    local resolved_filename = vim.fn.resolve(original_filename)
    local resolved_dir = vim.fn.fnamemodify(resolved_filename, ':h')
    local bname = vim.fn.fnamemodify(resolved_filename, ':t')
    local bname_wo_ext = vim.fn.fnamemodify(bname, ':r')
    print(resolved_dir .. '/' .. bname_wo_ext .. '.' .. extension)
    return resolved_dir .. '/' .. bname_wo_ext .. '.' .. extension
end

vim.api.nvim_create_user_command('EditLinkedCppFile', function()
  local file = GetCppFilepathAfterResolvingSymlink()
  if file and file ~= "" then
    local buf = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_delete(buf, { force = false })
    vim.cmd("edit " .. vim.fn.fnameescape(file))
  else
    print("No file path returned")
  end
end, {})

vim.keymap.set('n', '<leader>lc', ':EditLinkedCppFile<CR>', { noremap = true, silent = true })

-- Telescope related code here.
-- Function to safely load private path suffixes
local function load_private_suffixes()
  local config_path = vim.fn.stdpath("config")
  local local_config_file = config_path .. "/local_config.lua"

  -- Check if local config file exists
  if vim.fn.filereadable(local_config_file) == 1 then
    -- Safely load the local config
    local ok, local_config = pcall(dofile, local_config_file)
    if ok and local_config and local_config.private_suffixes then
      return local_config.private_suffixes
    else
      vim.notify("Warning: Could not load private suffixes from local_config.lua", vim.log.levels.WARN)
    end
  else
    vim.notify("Info: local_config.lua not found, using default suffixes", vim.log.levels.INFO)
  end

  -- Try to load from PROJECT_ROOTS environment variable
  -- E.g. in your .bashrc file you could have something like this:
  -- export PROJECT_ROOTS="client-work:open-source:internal-tools"
  local env_roots = os.getenv("PROJECT_ROOTS")
  if env_roots then
    local suffixes = {}
    for suffix in string.gmatch(env_roots, "([^:]+)") do
      -- Ensure suffix starts with /
      if not suffix:match("^/") then
        suffix = "/" .. suffix
      end
      table.insert(suffixes, suffix)
    end
    if #suffixes > 0 then
      return suffixes
    end
  end

  -- Final fallback: return empty table (will use base project root only)
  return {}
end

-- Function to build complete project paths
local function get_project_roots()
  local base_root = find_project_root()
  local private_suffixes = load_private_suffixes()

  -- If no suffixes configured, just use the base project root
  if #private_suffixes == 0 then
    return { base_root }
  end

  local complete_paths = {}
  for _, suffix in ipairs(private_suffixes) do
    table.insert(complete_paths, base_root .. suffix)
  end

  return complete_paths
end

-- Telescope setup with dynamic project roots
local telescope = require('telescope')
telescope.setup({
  defaults = {
    layout_strategy = 'vertical',
    layout_config = {
      vertical = {
        height = 0.95,
        width = 0.9,
        preview_height = 0.6,  -- 60% for preview
        prompt_position = "bottom",
        mirror = false,  -- preview below results
      },
    },
    sorting_strategy = "descending",  -- Default, natural for vertical
    -- winblend = 10,  -- Optional: slight transparency
  },
  pickers = {
    find_files = {
      search_dirs = get_project_roots()  -- Built dynamically
    },
    live_grep = {
      search_dirs = get_project_roots()
    }
  },
  extensions = {
    -- Your extensions here
  }
})

-- Telescope configuration
local telescope_builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', telescope_builtin.find_files, { desc = 'Telescope find files' })
vim.keymap.set('n', '<leader>fg', telescope_builtin.live_grep, { desc = 'Telescope live grep' })
vim.keymap.set('n', '<leader>fb', telescope_builtin.buffers, { desc = 'Telescope buffers' })
vim.keymap.set('n', '<leader>fh', telescope_builtin.help_tags, { desc = 'Telescope help tags' })
vim.keymap.set('n', '<leader>fs', telescope_builtin.lsp_document_symbols, { desc = 'Find symbols in document' })
vim.keymap.set('n', '<leader>fS', telescope_builtin.lsp_workspace_symbols, { desc = 'Find symbols in workspace' })
vim.keymap.set('n', '<leader>fd', telescope_builtin.lsp_dynamic_workspace_symbols, { desc = 'Find symbols dynamically' })

-- Treesitter configuration
require'nvim-treesitter.configs'.setup{
    highlight = { enable = true },
    indent = { enable = true },
    textobjects = {
      select = {
        enable = true,
        lookahead = true,
        keymaps = {
          ["af"] = "@function.outer",
          ["if"] = "@function.inner",
          ["ac"] = "@class.outer",
          ["ic"] = { query = "@class.inner", desc = "Select inner part of a class region" },
          ["as"] = { query = "@local.scope", query_group = "locals", desc = "Select language scope" },
        },
        selection_modes = {
          ['@parameter.outer'] = 'v', -- charwise
          ['@function.outer'] = 'V', -- linewise
          ['@class.outer'] = '<c-v>', -- blockwise
        },
        include_surrounding_whitespace = true,
      },
    },
}

-- Web devicons configuration
require'nvim-web-devicons'.setup {
   override = {
    zsh = {
      icon = "",
      color = "#428850",
      cterm_color = "65",
      name = "Zsh"
    }
   },
   color_icons = true,
   default = true,
   strict = true,
   variant = "light|dark",
   override_by_filename = {
    [".gitignore"] = {
      icon = "",
      color = "#f1502f",
      name = "Gitignore"
    }
   },
   override_by_extension = {
    ["log"] = {
      icon = "",
      color = "#81e043",
      name = "Log"
    }
   },
   override_by_operating_system = {
    ["apple"] = {
      icon = "",
      color = "#A2AAAD",
      cterm_color = "248",
      name = "Apple",
    },
   },
}

-- Buffer listing function
local function list_buffers()
  local bufs = vim.api.nvim_list_bufs()
  local lines = {}
  for _, buf in ipairs(bufs) do
    -- Use vim.bo instead of deprecated nvim_buf_get_option
    if vim.bo[buf].buflisted then
      local name = vim.api.nvim_buf_get_name(buf)
      if name == "" then
        table.insert(lines, string.format("%d: [No Name]", buf))
      else
        -- Add error handling for resolve and fnamemodify
        local ok, resolved = pcall(function()
          return vim.fn.fnamemodify(vim.fn.resolve(name), ":~:.")
        end)
        if ok then
          table.insert(lines, string.format("%d: %s", buf, resolved))
        else
          -- Fallback to original name if resolve fails
          table.insert(lines, string.format("%d: %s", buf, name))
        end
      end
    end
  end
  print(table.concat(lines, "\n"))
end

vim.api.nvim_create_user_command("Lls", list_buffers, {})
vim.api.nvim_create_user_command("LspStop", function()
  vim.lsp.stop_client(vim.lsp.get_clients())
end, {})

-- Custom Mercurial bookmark component for Lualine
local function hg_bookmark()
  local hg_dir = vim.fn.finddir('.hg', vim.fn.getcwd() .. ';')
  if hg_dir == '' then
    return ''
  end
  local bookmark = ''
  local bookmark_file = hg_dir .. '/bookmarks.current'
  local f = io.open(bookmark_file, 'r')
  if f then
    bookmark = f:read('*line') or ''
    f:close()
  end
  if bookmark and bookmark ~= '' then
    local max_length = 20
    if #bookmark > max_length then
      bookmark = bookmark:sub(1, max_length - 3) .. '...'
    end
    return '\u{f02e} ' .. bookmark
  end
  return ''
end

-- Function to get filename with symlink resolution and modification indicator
local function get_filename_with_symlink()
  local filename = vim.fn.expand('%:.')  -- Get relative path
  if filename == '' then
    return '[No Name]'
  end

  -- Check if the file is a symbolic link
  local full_path = vim.fn.expand('%:p')  -- Get absolute path
  local resolved_path = vim.fn.resolve(full_path)  -- Resolve symlinks

  local display_name
  if full_path ~= resolved_path then
    -- File is a symlink, show the target with an indicator
    local resolved_relative = vim.fn.fnamemodify(resolved_path, ':.')
    display_name = resolved_relative .. ' 🔗'
  else
    -- Not a symlink, just return the relative path
    display_name = filename
  end

  -- Add modification indicator if buffer is modified (on the right, like vanilla Neovim)
  if vim.bo.modified then
    display_name = display_name .. ' [+]'
  end

  return display_name
end



-- Lualine configuration
require("lualine").setup({
  options = {
    theme = 'onedark',
    component_separators = { left = '', right = ''},
    section_separators = { left = '', right = ''},
  },
  sections = {
    lualine_b = {'branch', 'diff', 'diagnostics'},
    lualine_c = { get_filename_with_symlink },
    lualine_x = { "aerial" },
    lualine_y = { 'filetype', 'fileformat', 'encoding' },
    lualine_z = { 'progress', 'location' }
  },
})

-- Aerial configuration
require('aerial').setup({
  backend = {"lsp", "treesitter"},
  show_guides = true,
  layout = {
    max_width = 40,
    min_width = 40,
    win_opts = {},
    default_direction = "prefer_right",
    placement = "window",
    resize_to_content = true,
    preserve_equality = false,
  },
})

-- Status line with symlink resolution
vim.opt.statusline = "%<%{fnamemodify(resolve(expand('%:p')),'~:.')}%% %h%m%r%=%-14.(%l,%c%V%)\\ %P"

-- Keymap to show resolved path
vim.keymap.set('n', '<leader>rp', function()
  local resolved = vim.fn.fnamemodify(vim.fn.resolve(vim.fn.expand('%:p')), ':~:.')
  print(resolved)
end, { noremap = true })

vim.keymap.set('n', '<Leader>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', { noremap = true, silent = true })

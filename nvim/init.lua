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

vim.g.clipboard = {
  name = 'OSC 52',
  copy = {
    ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
    ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
  },
  paste = {
    ['+'] = require('vim.ui.clipboard.osc52').paste('+'),
    ['*'] = require('vim.ui.clipboard.osc52').paste('*'),
  },
}

vim.opt.clipboard = "unnamedplus"
vim.keymap.set('n', '<F1>', ':update<cr>')

-- Define diagnostic signs (place this EARLY in your config)
-- Modern diagnostic configuration (Neovim 0.10+)
vim.diagnostic.config({
    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] = "E",
            [vim.diagnostic.severity.WARN] = "W",
            [vim.diagnostic.severity.INFO] = "I",
            [vim.diagnostic.severity.HINT] = "H",
        },
    },
    underline = true,
    update_in_insert = false,
    severity_sort = true,
    virtual_text = false,
    float = {
        border = 'rounded',
        source = 'always',
    },
})

-- Sign column always visible
vim.opt.signcolumn = "yes"

-- This filetype section must be placed before lazy.nvim configuration.
vim.filetype.add({
  filename = { ["TODO"] = "text", ["DONE"] = "text" },
  extension = { todo = "text" },
  -- Patterns can use Lua patterns; map a whole notes dir to text (could also be markdown):
  pattern = {
    [".*/notes/.*%.txt"] = "text",
    -- Common commit message patterns
    [".*COMMIT_EDITMSG"] = "gitcommit",
    ["hg%-editor%-.*"] = "hgcommit",
    ["svn%-commit.*%.tmp"] = "svncommit",
    ["COMMIT_MSG"] = "gitcommit",
  },
})

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

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

-- Function to safely load private path suffixes
local function load_private_suffixes()
  local config_path = vim.fn.stdpath("config")
  local local_config_file = config_path .. "/local_config.lua"

  if vim.fn.filereadable(local_config_file) == 1 then
    local ok, local_config = pcall(dofile, local_config_file)
    if ok and local_config and local_config.private_suffixes then
      return local_config.private_suffixes
    end
  end

  local env_roots = os.getenv("PROJECT_ROOTS")
  if env_roots then
    local suffixes = {}
    for suffix in string.gmatch(env_roots, "([^:]+)") do
      if not suffix:match("^/") then
        suffix = "/" .. suffix
      end
      table.insert(suffixes, suffix)
    end
    if #suffixes > 0 then
      return suffixes
    end
  end

  return {}
end

-- Function to build complete project paths
local function get_project_roots()
  local base_root = find_project_root()
  local private_suffixes = load_private_suffixes()

  if #private_suffixes == 0 then
    return { base_root }
  end

  local complete_paths = {}
  for _, suffix in ipairs(private_suffixes) do
    table.insert(complete_paths, base_root .. suffix)
  end

  return complete_paths
end

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
vim.opt.completeopt:append("popup")
vim.opt.autoread = false
vim.opt.hidden = false
vim.opt.path = "include/**,src/**,export/**,source/**,../include/**,../export/**,../src/**,../source/**"

-- Complete option settings
vim.opt.complete:remove("t")
vim.opt.complete:remove("i")

-- Configure all plugins with lazy.nvim
require("lazy").setup({
  {
    "williamboman/mason.nvim",
    build = ":MasonUpdate",
    config = function()
      require("mason").setup()
    end,
  },

  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = { "clangd" },
        automatic_installation = true,
        handlers = {
          function(server_name)
            if server_name ~= 'clangd' and server_name ~= 'ltex' then
              local caps = vim.lsp.protocol.make_client_capabilities()
              pcall(function()
                caps = require("cmp_nvim_lsp").default_capabilities(caps)
              end)
              require('lspconfig')[server_name].setup({
                capabilities = caps,
              })
            end
          end,
        },
      })
    end,
  },

  -- Treesitter for syntax highlighting and parsing
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
    },
    config = function()
      require('nvim-treesitter.configs').setup {
        ensure_installed = {"c", "cpp", "doxygen", "json", "python", "bash", "yang"},  -- Add Python and Bash parsers
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = true, -- I need this for TODO, FIXME, XXX
        },
        -- Add this for spell checking in comments
        incremental_selection = {
          enable = true,
        },
        indent = { enable = true },
        textobjects = {
          move = {
            enable = true,
            set_jumps = true,
            goto_next_start = {
              ["]m"] = "@function.outer",
              ["]f"] = "@function.inner",
              ["]]"] = "@class.outer",
            },
            goto_next_end = {
              ["]M"] = "@function.outer",
              ["]["] = "@class.outer",
            },
            goto_previous_start = {
              ["[m"] = "@function.outer",
              ["[f"] = "@function.inner",
              ["[["] = "@class.outer",
            },
            goto_previous_end = {
              ["[M"] = "@function.outer",
              ["[]"] = "@class.outer",
            },
          },
          select = {
            enable = true,
            keymaps = {
              ["af"] = "@function.outer",
              ["if"] = "@function.inner",
              ["ac"] = "@class.outer",
              ["ic"] = "@class.inner",
            },
          },
        },
      }
    end,
  },
  {
    "danymat/neogen",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      require('neogen').setup {
        enabled = true,
        languages = {
          cpp = {
            template = { annotation_convention = "doxygen" },
          },
          c = {
            template = { annotation_convention = "doxygen" },

          },
        },
      }
      -- Optional keymaps:
      vim.keymap.set("n", "<leader>ng", function() require("neogen").generate() end,
        { desc = "Generate Doxygen docblock" })
    end
  },

  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "williamboman/mason-lspconfig.nvim",
      "williamboman/mason.nvim",
    },
    config = function()
      local caps = vim.lsp.protocol.make_client_capabilities()
      pcall(function()
        caps = require("cmp_nvim_lsp").default_capabilities(caps)
      end)
      caps.textDocument = caps.textDocument or {}
      caps.textDocument.documentSymbol = vim.tbl_deep_extend("force",
        caps.textDocument.documentSymbol or {},
        { hierarchicalDocumentSymbolSupport = true }
      )

      local on_attach = function(client, bufnr)
        local opts = { buffer = bufnr, noremap = true, silent = true }
        vim.keymap.set('n', '<leader>h', '<cmd>ClangdSwitchSourceHeader<CR>',
          vim.tbl_extend('force', opts, { desc = 'Switch header/source' }))
        vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
      end

      -- OLD API - works reliably
      require('lspconfig').clangd.setup{
        cmd = {
          vim.fn.stdpath('data') .. '/mason/bin/clangd',
          "--background-index",
          "--clang-tidy",
          "--log=verbose",
          "--pretty",
          "--completion-style=detailed",
          "--cross-file-rename",
          "--header-insertion=iwyu",
        },
        filetypes = { 'c', 'cpp', 'objc', 'objcpp', 'h', 'hpp' },
        root_dir = function(fname)
          return find_project_root()
        end,
        capabilities = caps,
        on_attach = on_attach,
        on_init = function(client)
          print('LSP started:', client.name)
        end,
      }
    end,
  },

  -- Completion plugins (for LSP integration only)
  { "hrsh7th/nvim-cmp", lazy = true },
  { "hrsh7th/cmp-nvim-lsp", lazy = true },
  { "hrsh7th/cmp-buffer", lazy = true },
  { "hrsh7th/cmp-path", lazy = true },
  { "hrsh7th/cmp-cmdline", lazy = true },
  { "hrsh7th/cmp-vsnip", lazy = true },
  { "hrsh7th/vim-vsnip", lazy = true },

  -- Trouble for diagnostics
  {
    "folke/trouble.nvim",
    cmd = "Trouble",
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (Trouble)" },
      { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer Diagnostics (Trouble)" },
      { "<leader>cs", "<cmd>Trouble symbols toggle focus=false<cr>", desc = "Symbols (Trouble)" },
      { "<leader>cl", "<cmd>Trouble lsp toggle focus=false win.position=right<cr>", desc = "LSP Definitions / references / ... (Trouble)" },
      { "<leader>xL", "<cmd>Trouble loclist toggle<cr>", desc = "Location List (Trouble)" },
      { "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix List (Trouble)" },
    },
    opts = {},
  },

  -- Telescope fuzzy finder
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    keys = {
      { "<leader>ff", function() require('telescope.builtin').find_files() end, desc = "Find Files" },
      { "<leader>fg", function() require('telescope.builtin').live_grep() end, desc = "Live Grep" },
      { "<leader>fb", function() require('telescope.builtin').buffers() end, desc = "Buffers" },
      { "<leader>fh", function() require('telescope.builtin').help_tags() end, desc = "Help Tags" },
      { "<leader>fs", function() require('telescope.builtin').lsp_document_symbols() end, desc = "Document Symbols" },
      { "<leader>fS", function() require('telescope.builtin').lsp_workspace_symbols() end, desc = "Workspace Symbols" },
      { "<leader>fd", function() require('telescope.builtin').lsp_dynamic_workspace_symbols() end, desc = "Dynamic Workspace Symbols" },
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release",
      },
    },
    config = function()
      local telescope = require('telescope')
      telescope.setup({
        defaults = {
          layout_strategy = 'vertical',
          layout_config = {
            vertical = {
              height = 0.95,
              width = 0.9,
              preview_height = 0.6,
              prompt_position = "bottom",
              mirror = false,
            },
          },
          sorting_strategy = "descending",
        },
        pickers = {
          find_files = {
            search_dirs = get_project_roots()
          },
          live_grep = {
            search_dirs = get_project_roots()
          },
          lsp_dynamic_workspace_symbols = {
            fname_width = 60,
            symbol_width = 60,
          },
          lsp_document_symbols = {
            fname_width = 60,
            symbol_width = 60,
          },
        },
      })
      telescope.load_extension("fzf")
    end,
  },

  -- Status line
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      -- Custom Mercurial bookmark component
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
        local filename = vim.fn.expand('%:.')
        if filename == '' then
          return '[No Name]'
        end

        local full_path = vim.fn.expand('%:p')
        local resolved_path = vim.fn.resolve(full_path)

        local display_name
        if full_path ~= resolved_path then
          local resolved_relative = vim.fn.fnamemodify(resolved_path, ':.')
          display_name = resolved_relative .. ' 🔗'
        else
          display_name = filename
        end

        if vim.bo.modified then
          display_name = display_name .. ' [+]'
        end

        return display_name
      end

      require("lualine").setup({
        options = {
          theme = 'onedark',
          --theme = {
          --  normal = {
          --      -- Keep onedark's normal colors
          --      a = { bg = '#98c379', fg = '#282c34', gui = 'bold' },
          --      b = { bg = '#3e4451', fg = '#abb2bf' },
          --      c = { bg = '#2c323c', fg = '#abb2bf' },
          --      x = { bg = '#2c323c', fg = '#abb2bf' },
          --      y = { bg = '#3e4451', fg = '#abb2bf' },
          --      z = { bg = '#3e4451', fg = '#abb2bf' }, -- same as y in all modes
          --  },
          --  insert = {
          --      z = { bg = '#3e4451', fg = '#abb2bf' },
          --  },
          --  visual = {
          --      z = { bg = '#3e4451', fg = '#abb2bf' },
          --  },
          --  replace = {
          --      z = { bg = '#3e4451', fg = '#abb2bf' },
          --  },
          --  command = {
          --      z = { bg = '#3e4451', fg = '#abb2bf' },
          --  },
          --},
          component_separators = { left = '', right = ''},
          section_separators = { left = '', right = ''},
        },
        sections = {
          lualine_a = {},
          lualine_b = {'branch', 'diff', 'diagnostics'},
          lualine_c = { get_filename_with_symlink },
          --lualine_x = { "aerial" },
          lualine_x = {  },
          lualine_y = { 'filetype', 'fileformat', 'encoding' },
          lualine_z = { 'progress', 'location' }
        },
      })
    end,
  },

  -- Icons
  {
    "nvim-tree/nvim-web-devicons",
    lazy = true,
    config = function()
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
      }
    end,
  },

  -- Mercurial integration
  { "jlfwong/vim-mercenary" },

  -- Aerial with hierarchical support
  {
    'stevearc/aerial.nvim',
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
      'nvim-tree/nvim-web-devicons',
      'neovim/nvim-lspconfig', -- Ensure LSP loads first
    },
    opts = {
      backends = { "lsp", "treesitter", "markdown", "man", "asciidoc" },
      -- If some filetypes behave better with a different source, override here.
      backends_by_ft = {
        -- Example: if Go methods look flat with gopls, try Tree-sitter first.
        go = { "treesitter", "lsp" },
        cpp = { "lsp", "treesitter" },
        c = { "lsp", "treesitter" },
      },

      layout = {
        max_width = 60,
        min_width = 28,
        win_opts = {},
        default_direction = "prefer_right",
        placement = "window",
        resize_to_content = true,
        preserve_equality = false,
      },

      -- Enable proper hierarchy display
      show_guides = true,
      manage_folds = true,

      -- Configure symbol filtering for class hierarchy
      filter_kind = {
        "Class",
        "Constructor",
        "Destructor",
        "Enum",
        "Function",
        "Interface",
        "Method",
        "Module",
        "Namespace",
        "Struct",
        "Variable",
      },

      -- LSP configuration
      lsp = {
        diagnostics_trigger_update = false,
        update_when_errors = true,
        update_delay = 300,
      },

      -- Visual improvements for hierarchy
      guides = {
        mid_item = "├─",
        last_item = "└─",
        nested_top = "│ ",
        whitespace = "  ",
      },
    },
    keys = {
      { "<leader>o", "<cmd>AerialToggle!<CR>", desc = "Toggle Outline" },
      { "<leader>oo", "<cmd>AerialOpen<CR>", desc = "Open Outline" },
      { "<leader>oc", "<cmd>AerialClose<CR>", desc = "Close Outline" },
      { "<leader>on", "<cmd>AerialNext<CR>", desc = "Next Symbol" },
      { "<leader>op", "<cmd>AerialPrev<CR>", desc = "Prev Symbol" },
      { "[[", "<cmd>AerialPrevUp<CR>", desc = "Prev Symbol Up" },
      { "]]", "<cmd>AerialNextUp<CR>", desc = "Next Symbol Up" },
    },
  },
  {
    'dhruvasagar/vim-table-mode',
    ft = { 'markdown', 'text', 'org', 'rst' },
    keys = {
      { '<leader>tm', '<cmd>TableModeToggle<cr>', desc = 'Toggle Table Mode' },
      { '<leader>tr', '<cmd>TableModeRealign<cr>', desc = 'Realign Table' },
      { '<leader>tdd', '<cmd>TableModeDeleteRow<cr>', desc = 'Delete Row' },
      { '<leader>tdc', '<cmd>TableModeDeleteColumn<cr>', desc = 'Delete Column' },
    },
    config = function()
      -- Configuration
      vim.g.table_mode_corner = '|'
      vim.g.table_mode_border = 0
      vim.g.table_mode_fillchar = ' '
      vim.g.table_mode_header_fillchar = '-'
    end,
  },
})

--vim.cmd('colorscheme habamax')

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
" nnoremap <silent> <leader>c :call ToggleColorColumn()<CR>

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

" Toggle quickfix window
function! ToggleQuickFix()
    if empty(filter(getwininfo(), 'v:val.quickfix'))
        botright cwindow
    else
        cclose
    endif
endfunction
nnoremap <silent> <F4> :call ToggleQuickFix()<CR>

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
        execute a:cmd . ' ' . a:others[0]
    catch /E345:/
        if nOthers > 1
            execute a:cmd . ' ' . a:others[1]
        endif
    endtry
endfunction

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

vim.api.nvim_create_user_command('EditLinkedCppFile', function()
  local original_filename = vim.fn.expand('%:p')
  local extension = vim.fn.fnamemodify(original_filename, ':e')
  local resolved_filename = vim.fn.resolve(original_filename)
  local resolved_dir = vim.fn.fnamemodify(resolved_filename, ':h')
  local bname = vim.fn.fnamemodify(resolved_filename, ':t')
  local bname_wo_ext = vim.fn.fnamemodify(bname, ':r')
  local file = resolved_dir .. '/' .. bname_wo_ext .. '.' .. extension

  if file and file ~= "" then
    local buf = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_delete(buf, { force = false })
    vim.cmd("edit " .. vim.fn.fnameescape(file))
  else
    print("No file path returned")
  end
end, {})

vim.api.nvim_create_user_command("Lls", function()
  local bufs = vim.api.nvim_list_bufs()
  local lines = {}
  for _, buf in ipairs(bufs) do
    if vim.bo[buf].buflisted then
      local name = vim.api.nvim_buf_get_name(buf)
      if name == "" then
        table.insert(lines, string.format("%d: [No Name]", buf))
      else
        local ok, resolved = pcall(function()
          return vim.fn.fnamemodify(vim.fn.resolve(name), ":~:.")
        end)
        if ok then
          table.insert(lines, string.format("%d: %s", buf, resolved))
        else
          table.insert(lines, string.format("%d: %s", buf, name))
        end
      end
    end
  end
  print(table.concat(lines, "\n"))
end, {})

vim.api.nvim_create_user_command("LspStop", function()
  vim.lsp.stop_client(vim.lsp.get_clients())
end, {})

vim.api.nvim_create_user_command('LspDiag', function(opts)
  local args = vim.split(opts.args, '%s+')
  local use_loclist = false
  local all_buffers = false
  local severity_filter = nil

  for _, arg in ipairs(args) do
    if arg == 'loc' or arg == 'loclist' then
      use_loclist = true
    elseif arg == 'all' then
      all_buffers = true
    elseif arg == 'error' then
      severity_filter = vim.diagnostic.severity.ERROR
    elseif arg == 'warn' then
      severity_filter = {min = vim.diagnostic.severity.WARN}
    end
  end

  if use_loclist then
    local config = {open = true}
    if severity_filter then
      config.severity = severity_filter
    end
    if not all_buffers then
      config.bufnr = 0
    end
    vim.diagnostic.setloclist(config)
  else
    local bufnr = all_buffers and nil or 0
    local diagnostics = vim.diagnostic.get(bufnr, {severity = severity_filter})
    local qf_items = vim.diagnostic.toqflist(diagnostics)
    vim.fn.setqflist(qf_items, 'r')
    vim.cmd('copen')
  end
end, {
  nargs = '*',
  complete = function()
    return {'loclist', 'loc', 'all', 'error', 'warn'}
  end,
  desc = 'Show LSP diagnostics in quickfix (default) or location list'
})

-- Key mappings
vim.keymap.set({'n', 'i', 'v'}, '<F1>', '<Esc>:update<cr>')
vim.keymap.set('n', '<F3>', ':set hls!<cr>', { silent = true })

-- Search mappings using quickfix list
vim.keymap.set('n', '<leader>gf', ':grep! "\\b<cword>\\b" <CR>:botright copen<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<leader>gp', ':grep! "\\b<cword>\\b" <CR>:botright copen<CR>', { noremap = true })
vim.keymap.set('n', '<leader>g.', ':grep! "\\b<cword>\\b" <CR>:copen<CR>', { noremap = true })
--vim.keymap.set('n', '<leader>o', ':vim /\\<<c-r>=expand(\'<cword>\')<CR>\\>/j %<CR>:botright copen<CR>', { noremap = true })
--vim.keymap.set('n', '<leader>O', ':vim /\\<<c-r>=expand(\'<cword>\')<CR>\\>\\C/j %<CR>:botright copen<CR>', { noremap = true })

-- LSP keymaps
vim.keymap.set('n', '<leader>d', vim.diagnostic.open_float, { noremap = true, silent = true, desc = 'Show diagnostics' })
vim.keymap.set('n', '<leader>r', vim.lsp.buf.references, { noremap = true, silent = true })
vim.keymap.set('n', '<Leader>ca', vim.lsp.buf.code_action, { noremap = true, silent = true })

-- Switch source/header function
local function switch_source_header()
    local bufnr = 0
    local uri = vim.uri_from_bufnr(bufnr)
    local params = { uri = uri }
    vim.lsp.buf_request(bufnr, "textDocument/switchSourceHeader", params, function(err, result)
        if err then
            print("Error switching file: " .. err.message)
            return
        end
        if result then
            local target_uri = result
            local target_path = vim.uri_to_fname(target_uri)
            vim.cmd("edit " .. target_path)
        else
            print("No corresponding file found")
        end
    end)
end

vim.keymap.set('n', '<Leader>a', switch_source_header, { noremap = true, silent = true })
vim.keymap.set('n', '<leader>lc', ':EditLinkedCppFile<CR>', { noremap = true, silent = true })

-- Show resolved path keymap
vim.keymap.set('n', '<leader>rp', function()
  local resolved = vim.fn.fnamemodify(vim.fn.resolve(vim.fn.expand('%:p')), ':~:.')
  print(resolved)
end, { noremap = true })

-- Autocmd for quickfix
vim.api.nvim_create_autocmd("BufReadPost", {
  pattern = "quickfix",
  callback = function()
    vim.keymap.set('n', '<CR>', '<CR>', { buffer = true })
  end
})

vim.opt.guicursor = {
  "n-v-c:block",                           -- normal, visual, command: steady block
  "i-ci-ve:ver25-blinkon500-blinkoff500",  -- insert modes: blinking vertical bar
  "r-cr:hor20",                            -- replace: steady horizontal
  "o:hor50"                                -- operator-pending: steady horizontal
}

-- Enable manual folding using Treesitter
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldenable = true
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99

vim.opt_local.spelllang = { "en_us" }
-- Optional: Keymaps for spell checking
vim.keymap.set('n', '<leader>ss', ':setlocal spell!<CR>', { desc = 'Toggle spell checking' })
--vim.keymap.set('n', '<leader>sn', ']s', { desc = 'Next misspelled word' })
--vim.keymap.set('n', '<leader>sp', '[s', { desc = 'Previous misspelled word' })
--vim.keymap.set('n', '<leader>sa', 'zg', { desc = 'Add word to dictionary' })
--vim.keymap.set('n', '<leader>s?', 'z=', { desc = 'Suggest corrections' })

-- Enable spell for all commit-like files.
-- Do not enable it for markdown files, because this filetype seems to be
-- enabled even when calling the documentation popup windows in C++ code with
-- shift-k.
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "gitcommit", "hgcommit", "svncommit" },
  callback = function()
    vim.opt_local.spell = true
    vim.opt_local.textwidth = 72  -- Also helpful for commits
  end,
})

-- ============================================================================
-- Neovim 0.12+ configuration using the built-in `vim.pack` plugin manager
-- ============================================================================
--
-- INSTALLATION
-- ------------
-- Built from source (because of glibc issues with prebuilt binaries):
--
--   $ git clone https://github.com/neovim/neovim
--   $ cd neovim
--   $ git tag -l                          # look for the latest version
--   $ git checkout v0.12.x                # any 0.12+ tag
--   $ make CMAKE_BUILD_TYPE=Release CMAKE_INSTALL_PREFIX=/data/chryssoc
--   $ make install
--
-- Plugins are installed into vim.fn.stdpath('data')/site/pack/core/opt/
-- by `vim.pack.add()` on first startup. Manage updates with:
--   :lua vim.pack.update()                -- update all plugins
--   :lua vim.pack.update({ 'name' })      -- update one plugin
--   :lua vim.pack.del({ 'name' })         -- delete a plugin
--   :checkhealth vim.pack                 -- diagnose problems
--
-- See `:h vim.pack` and `:h vim.pack-examples` for more.
-- ============================================================================

-- Speed up `require()` calls (recommended first line in init.lua).
vim.loader.enable()

-- Set Space as the leader key.
-- This MUST be placed before any plugins or keymaps are loaded.
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- ----------------------------------------------------------------------------
-- Basic options (set before plugins so they affect plugin behaviour)
-- ----------------------------------------------------------------------------
vim.opt.scrolloff      = 5
vim.opt.mouse          = 'a'
-- Sign column always visible
--vim.opt.signcolumn = "yes"
-- vim.opt.number = false
-- vim.opt.signcolumn = "yes:1"
vim.opt.number         = true
vim.opt.relativenumber = true
vim.opt.signcolumn = "number"
vim.opt.expandtab      = true
vim.opt.tabstop        = 4
vim.opt.shiftwidth     = 4
vim.opt.softtabstop    = 4
vim.opt.shiftround     = true
vim.opt.smarttab       = true
vim.opt.showcmd        = true
vim.opt.ignorecase     = true
vim.opt.smartcase      = true
vim.opt.autoread       = false
--vim.opt.hidden = false
vim.opt.completeopt:append('popup')
vim.opt.path = 'include/**,src/**,export/**,source/**,'
            .. '../include/**,../export/**,../src/**,../source/**'
-- Complete option settings <-- What do these do?
vim.opt.complete = 'o,.'
vim.o.completeopt = "menu,menuone,popup,nearest" -- noselect

--vim.o.autocomplete = true

-- vim.opt.clipboard = "unnamedplus"  <-- Too much lag!
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

-- Define diagnostic signs (place this EARLY in your config)
-- Modern diagnostic configuration (Neovim 0.10+)
vim.diagnostic.config({
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = 'E',
      [vim.diagnostic.severity.WARN]  = 'W',
      [vim.diagnostic.severity.INFO]  = 'I',
      [vim.diagnostic.severity.HINT]  = 'H',
    },
  },
  underline        = true,
  update_in_insert = false,
  severity_sort    = true,
  virtual_text     = false,
  float = { border = 'rounded', source = true },
})

-- This filetype section must be placed before vim.pack configuration.
vim.filetype.add({
  filename  = { ['TODO'] = 'text', ['DONE'] = 'text' },
  extension = { todo = 'text' },
  -- Patterns can use Lua patterns; map a whole notes dir to text (could also be markdown):
  pattern   = {
    ['.*/notes/.*%.txt']  = 'text',
    -- Common commit message patterns
    ['.*COMMIT_EDITMSG']  = 'gitcommit',
    ['hg%-editor%-.*']    = 'hgcommit',
    ['svn%-commit.*%.tmp']= 'svncommit',
    ['COMMIT_MSG']        = 'gitcommit',
  },
})

-- ----------------------------------------------------------------------------
-- Helpers used both by plugin setup and elsewhere
-- ----------------------------------------------------------------------------
local function find_project_root()
  local compile_db = vim.fs.find('compile_commands.json', { upward = true })[1]
  if compile_db then return vim.fs.dirname(compile_db) end
  local vc_dir = vim.fs.find({ '.hg', '.git' }, { upward = true })[1]
  if vc_dir then return vim.fs.dirname(vc_dir) end
  return vim.fn.getcwd()
end

local function load_private_suffixes()
  local local_config_file = vim.fn.stdpath('config') .. '/local_config.lua'
  if vim.fn.filereadable(local_config_file) == 1 then
    local ok, local_config = pcall(dofile, local_config_file)
    if ok and local_config and local_config.private_suffixes then
      return local_config.private_suffixes
    end
  end
  local env_roots = os.getenv('PROJECT_ROOTS')
  if env_roots then
    local suffixes = {}
    for suffix in string.gmatch(env_roots, '([^:]+)') do
      if not suffix:match('^/') then suffix = '/' .. suffix end
      table.insert(suffixes, suffix)
    end
    if #suffixes > 0 then return suffixes end
  end
  return {}
end

local function get_project_roots()
  local base_root = find_project_root()
  local private_suffixes = load_private_suffixes()
  if #private_suffixes == 0 then return { base_root } end
  local complete_paths = {}
  for _, suffix in ipairs(private_suffixes) do
    table.insert(complete_paths, base_root .. suffix)
  end
  return complete_paths
end

local function my_keymap()
  -- Check if keymap is active
  if vim.bo.iminsert == 1 then
    -- Try to get b:keymap_name (the "grkmac" in my own keymap).
    -- If for some reason this fails, it falls back to the filename (e.g. "greek_mac").
    return vim.b.keymap_name or vim.bo.keymap
  end
  -- If you're not using any keymap, returns the empty string (to save space).
  -- If you prefer to show something there, use something like return "EN".
  return ''
end

-- ============================================================================
-- vim.pack: install + load plugins
-- ============================================================================
--
-- IMPORTANT: any `PackChanged` autocommands used as build/post-install hooks
-- must be defined BEFORE the `vim.pack.add()` call that triggers them.
-- Otherwise Neovim cannot run them on the very first install.
-- ----------------------------------------------------------------------------

-- Build hook for telescope-fzf-native (compiles a small C library).
vim.api.nvim_create_autocmd('PackChanged', {
  desc = 'Build telescope-fzf-native after install/update',
  callback = function(ev)
    local name, kind = ev.data.spec.name, ev.data.kind
    if name == 'telescope-fzf-native.nvim'
       and (kind == 'install' or kind == 'update') then
      local plug_dir = ev.data.path
      vim.notify('Building telescope-fzf-native…', vim.log.levels.INFO)
      vim.system(
        { 'cmake', '-S', '.', '-Bbuild', '-DCMAKE_BUILD_TYPE=Release' },
        { cwd = plug_dir, text = true },
        function(out)
          if out.code ~= 0 then
            vim.schedule(function()
              vim.notify('cmake configure failed:\n' .. (out.stderr or ''),
                         vim.log.levels.ERROR)
            end)
            return
          end
          vim.system(
            { 'cmake', '--build', 'build', '--config', 'Release' },
            { cwd = plug_dir, text = true },
            function(out2)
              vim.schedule(function()
                if out2.code == 0 then
                  vim.notify('telescope-fzf-native built.', vim.log.levels.INFO)
                else
                  vim.notify('cmake build failed:\n' .. (out2.stderr or ''),
                             vim.log.levels.ERROR)
                end
              end)
            end)
        end)
    elseif name == "nvim-treesitter" and kind == "update" then
      vim.cmd("TSUpdate")
    end
  end,
})

-- Optional: keep tree-sitter parsers in sync after updates.
vim.api.nvim_create_autocmd('PackChanged', {
  desc = 'Run :TSUpdate after nvim-treesitter changes',
  callback = function(ev)
    local name, kind = ev.data.spec.name, ev.data.kind
    if name == 'nvim-treesitter' and kind == 'update' then
      if not ev.data.active then vim.cmd.packadd('nvim-treesitter') end
      pcall(vim.cmd, 'TSUpdate')
    end
  end,
})

vim.pack.add({
  -- Common dependencies first so dependants find them on rtp.
  'https://github.com/nvim-lua/plenary.nvim',
  'https://github.com/nvim-tree/nvim-web-devicons',

  -- Mason (uses canonical URLs at mason-org/*).
  'https://github.com/mason-org/mason.nvim',
  { src = 'https://github.com/neovim/nvim-lspconfig' },
  'https://github.com/mason-org/mason-lspconfig.nvim',

  -- Treesitter — using the new `main` branch (incompatible rewrite).
  -- The plugin only manages parsers/queries now; highlight, indent, folding
  -- are wired up manually below via core Neovim APIs.
  'https://github.com/nvim-treesitter/nvim-treesitter',
  'https://github.com/nvim-treesitter/nvim-treesitter-textobjects',

  -- Doxygen / docblock generation
  'https://github.com/danymat/neogen',

  -- Trouble.nvim diagnostics / symbol view
  'https://github.com/folke/trouble.nvim',

  -- Telescope (fzf-native built via PackChanged hook above)
  'https://github.com/nvim-telescope/telescope-fzf-native.nvim',
  'https://github.com/nvim-telescope/telescope.nvim',

  -- Status line
  'https://github.com/nvim-lualine/lualine.nvim',

  -- Mercurial integration, outline, table mode, zen mode
  'https://github.com/jlfwong/vim-mercenary',
  'https://github.com/stevearc/aerial.nvim',
  'https://github.com/dhruvasagar/vim-table-mode',
  'https://github.com/folke/zen-mode.nvim',
  "https://github.com/windwp/nvim-autopairs",
})

-- ============================================================================
-- Plugin setup (everything below assumes plugins are already on the rtp)
-- ============================================================================

-- ---- Mason --------------------------------------------------------------- --
require('mason').setup()

-- clangd extension: jump between source and header.
-- Uses the custom LSP request 'textDocument/switchSourceHeader'.
local function switch_source_header(bufnr)
  local client = vim.lsp.get_clients({ bufnr = bufnr, name = 'clangd' })[1]
  if not client then
    vim.notify('clangd not attached', vim.log.levels.WARN)
    return
  end
  local params = vim.lsp.util.make_text_document_params(bufnr)
  client:request('textDocument/switchSourceHeader', params, function(err, result)
    if err then
      vim.notify(tostring(err), vim.log.levels.ERROR)
      return
    end
    if not result then
      vim.notify('Corresponding file not found', vim.log.levels.INFO)
      return
    end
    vim.cmd.edit(vim.uri_to_fname(result))
  end, bufnr)
end

-- ---- LSP per-buffer features (completion, inlay hints, signature help) -- --
vim.api.nvim_create_autocmd('LspAttach', {
  group    = vim.api.nvim_create_augroup('user_lsp_features', { clear = true }),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client then return end
    local buf = args.buf
    local opts = { buffer = buf, noremap = true, silent = true }

    -- LSP-driven autocompletion (auto-trigger in '.', '->', '::')
    if client:supports_method('textDocument/completion') then
      vim.lsp.completion.enable(true, client.id, buf, { autotrigger = false })
      vim.keymap.set('i', '<C-Space>', function()
        vim.lsp.completion.get()
      end, { desc = 'Trigger completion' })
    end

    -- Inlay hints
    if client:supports_method('textDocument/inlayHint') then
      --vim.lsp.inlay_hint.enable(true, { bufnr = buf })
      vim.keymap.set("n", "<leader>ih", function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
      end, { desc = "Toggle inlay hints" })
    end

    -- Buffer-local keymaps (was before in on_attach)
    if client.name == 'clangd' then
      vim.keymap.set('n', '<leader>a', function()
        switch_source_header(buf)
      end, vim.tbl_extend('force', opts, { desc = 'Switch header/source' }))
    end
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)

    -- Manual signature help (toggle via lsp_signature)
    vim.keymap.set({ 'i', 'n' }, '<C-s>', function()
      vim.lsp.buf.signature_help({ border = 'rounded' })
    end, vim.tbl_extend('force', opts, { desc = 'Signature help' }))

    -- Hover documentation with rounded borders
    vim.keymap.set('n', 'K', function()
      vim.lsp.buf.hover({ border = 'rounded' })
    end, vim.tbl_extend('force', opts, { desc = 'Hover Documentation' }))
  end,
})

-- ---- LSP (clangd) -------------------------------------------------------- --
-- IMPORTANT: register the clangd config BEFORE calling mason-lspconfig.setup,
-- so that when mason-lspconfig auto-enables clangd via vim.lsp.enable(),
-- our settings (cmd, root_markers, capabilities, on_attach) are already in
-- place.

local caps = vim.lsp.protocol.make_client_capabilities()

vim.lsp.config('clangd', {
  cmd = {
    vim.fn.stdpath('data') .. '/mason/bin/clangd',
    '--background-index',
    '--clang-tidy',
    '--log=error',
    '--completion-style=detailed',
    '--header-insertion=iwyu',
    '--j=4',
    '--pch-storage=memory',
    '--all-scopes-completion',
    '--limit-references=0',
  },
  filetypes    = { 'c', 'cpp', 'objc', 'objcpp', 'cuda' },
  root_markers = {
    '.clangd', '.clang-tidy', '.clang-format',
    'compile_commands.json', '.git',
  },
  capabilities = caps,
})

-- mason-lspconfig v2: `handlers` and `automatic_installation` are gone.
-- We just declare what to install and let it call vim.lsp.enable() for us.
require('mason-lspconfig').setup({
  ensure_installed = { 'clangd' },
  automatic_enable = true,
})

-- ---- Treesitter (main branch — new API) ---------------------------------- --
-- The `main` branch only manages parsers and queries. Features like
-- highlighting, folding, and indentation are now opt-in core Neovim APIs that
-- we wire up below via a FileType autocommand.

local ts_parsers = { 'c', 'cpp', 'doxygen', 'json', 'python', 'bash', 'yang' }

require('nvim-treesitter').setup({
  -- Parsers and queries are installed under stdpath('data')/site/parser by
  -- default; this just makes the location explicit.
  install_dir = vim.fn.stdpath('data') .. '/site',
})

-- Install the parsers we want. install() is async; on first run we wait for
-- it so highlighting works in the very first opened buffer. On later runs
-- it's effectively a no-op for parsers already on disk.
do
  local ok, ts = pcall(require, 'nvim-treesitter')
  if ok and ts.install then
    -- :wait() blocks the UI; 5 minutes is generous for a fresh install.
    pcall(function() ts.install(ts_parsers):wait(300000) end)
  end
end

-- Build a list of *filetypes* (not parser names) for which to enable TS
-- features. Some parsers don't map 1-to-1 to filetypes (e.g. bash → sh,
-- doxygen → none — it's only used as an injection inside C/C++ comments).
local ts_filetypes = {}
do
  local seen = {}
  for _, parser in ipairs(ts_parsers) do
    local fts = vim.treesitter.language.get_filetypes(parser)
    for _, ft in ipairs(fts) do
      if not seen[ft] then
        seen[ft] = true
        table.insert(ts_filetypes, ft)
      end
    end
  end
end

-- Enable highlight + folding + indent for the filetypes whose parsers we
-- installed. We deliberately keep `:syntax on` running in parallel so that
-- regex-based highlights for TODO/FIXME/XXX in comments still work.
vim.api.nvim_create_autocmd('FileType', {
  pattern = ts_filetypes,
  callback = function() vim.treesitter.start() end,
})

-- ---- Treesitter textobjects (main branch — new API) ---------------------- --
require('nvim-treesitter-textobjects').setup({
  select = {
    -- Jump forward to text-object if cursor isn't already on one.
    lookahead = true,
  },
  move = {
    set_jumps = true, -- record positions in the jumplist
  },
})

-- Selection mappings (af/if/ac/ic).
local ts_select = require('nvim-treesitter-textobjects.select')
vim.keymap.set({ 'x', 'o' }, 'af', function() ts_select.select_textobject('@function.outer', 'textobjects') end, { desc = 'Select around function' })
vim.keymap.set({ 'x', 'o' }, 'if', function() ts_select.select_textobject('@function.inner', 'textobjects') end, { desc = 'Select inside function' })
vim.keymap.set({ 'x', 'o' }, 'ac', function() ts_select.select_textobject('@class.outer',    'textobjects') end, { desc = 'Select around class' })
vim.keymap.set({ 'x', 'o' }, 'ic', function() ts_select.select_textobject('@class.inner',    'textobjects') end, { desc = 'Select inside class' })

-- Movement mappings — same set as before. Note that `]]` and `[[` are
-- overridden later by Aerial when its outline is open; that's intentional.
local ts_move = require('nvim-treesitter-textobjects.move')
vim.keymap.set({ 'n', 'x', 'o' }, ']m', function() ts_move.goto_next_start('@function.outer', 'textobjects') end, { desc = 'Next function start' })
vim.keymap.set({ 'n', 'x', 'o' }, ']f', function() ts_move.goto_next_start('@function.inner', 'textobjects') end, { desc = 'Next function-body start' })
vim.keymap.set({ 'n', 'x', 'o' }, ']]', function() ts_move.goto_next_start('@class.outer',    'textobjects') end, { desc = 'Next class start' })
vim.keymap.set({ 'n', 'x', 'o' }, ']M', function() ts_move.goto_next_end(  '@function.outer', 'textobjects') end, { desc = 'Next function end' })
vim.keymap.set({ 'n', 'x', 'o' }, '][', function() ts_move.goto_next_end(  '@class.outer',    'textobjects') end, { desc = 'Next class end' })
vim.keymap.set({ 'n', 'x', 'o' }, '[m', function() ts_move.goto_previous_start('@function.outer', 'textobjects') end, { desc = 'Prev function start' })
vim.keymap.set({ 'n', 'x', 'o' }, '[f', function() ts_move.goto_previous_start('@function.inner', 'textobjects') end, { desc = 'Prev function-body start' })
vim.keymap.set({ 'n', 'x', 'o' }, '[[', function() ts_move.goto_previous_start('@class.outer',    'textobjects') end, { desc = 'Prev class start' })
vim.keymap.set({ 'n', 'x', 'o' }, '[M', function() ts_move.goto_previous_end(  '@function.outer', 'textobjects') end, { desc = 'Prev function end' })
vim.keymap.set({ 'n', 'x', 'o' }, '[]', function() ts_move.goto_previous_end(  '@class.outer',    'textobjects') end, { desc = 'Prev class end' })

-- ---- Neogen (docblocks) -------------------------------------------------- --
require('neogen').setup({
  enabled = true,
  languages = {
    cpp = { template = { annotation_convention = 'doxygen' } },
    c   = { template = { annotation_convention = 'doxygen' } },
  },
})
-- Optional keymaps:
vim.keymap.set('n', '<leader>ng', function() require('neogen').generate() end,
  { desc = 'Generate Doxygen docblock' })

-- ---- Trouble ------------------------------------------------------------- --
require('trouble').setup({
  win   = { size = 0.4 },
  modes = {
    symbols = {
      format = '{kind_icon} {symbol.name}: {symbol.detail:Comment} '
            .. '{text:Comment} {pos:LineNr}',
    },
  },
})
vim.keymap.set('n', '<leader>tX', '<cmd>Trouble diagnostics toggle<cr>',
  { desc = 'Diagnostics (Trouble)' })
vim.keymap.set('n', '<leader>tx',
  '<cmd>Trouble diagnostics toggle filter.buf=0<cr>',
  { desc = 'Buffer Diagnostics (Trouble)' })
vim.keymap.set('n', '<leader>ts', '<cmd>Trouble symbols toggle focus=false<cr>',
  { desc = 'Symbols (Trouble)' })
vim.keymap.set('n', '<leader>tl',
  '<cmd>Trouble lsp toggle focus=false win.position=right<cr>',
  { desc = 'LSP Definitions / references (Trouble)' })
vim.keymap.set('n', '<leader>tL', '<cmd>Trouble loclist toggle<cr>',
  { desc = 'Location List (Trouble)' })
vim.keymap.set('n', '<leader>tQ', '<cmd>Trouble qflist toggle<cr>',
  { desc = 'Quickfix List (Trouble)' })

-- ---- Telescope ----------------------------------------------------------- --
local telescope = require('telescope')
telescope.setup({
  defaults = {
    layout_strategy = 'vertical',
    layout_config = {
      vertical = {
        height          = 0.95,
        width           = 0.9,
        preview_height  = 0.6,
        prompt_position = 'bottom',
        mirror          = false,
      },
    },
    sorting_strategy = 'descending',
  },
  pickers = {
    find_files = { search_dirs = get_project_roots() },
    live_grep  = { search_dirs = get_project_roots() },
    lsp_dynamic_workspace_symbols = { fname_width = 60, symbol_width = 60 },
    lsp_document_symbols          = { fname_width = 60, symbol_width = 60 },
  },
})
-- fzf extension may not be built yet on the very first run. Don't fail.
pcall(telescope.load_extension, 'fzf')

vim.keymap.set('n', '<leader>ff', function() require('telescope.builtin').find_files() end,           { desc = 'Find Files' })
vim.keymap.set('n', '<leader>fg', function() require('telescope.builtin').live_grep() end,            { desc = 'Live Grep' })
vim.keymap.set('n', '<leader>fb', function() require('telescope.builtin').buffers() end,              { desc = 'Buffers' })
vim.keymap.set('n', '<leader>fh', function() require('telescope.builtin').help_tags() end,            { desc = 'Help Tags' })
vim.keymap.set('n', '<leader>fs', function() require('telescope.builtin').lsp_document_symbols() end, { desc = 'Document Symbols' })
vim.keymap.set('n', '<leader>fS', function() require('telescope.builtin').lsp_workspace_symbols() end,{ desc = 'Workspace Symbols' })
vim.keymap.set('n', '<leader>fd', function() require('telescope.builtin').lsp_dynamic_workspace_symbols() end, { desc = 'Dynamic Workspace Symbols' })

-- ---- Devicons ------------------------------------------------------------ --
require('nvim-web-devicons').setup({
  override = {
    zsh = { icon = '', color = '#428850', cterm_color = '65', name = 'Zsh' },
  },
  color_icons = true,
  default     = true,
  strict      = true,
  variant     = 'light|dark',
  override_by_filename = {
    ['.gitignore'] = { icon = '', color = '#f1502f', name = 'Gitignore' },
  },
  override_by_extension = {
    log = { icon = '', color = '#81e043', name = 'Log' },
  },
})

-- ---- Lualine ------------------------------------------------------------- --
local function get_filename_with_symlink()
  local filename = vim.fn.expand('%:.')
  if filename == '' then return '[No Name]' end
  local full_path     = vim.fn.expand('%:p')
  local resolved_path = vim.fn.resolve(full_path)
  local display_name
  if full_path ~= resolved_path then
    display_name = vim.fn.fnamemodify(resolved_path, ':.') .. ' 🔗'
  else
    display_name = filename
  end
  if vim.bo.modified then display_name = display_name .. ' [+]' end
  return display_name
end

require('lualine').setup({
  options = {
    theme               = 'onedark',
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
    component_separators = { left = '', right = '' },
    section_separators   = { left = '', right = '' },
  },
  sections = {
    lualine_a = {},
    lualine_b = { 'branch', 'diff', 'diagnostics' },
    lualine_c = { get_filename_with_symlink },
    --lualine_x = { "aerial" },
    lualine_x = { my_keymap },
    lualine_y = { 'filetype', 'fileformat', 'encoding' },
    lualine_z = { 'progress', 'location' },
  },
})

-- ---- Aerial outline ------------------------------------------------------ --
require('aerial').setup({
  backends       = { 'lsp', 'treesitter', 'markdown', 'man', 'asciidoc' },
  -- If some filetypes behave better with a different source, override here.
  backends_by_ft = {
    -- Example: if Go methods look flat with gopls, try Tree-sitter first.
    go  = { 'treesitter', 'lsp' },
    cpp = { 'lsp', 'treesitter' },
    c   = { 'lsp', 'treesitter' },
  },
  layout = {
    max_width         = 60,
    min_width         = 28,
    default_direction = 'prefer_right',
    placement         = 'window',
    resize_to_content = true,
  },
  -- Enable proper hierarchy display
  show_guides   = true,
  manage_folds  = true,
  -- Configure symbol filtering for class hierarchy
  filter_kind = {
    'Class', 'Constructor', 'Destructor', 'Enum', 'Function',
    'Interface', 'Method', 'Module', 'Namespace', 'Struct', 'Variable',
  },
  -- LSP configuration
  lsp = {
    diagnostics_trigger_update = false,
    update_when_errors         = true,
    update_delay               = 300,
  },
  -- Visual improvements for hierarchy
  guides = {
    mid_item   = '├─',
    last_item  = '└─',
    nested_top = '│ ',
    whitespace = '  ',
  },
})
vim.keymap.set('n', '<leader>o',  '<cmd>AerialToggle!<CR>', { desc = 'Toggle Outline' })
vim.keymap.set('n', '<leader>oo', '<cmd>AerialOpen<CR>',    { desc = 'Open Outline' })
vim.keymap.set('n', '<leader>oc', '<cmd>AerialClose<CR>',   { desc = 'Close Outline' })
vim.keymap.set('n', '<leader>on', '<cmd>AerialNext<CR>',    { desc = 'Next Symbol' })
vim.keymap.set('n', '<leader>op', '<cmd>AerialPrev<CR>',    { desc = 'Prev Symbol' })
vim.keymap.set('n', '[[',         '<cmd>AerialPrevUp<CR>',  { desc = 'Prev Symbol Up' })
vim.keymap.set('n', ']]',         '<cmd>AerialNextUp<CR>',  { desc = 'Next Symbol Up' })

-- ---- Table Mode ---------------------------------------------------------- --
vim.g.table_mode_corner          = '|'
vim.g.table_mode_border          = 0
vim.g.table_mode_fillchar        = ' '
vim.g.table_mode_header_fillchar = '-'
vim.keymap.set('n', '<leader>Tm',  '<cmd>TableModeToggle<cr>',       { desc = 'Toggle Table Mode' })
vim.keymap.set('n', '<leader>Tr',  '<cmd>TableModeRealign<cr>',      { desc = 'Realign Table' })
vim.keymap.set('n', '<leader>Tdd', '<cmd>TableModeDeleteRow<cr>',    { desc = 'Delete Row' })
vim.keymap.set('n', '<leader>Tdc', '<cmd>TableModeDeleteColumn<cr>', { desc = 'Delete Column' })

-- ---- Zen Mode ------------------------------------------------------------ --
require('zen-mode').setup({
  -- your configuration comes here
  -- or leave it empty to use the default settings
  -- refer to the configuration section below
})

-- ---- nvim-autopairs ------------------------------------------------------ --
require("nvim-autopairs").setup({
  check_ts = true,
  ts_config = {
    cpp = { "string", "comment" },  -- no pairing inside strings/comments
    c   = { "string", "comment" },
  },
})

--vim.cmd('colorscheme habamax')

-- ============================================================================
-- Custom commands and keymaps
-- ============================================================================

-- Vimscript helpers (kept verbatim; can be ported to Lua later).
vim.cmd([[
function! ToggleColorColumn()
    if &colorcolumn != ''
        set colorcolumn=
    else
        let &colorcolumn = g:columnlimit
    endif
endfunction

function! FindFiles(filename)
    let error_file = tempname()
    silent execute '!find . -name "'.a:filename.'" | xargs file | sed "s/:/:1:/" > '.error_file
    set errorformat=%f:%l:%m
    execute 'cfile '.error_file
    copen
    call delete(error_file)
endfunction
command! -nargs=1 FindFile call FindFiles(<q-args>)

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
  local original_filename  = vim.fn.expand('%:p')
  local extension          = vim.fn.fnamemodify(original_filename, ':e')
  local resolved_filename  = vim.fn.resolve(original_filename)
  local resolved_dir       = vim.fn.fnamemodify(resolved_filename, ':h')
  local bname              = vim.fn.fnamemodify(resolved_filename, ':t')
  local bname_wo_ext       = vim.fn.fnamemodify(bname, ':r')
  local file               = resolved_dir .. '/' .. bname_wo_ext .. '.' .. extension
  if file and file ~= '' then
    local buf = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_delete(buf, { force = false })
    vim.cmd('edit ' .. vim.fn.fnameescape(file))
  else
    print('No file path returned')
  end
end, {})

vim.api.nvim_create_user_command('Ls', function()
  local bufs = vim.api.nvim_list_bufs()
  local lines = {}
  for _, buf in ipairs(bufs) do
    if vim.bo[buf].buflisted then
      local name = vim.api.nvim_buf_get_name(buf)
      if name == '' then
        table.insert(lines, string.format('%d: [No Name]', buf))
      else
        local ok, resolved = pcall(function()
          return vim.fn.fnamemodify(vim.fn.resolve(name), ':~:.')
        end)
        table.insert(lines, string.format('%d: %s', buf, ok and resolved or name))
      end
    end
  end
  print(table.concat(lines, '\n'))
end, {})

vim.api.nvim_create_user_command('LspStop', function()
  for _, client in ipairs(vim.lsp.get_clients()) do
    client:stop()
  end
end, { desc = 'Stop all LSP clients' })

vim.api.nvim_create_user_command('LspRestart', function()
  for _, client in ipairs(vim.lsp.get_clients()) do
    client:stop()
  end
  vim.defer_fn(function()
    vim.cmd('edit')
  end, 100)
end, { desc = 'Stop all LSP clients and reattach' })

vim.api.nvim_create_user_command('LspDiag', function(opts)
  local args = vim.split(opts.args, '%s+')
  local use_loclist, all_buffers, severity_filter = false, false, nil
  for _, arg in ipairs(args) do
    if     arg == 'loc' or arg == 'loclist' then use_loclist = true
    elseif arg == 'all'   then all_buffers = true
    elseif arg == 'error' then severity_filter = vim.diagnostic.severity.ERROR
    elseif arg == 'warn'  then severity_filter = { min = vim.diagnostic.severity.WARN }
    end
  end
  if use_loclist then
    local config = { open = true }
    if severity_filter then config.severity = severity_filter end
    if not all_buffers then config.bufnr = 0 end
    vim.diagnostic.setloclist(config)
  else
    local bufnr        = all_buffers and nil or 0
    local diagnostics  = vim.diagnostic.get(bufnr, { severity = severity_filter })
    local qf_items     = vim.diagnostic.toqflist(diagnostics)
    vim.fn.setqflist(qf_items, 'r')
    vim.cmd('copen')
  end
end, {
  nargs = '*',
  complete = function() return { 'loclist', 'loc', 'all', 'error', 'warn' } end,
  desc = 'Show LSP diagnostics in quickfix (default) or location list',
})

-- ---- Top-level keymaps --------------------------------------------------- --
-- Toggle search highlighting
vim.keymap.set('n', '<F3>', '<cmd>set hls!<CR>', { silent = true, desc = 'Toggle search highlight' })

-- Toggle spell checking
vim.keymap.set('n', '<F5>', '<cmd>set spell!<CR>', { silent = true, desc = 'Toggle spell check' })

-- Search using quickfix list
-- Search in the directory of the file currently opened in the buffer
vim.keymap.set('n', '<leader>gf', function()
  local word = vim.fn.expand('<cword>')
  local dir  = vim.fn.expand('%:p:h')

  -- Escape the directory path to handle spaces or special characters safely
  vim.cmd('grep! "\\b' .. word .. '\\b" ' .. vim.fn.fnameescape(dir))
  vim.cmd('botright copen')
end, { silent = true, desc = 'Grep word in current file dir' })

-- Search in the parent directory of the file currently opened in the buffer
vim.keymap.set('n', '<leader>gp', function()
  local word = vim.fn.expand('<cword>')
  local dir  = vim.fn.expand('%:p:h:h')

  vim.cmd('grep! "\\b' .. word .. '\\b" ' .. vim.fn.fnameescape(dir))
  vim.cmd('botright copen')
end, { silent = true, desc = 'Grep word in parent dir' })

-- Search in the current working directory of Neovim
vim.keymap.set('n', '<leader>g.', function()
  local word = vim.fn.expand('<cword>')
  local dir  = vim.fn.getcwd()

  vim.cmd('grep! "\\b' .. word .. '\\b" ' .. vim.fn.fnameescape(dir))
  vim.cmd('copen')
end, { silent = true, desc = 'Grep word in Neovim cwd' })

--vim.keymap.set('n', '<leader>o', ':vim /\\<<c-r>=expand(\'<cword>\')<CR>\\>/j %<CR>:botright copen<CR>', { noremap = true })
--vim.keymap.set('n', '<leader>O', ':vim /\\<<c-r>=expand(\'<cword>\')<CR>\\>\\C/j %<CR>:botright copen<CR>', { noremap = true })

-- LSP keymaps
vim.keymap.set('n', '<leader>d',  vim.diagnostic.open_float, { silent = true, desc = 'Show diagnostics' })
vim.keymap.set('n', '<leader>r',  vim.lsp.buf.references, { silent = true, desc = 'Show references'})
vim.keymap.set('n', '<Leader>ca', vim.lsp.buf.code_action, { silent = true, desc = 'Show code actions' })

vim.keymap.set('n', '<leader>lc', '<cmd>EditLinkedCppFile<CR>', { silent = true })
-- Print the file path relative to the current working directory
vim.keymap.set('n', '<leader>rp', function()
  print(vim.fn.fnamemodify(vim.fn.resolve(vim.fn.expand('%:p')), ':~:.'))
end, { desc = 'Print relative path' })

-- Quickfix Enter mapping (used to be quirky; keep an explicit map).
vim.api.nvim_create_autocmd('BufReadPost', {
  pattern = 'quickfix',
  callback = function()
    vim.keymap.set('n', '<CR>', '<CR>', { buffer = true })
  end,
})

-- ---- Cursor / folds ------------------------------------------------------ --
-- This seem to make the editor sluggish...
--vim.opt.guicursor = {
--  'n-v-c:block',
--  'i-ci-ve:ver25-blinkon500-blinkoff500',
--  'r-cr:hor20',
--  'o:hor50',
--}
-- Enable manual folding using Treesitter.
-- NOTE: foldmethod and foldexpr are now set per-buffer in the TS FileType
-- autocmd above. We keep folds open by default everywhere.
vim.opt.foldenable     = true
vim.opt.foldlevel      = 99
vim.opt.foldlevelstart = 99

-- ---- Spelling ------------------------------------------------------------ --
vim.opt.spelllang     = { 'en_us', 'el' }
vim.opt.spelloptions  = 'camel'  -- Check camelCase words

-- Optional: Keymaps for spell checking
vim.keymap.set('n', '<leader>s', ':setlocal spell!<CR>', { desc = 'Toggle spell checking' })
--vim.keymap.set('n', '<leader>sn', ']s', { desc = 'Next misspelled word' })
--vim.keymap.set('n', '<leader>sp', '[s', { desc = 'Previous misspelled word' })
--vim.keymap.set('n', '<leader>sa', 'zg', { desc = 'Add word to dictionary' })
--vim.keymap.set('n', '<leader>s?', 'z=', { desc = 'Suggest corrections' })

-- Enable spell for all commit-like files.
-- Do not enable it for markdown files, because this filetype seems to be
-- enabled even when calling the documentation popup windows in C++ code with
-- shift-k.
vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'gitcommit', 'hgcommit', 'svncommit' },
  callback = function()
    vim.opt_local.spell    = true
    vim.opt_local.textwidth = 72  -- Also helpful for commits
  end,
})

-- ---- Scratch buffer ------------------------------------------------------ --
local scratch_buf = nil
vim.keymap.set('n', '<leader>x', function()
  if scratch_buf and vim.api.nvim_buf_is_valid(scratch_buf) then
    -- Switch to existing scratch buffer
    vim.api.nvim_set_current_buf(scratch_buf)
  else
    -- Create new scratch buffer
    vim.cmd('enew')
    vim.bo.buftype   = 'nofile'
    vim.bo.bufhidden = 'hide'
    vim.bo.swapfile  = false
    scratch_buf      = vim.api.nvim_get_current_buf()
  end
end, { desc = 'Toggle scratch buffer' })

-- Evaluate visual selection
vim.keymap.set('v', '<leader>=', 'c<C-r>=<C-r>"<CR><Esc>',
  { desc = 'Calculate expression' })

-- ---- Document symbols → quickfix ----------------------------------------- --
-- Add a keybinding to show current function
local function show_document_symbols_with_current()
  -- Get current position
  local current_line = vim.fn.line('.')
  local clients      = vim.lsp.get_clients({ bufnr = 0 })
  if #clients == 0 then
    vim.notify('No LSP client attached', vim.log.levels.WARN)
    return
  end
  -- Get client and its encoding
  local client = clients[1]
  local params = vim.lsp.util.make_position_params(0, client.offset_encoding)

  vim.lsp.buf_request(0, 'textDocument/documentSymbol', params,
    function(err, result, _, _)
      if err or not result or vim.tbl_isempty(result) then
        vim.notify('No symbols found', vim.log.levels.WARN)
        return
      end

      -- Flatten symbols into a list with their ranges
      local items, current_symbol_idx = {}, nil

      local function flatten_symbols(symbols, prefix)
        prefix = prefix or ''
        for _, symbol in ipairs(symbols) do
          local range      = symbol.range or symbol.location.range
          local start_line = range.start.line + 1  -- LSP is 0-indexed
          local end_line   = range['end'].line + 1
          local name       = prefix .. symbol.name
          table.insert(items, {
            lnum       = start_line,
            col        = range.start.character + 1,
            text       = name,
            start_line = start_line,
            end_line   = end_line,
            start_char = range.start.character,
            end_char   = range['end'].character,
          })
          -- Check if cursor is in this symbol
          if current_line >= start_line and current_line <= end_line then
            if not current_symbol_idx
               or items[current_symbol_idx].start_line < start_line then
              current_symbol_idx = #items
            end
          end
          -- Process children with indentation
          if symbol.children then
            flatten_symbols(symbol.children, name .. '::')
          end
        end
      end

      flatten_symbols(result)

      -- Set location list
      --vim.fn.setloclist(0, {}, ' ', {
      -- Set quickfix list
      vim.fn.setqflist({}, ' ', { title = 'Document Symbols', items = items })

      -- Open location list
      -- vim.cmd('lopen')
      -- Open quickfix list (changed from lopen)
      vim.cmd('copen')

      -- Jump to current symbol if found
      --if current_symbol_idx then
      --  vim.cmd('ll ' .. current_symbol_idx)
      --end
      -- Jump to current symbol if found (changed from ll to cc)
      if current_symbol_idx then vim.cmd('cc ' .. current_symbol_idx) end
    end)
end
vim.keymap.set('n', '<leader>cf', show_document_symbols_with_current,
  { desc = 'Show symbols (highlight current)' })

-- "Where am I?" — print the qualified symbol name at cursor.
local function show_current_function()
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if #clients == 0 then
    print('No LSP client attached')
    return
  end
  local client = clients[1]
  local params = vim.lsp.util.make_position_params(0, client.offset_encoding)

  vim.lsp.buf_request(0, 'textDocument/documentSymbol', params,
    function(err, result, _, _)
      if err or not result or vim.tbl_isempty(result) then
        print('No symbol information available')
        return
      end

      local function find_symbol_at_pos(symbols, line, col)
        for _, symbol in ipairs(symbols) do
          local range      = symbol.range or symbol.location.range
          local start_line = range.start.line
          local end_line   = range['end'].line
          local start_char = range.start.character
          local end_char   = range['end'].character
          -- Check if position is within this symbol
          if line >= start_line and line <= end_line then
            if line == start_line and col < start_char then goto continue end
            if line == end_line   and col > end_char   then goto continue end
            -- Check children first (more specific)
            if symbol.children then
              local child_result = find_symbol_at_pos(symbol.children, line, col)
              if child_result then
                return symbol.name .. '::' .. child_result
              end
            end
            return symbol.name
          end
          ::continue::
        end
        return nil
      end

      local line     = params.position.line
      local col      = params.position.character
      local location = find_symbol_at_pos(result, line, col)
      if location then print('📍 ' .. location)
      else print('Not inside any function') end
    end)
end
vim.keymap.set('n', '<leader>pf', show_current_function,
  { desc = 'Where am I?' })

-- ---- Cursorline / quickfix toggle ---------------------------------------- --
-- Make cursorline color a bit more visible
vim.api.nvim_set_hl(0, 'CursorLine', { bg = '#3a3a3a', bold = true })

local function toggle_quickfix()
  local qf_exists = false
  for _, win in pairs(vim.fn.getwininfo()) do
    if win.quickfix == 1 then qf_exists = true; break end
  end
  if qf_exists then vim.cmd('cclose')
  else              vim.cmd('botright copen') end
end
vim.keymap.set('n', '<F4>', toggle_quickfix,
  { silent = true, desc = 'Toggle quickfix' })

-- ---- Greek input method (vim's own keymap) ------------------------------- --
-- 2. Set my own input method to use
vim.opt.keymap   = 'greek_mac'
-- Begin with the default input method and switch to my own with Ctrl-^ (i.e. Ctrl-6)
vim.opt.iminsert = 0
vim.opt.imsearch = -1

-- <C-^> does the language switching and <Cmd>... does the UI refresh in the background
-- without switching mode!
vim.keymap.set({ 'i', 'c' }, '<C-\\>',
  '<C-^><Cmd>lua require("lualine").refresh()<CR>',
  { noremap = true, silent = true, desc = 'Toggle Keymap & Refresh Lualine' })

-- Tab to go to next option
vim.keymap.set('i', '<Tab>', function()
  if vim.fn.pumvisible() == 1 then
    return '<C-n>'
  end
  return '<Tab>'
end, { expr = true, desc = 'Next completion item' })

-- Shift+Tab to go to previous option
vim.keymap.set('i', '<S-Tab>', function()
  if vim.fn.pumvisible() == 1 then
    return '<C-p>'
  end
  return '<S-Tab>'
end, { expr = true, desc = 'Prev completion item' })

-- Enter to accept selection (This is bad!)
--vim.keymap.set('i', '<CR>', function()
--  if vim.fn.pumvisible() == 1 then
--    return '<C-y>'
--  end
--  return '<CR>'
--end, { expr = true, desc = 'Accept completion' })

-- Save the current buffer (only if it has been modified)
vim.keymap.set('n', '<leader>w', '<cmd>update<CR>', { desc = 'Save buffer' })

vim.keymap.set({ 'i', 's' }, '<Tab>', function()
  if vim.snippet.active({ direction = 1 }) then
    return '<Cmd>lua vim.snippet.jump(1)<CR>'
  end
  return '<Tab>'
end, { expr = true, desc = 'Snippet forward or Tab' })

vim.keymap.set({ 'i', 's' }, '<S-Tab>', function()
  if vim.snippet.active({ direction = -1 }) then
    return '<Cmd>lua vim.snippet.jump(-1)<CR>'
  end
  return '<S-Tab>'
end, { expr = true, desc = 'Snippet backward or Shift-Tab' })

vim.api.nvim_create_user_command('BuildIndex', function()
  vim.notify('Building compile DB...', vim.log.levels.INFO)
  local t0 = vim.uv.hrtime()

  vim.system(
    { 'build_index' },                    -- or full path if not on Neovim's $PATH
    { text = true },
    function(out)
      vim.schedule(function()
        local dt = (vim.uv.hrtime() - t0) / 1e9
        if out.code ~= 0 then
          vim.notify(
            ('build_index failed (%.1fs):\n%s'):format(dt, out.stderr or ''),
            vim.log.levels.ERROR
          )
          return
        end

        -- Restart only the clangd clients
        local clients = vim.lsp.get_clients({ name = 'clangd' })
        for _, c in ipairs(clients) do
          vim.lsp.stop_client(c.id, true)
        end

        -- Small delay so the server shuts down gracefully,
        -- then :edit to re-attach LSP to the current buffer.
        vim.defer_fn(function()
          local view = vim.fn.winsaveview()
          vim.cmd('edit')
          vim.fn.winrestview(view)
          vim.notify(
            ('build_index done (%.1fs), clangd restarted'):format(dt),
            vim.log.levels.INFO
          )
        end, 200)
      end)
    end
  )
end, { desc = 'Refresh compile_commands.json and restart clangd' })

vim.keymap.set('n', '<leader>bi', '<cmd>BuildIndex<CR>',
  { desc = 'Build compile DB index' })


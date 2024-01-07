M = {}

local default_opts = {
  paths = {
    -- The names are unimportant, only the paths matter.
    -- Any path in here will hide exports, .gitconfig personals, $env: vars, etc
    venv = '*/venv/*',
    virtualenv = '*/virtualenv/*',
    dotenv = '*/.env',
    config = '*/.config/*',
    aliases = '*/.bash_aliases',
    dotfiles = '*/dotfiles/*',
    powershell = '*.ps1',
    gitconfig = '*/.gitconfig',
    configini = '*.ini',
    secretsyaml = '*.yaml',
    ssh = '*/.ssh/*',
  },
  keywords = {
    'api_key',
    'token',
    'client_secret',
    'powershell',
    '$env:',
    'export',
    'alias',
    'name',
    'userpassword',
    'username',
    'user.name',
    'user.password',
    'user.email',
    'email',
    'signingkey',
    'IdentityFile',
    'server',
    'host',
    'port',
    'credential.helper',
  },

  level = 'secure', -- | 'edit' | 'soft'
  default_state = 'off', -- Whether or not streamer mode turns on when nvim is launched.
  exclude = { '' }, -- Any of the named defaults can go here, as strings. e.g., 'bash_aliases'
  conceal_char = '*',
  patterns = {},
}

M._BaseKeywordConcealPattern = [[^\(\s*\)\?\c\(\%%['"]%s\%%['"]\%%(\s\{-}\)\?\)\zs.*$]]
for _, keyword in ipairs(default_opts.keywords) do
  default_opts.patterns[#default_opts.patterns + 1] = M._BaseKeywordConcealPattern:format(keyword)
end

M.opts = {}

M.file_conceal_augroup = vim.api.nvim_create_augroup('StreamerModeFileConceal', { clear = true })
M.conceal_augroup = vim.api.nvim_create_augroup('StreamerMode', { clear = true })
M._matches = {}
M.cursor_levels = {
  secure = 'ivnc',
  edit = 'vn',
  soft = '',
}

--- Setup function for the user. Configures default behavior.
--- Usage: >
---	  require('streamer-mode').setup({
---      -- Use all the default paths
---      preset = true,
---      -- Add more paths
---      paths = { project_dir = '~/projects/*' },
---      -- Set Streamer Mode to be active when nvim is launched
---	     default_mode = 'on',
---      -- Set Streamer Mode behavior. :h sm.level
---	     level = 'edit',
---      -- A listlike table of default paths to exlude
---	     exclude = { 'powershell' }
---	     keywords = { 'export', 'alias', 'api_key' }
---	   })
---
--- Parameters: ~
---   • {opts}  Table of named paths
---     • keywords: table = { 'keywords', 'to', 'conceal' }
---     • paths: table = { any_name = '*/path/*' }
---     • level: string = 'secure' -- or: 'soft', 'edit'
---     • exclude: table = { 'default', 'path', 'names' }
---     • conceal_char: string = '*' -- default
---     • default_state: string = 'on' -- or 'off'
---     • levels:
---        • `'secure'` will prevent the concealed text from becoming
---          visible at all.
---          This will also conceal any keywords while typing
---          them (like sudo password input).
---
---        • `'edit'` will allow the concealed text to become visible
---          only when the cursor goes into insert mode on the same line.
---
---        • `'soft'` will allow the concealed text to become visible
---          when the cursor is on the same line in any mode.
---
--- :h streamer-mode.setup
---@param opts? table
---keywords: list[string],
---paths: table,
---exclude: list[string],
---default_mode: string,
---conceal_char: string,
---level: string
function M.setup(user_opts)
  M.default_conceallevel = vim.o.conceallevel
  user_opts = user_opts or {}
  local opts = vim.tbl_deep_extend('force', default_opts, user_opts)
  M.opts = opts

  if opts.paths then
    for name, path in pairs(opts.paths) do
      M.opts.paths[name] = vim.fs.normalize(path, { expand_env = true })
    end
  end

  -- Remove any unwanted paths
  if opts.exclude then
    for _, name in ipairs(opts.exclude) do
      M.opts.paths[name] = nil
    end
  end

  -- Add custom keywords
  if opts.keywords then
    M:generate_patterns(opts.keywords)
  else
    M:generate_patterns(M.opts.keywords)
  end

  -- set conceal character
  vim.o.concealcursor = M.cursor_levels[M.opts.level]
  vim.o.conceallevel = 1
  M.autocmds = vim.api.nvim_get_autocmds({ group = M._conceal_augroup })
  M.opts.default_state = opts.default_state or M.opts.default_state
  if M.opts.default_state == 'on' then
    M:start_streamer_mode()
  else
    vim.o.conceallevel = M.default_conceallevel
  end
end

-- Not yet fully tested. Use setup() instead.
-- Add a single path (or file/type) to Streamer Mode.
-- setup({ paths = { name = '*/path/*' } }) is preferred.
-- example:
--	   add_path('bashrc', '*/.bashrc')
---@param name string
---@param path string
function M:add_path(name, path)
  if path:match('~') then
    path = path:gsub('~', vim.fn.expand('~')) -- Essentially normalize while keeping globs
  end
  self.opts.paths[name] = path
end

---Takes in a table in the format of { keyword = true }
---Any keyword that is assigned a value of `true` will be added to
---the conceal patterns.
---@param keywords table list
function M:generate_patterns(keywords)
  for _, word in ipairs(keywords) do
    -- Check for regex special characters
    -- if word:find('%*|%[|%]') then
    -- Replace special characters with their escaped equivalents
    -- word = word:find('%*') and word:gsub([[%*]], [[\*]]) or word
    -- word = word:find('%[') and word:gsub('%[', [[\[]]) or word
    -- word = word:find('%]') and word:gsub('%]', [=[\]]=]) or word
    -- end
    M.opts.patterns[#M.opts.patterns + 1] = M._BaseKeywordConcealPattern:format(word)
  end
end

---Callback for autocmds.
function M:add_match_conceals()
  for _, pattern in ipairs(M.opts.patterns) do
    table.insert(self._matches, vim.fn.matchadd('Conceal', pattern, 9999, -1, { conceal = self.opts.conceal_char }))
  end
end

---Activates Streamer Mode
function M:add_conceals()
  vim.fn.clearmatches()
  self._matches = {}
  self:add_match_conceals()
  self:setup_env_conceals()
  self:add_ssh_key_conceals()
  self:start_ssh_conceals()
  vim.o.conceallevel = 1
  self.enabled = true
end

---Turns off Streamer Mode (Removes Conceal commands)
function M:remove_conceals()
  vim.api.nvim_clear_autocmds({ group = self.conceal_augroup })
  vim.fn.clearmatches()
  self._matches = {}
  vim.o.conceallevel = self.default_conceallevel
  self.enabled = false
end

---Sets up conceals for environment variables
function M:setup_env_conceals()
  for _, path in pairs(self.opts.paths) do
    vim.api.nvim_create_autocmd({ 'BufEnter' }, {
      pattern = path,
      callback = function()
        self:add_match_conceals()
      end,
      group = self._conceal_augroup,
    })
  end
end

---Starts Streamer Mode. Alias for `add_conceals()`
function M:start_streamer_mode()
  self:add_conceals()
end

---Stops Streamer Mode. Alias for `remove_conceals()`
function M:stop_streamer_mode()
  self:remove_conceals()
end

function M:toggle_streamer_mode()
  if self.enabled then
    self:stop_streamer_mode()
  else
    self:start_streamer_mode()
  end
end

M.ssh_conceal_pattern =
  [[^-\{1,}BEGIN OPENSSH PRIVATE KEY-\{-1,}\n\zs\(\_.\{-}\)\ze-\{1,}END OPENSSH PRIVATE KEY-\{-1,}\n\?]]
function M:start_ssh_conceals()
  table.insert(
    self._matches,
    vim.fn.matchadd('Conceal', self.ssh_conceal_pattern, 9999, -1, { conceal = self.opts.conceal_char })
  )
end

function M:add_ssh_key_conceals()
  vim.api.nvim_create_autocmd({ 'BufEnter' }, {
    pattern = '*/.ssh/id_*',
    callback = function()
      -- Check that the filename doesn't end with .pub
      if vim.fn.expand('%:e') ~= 'pub' then
        self:start_ssh_conceals()
      end
    end,
    group = self.file_conceal_augroup,
  })
end

return M

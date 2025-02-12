M = {}

local default_opts = {
    paths = {
        '*',
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
    conceal_char = '*',
    patterns = {},
}

M._BaseKeywordConcealPattern = [[^\(\s*\)\?\c\(\%%['"]%s\%%['"]\%%(\s\{-}\)\?\)\zs.*$]]
for _, keyword in ipairs(default_opts.keywords) do
    default_opts.patterns[#default_opts.patterns + 1] = M._BaseKeywordConcealPattern:format(keyword)
end

M.opts = {
    level = 'secure',
    default_state = 'off',
    conceal_char = '*',
    paths = {},
    patterns = {},
    keywords = {},
}

M.conceal_augroup = vim.api.nvim_create_augroup('StreamerMode', { clear = true })
M._matches = {}
M.cursor_levels = {
    secure = 'ivnc',
    edit = 'vn',
    soft = '',
}

M.exclude = {

    keywords = {
        ['api_key'] = false,
        ['token'] = false,
        ['client_secret'] = false,
        ['powershell'] = false,
        ['$env:'] = false,
        ['export'] = false,
        ['alias'] = false,
        ['name'] = false,
        ['userpassword'] = false,
        ['username'] = false,
        ['user.name'] = false,
        ['user.password'] = false,
        ['user.email'] = false,
        ['email'] = false,
        ['signingkey'] = false,
        ['IdentityFile'] = false,
        ['server'] = false,
        ['host'] = false,
        ['port'] = false,
        ['credential.helper'] = false,
    }
}


--- Setup function for the user. Configures default behavior.
--- Usage: >lua
---	  require('streamer-mode').setup({
---	     preset = true, -- DEPRECATED - Use `use_defaults`
---	     use_defaults = true -- | false
---      -- Use custom paths
---      paths = { '~/projects/*' },
---      -- Set Streamer Mode to be active when nvim is launched
---	     default_mode = 'on',
---      -- Set Streamer Mode behavior. :h sm.level
---	     level = 'edit',
---      -- A listlike table of default paths to exlude
---	     keywords = { 'export', 'alias', 'api_key' }
---	   })
---
--- Parameters: ~
---   • {opts} Optional Table of named paths
---     • use_defaults: boolean = true | false
---     • keywords: table = { 'keywords', 'to', 'conceal' }
---     • paths: table = { '*/paths/*', '*to_use/*' }
---     • level: string = 'secure' -- | 'soft' | 'edit'
---     • conceal_char: string = '*' -- default
---     • default_state: string = 'on' -- | 'off'
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
---@param user_opts? table
---keywords: list[string],
---paths: list[string],
---default_mode: string,
---conceal_char: string,
---level: string,
---exclude_all_default_paths: bool,
---exclude_all_default_keywords: bool,
---exclude_default_paths: table{string},
---exclude_default_keywords: table{string},
function M:configure_options(user_opts)
    if not user_opts then
        self:start_with_defaults()
        return
    end
    user_opts = user_opts or {}
    self.opts.default_state = user_opts.default_state or 'off'
    self.opts.level = user_opts.level or 'secure'

    if not user_opts.exclude_all_default_keywords then
        if user_opts.exclude_default_keywords then
            for _, v in ipairs(user_opts.exclude_default_keywords) do
                self.exclude.keywords[v] = true
            end
        end
        if user_opts.keywords then
            for i = 1, #default_opts.keywords do
                if not self.exclude.keywords[default_opts[i]] then
                    self.opts.keywords[#self.opts.keywords + 1] = default_opts.keywords[i]
                end
            end
        end
    else
        for k, _ in pairs(self.exclude.keywords) do
            self.exclude.keywords[k] = true
        end
    end


    if not user_opts.exclude_all_default_paths then
        if user_opts.paths then
            for i = 1, #default_opts.paths do
                self.opts.paths[#self.opts.paths + 1] = default_opts.paths[i]
            end
        end
    end



    if user_opts.keywords then
        for i = 1, #default_opts.keywords do
            self.opts.keywords[#self.opts.keywords + 1] = default_opts.keywords[i]
        end
    end

    if user_opts.use_defaults or user_opts.use_defaults == nil then
        if user_opts.paths then
            for i = 1, #default_opts.paths do
                self.opts.paths[#self.opts.paths + 1] = default_opts.paths[i]
            end
        end
        if user_opts.keywords then
            for i = 1, #default_opts.keywords do
                self.opts.keywords[#self.opts.keywords + 1] = default_opts.keywords[i]
            end
        end
    elseif user_opts.use_defaults == false then
        self.opts = vim.tbl_deep_extend('force', self.opts, user_opts)
    end

    if self.opts.keywords then
        self:generate_patterns(self.opts.keywords)
    end


    vim.o.concealcursor = self.cursor_levels[self.opts.level]
    if not self.enabled then
        self.default_conceallevel = vim.o.conceallevel
    end
    if self.opts.default_state == 'on' then
        self:start_streamer_mode()
    end
end

function M:start_with_defaults()
    self.opts = vim.tbl_deep_extend('force', self.opts, default_opts)
    vim.o.concealcursor = self.cursor_levels[self.opts.level]
    if not self.enabled then
        self.default_conceallevel = vim.o.conceallevel
    end
    if self.opts.default_state == 'on' then
        self:start_streamer_mode()
    end
    self:generate_patterns(self.opts.keywords)
end

---Alias for `configure_options`
function M.setup(opts)
    M:configure_options(opts)
end

---Takes in a table in the format of { keyword = true }
---Any keyword that is assigned a value of `true` will be added to
---the conceal patterns.
---@param keywords table list
function M:generate_patterns(keywords)
    self.opts.patterns = self.opts.patterns or {}
    for i = 1, #keywords do
        if not self.exclude.keywords[keywords[i]] then
            self.opts.patterns[#self.opts.patterns + 1] = self._BaseKeywordConcealPattern:format(keywords[i])
        end
    end
end

---Callback for autocmds.
function M:add_match_conceals()
    -- vim.notify("Options: " .. vim.inspect(self.opts))
    if self.opts.patterns then
        for i = 1, #self.opts.patterns do
            table.insert(
                self._matches,
                vim.fn.matchadd('Conceal', self.opts.patterns[i], 9999, -1, { conceal = self.opts.conceal_char })
            )
        end
    end
end

---Activates Streamer Mode
function M:add_conceals()
    self:clear_matches()
    self:setup_conceal_autocmds()
    self:setup_ssh_conceal_autocmds()
    self:add_match_conceals()
    self:start_ssh_conceals()
    vim.o.conceallevel = 1
    self.enabled = true
    -- self.autocmds = vim.api.nvim_get_autocmds({ group = self.conceal_augroup })
end

---Turns off Streamer Mode (Removes Conceal commands)
function M:remove_conceals()
    vim.api.nvim_clear_autocmds({ group = self.conceal_augroup })
    self:clear_matches()
    self.enabled = false
    vim.o.conceallevel = self.default_conceallevel
end

--- Remove all the matches made with matchadd()
function M:clear_matches()
    if self._matches then
        for i = 1, #self._matches do
            vim.fn.matchdelete(self._matches[i])
        end
        self._matches = {}
    end
end

---Sets up conceals for environment variables
function M:setup_conceal_autocmds()
    if self.opts.paths then
        for _, path in pairs(self.opts.paths) do
            vim.api.nvim_create_autocmd({ 'BufEnter' }, {
                pattern = path,
                callback = function()
                    self:add_match_conceals()
                end,
                group = self.conceal_augroup,
            })
        end
    end
end

---Starts Streamer Mode. Alias for `add_conceals()`
function M:start_streamer_mode()
    -- vim.notify("Current options: " .. vim.inspect(self.opts))
    -- if not self.opts.patterns then
    --     self.setup({ use_defaults = true })
    -- end
    self:add_conceals()
end

---Stops Streamer Mode. Alias for `remove_conceals()`
function M:stop_streamer_mode()
    self:remove_conceals()
end

function M:toggle_streamer_mode()
    if self.enabled then
        return self:stop_streamer_mode()
    end
    return self:start_streamer_mode()
end

M.ssh_conceal_pattern =
    [[^-\{1,}BEGIN OPENSSH PRIVATE KEY-\{-1,}\n\zs\(\_.\{-}\)\ze-\{1,}END OPENSSH PRIVATE KEY-\{-1,}\n\?]]
function M:start_ssh_conceals()
    if self.ssh_conceal_pattern then
        table.insert(
            self._matches,
            vim.fn.matchadd('Conceal', self.ssh_conceal_pattern, 9999, -1, { conceal = self.opts.conceal_char })
        )
    end
end

function M:setup_ssh_conceal_autocmds()
    vim.api.nvim_create_autocmd({ 'BufEnter' }, {
        pattern = '*/.ssh/*',
        callback = function()
            -- Check that the filename doesn't end with .pub
            if vim.fn.expand('%:e') ~= 'pub' then
                self:start_ssh_conceals()
            end
        end,
        group = self.conceal_augroup,
    })
end

return M

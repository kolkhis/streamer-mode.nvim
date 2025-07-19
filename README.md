# Streamer Mode - Be Safe!  

### Streamer Mode - a Neovim plugin to hide your environment variables.  

This plugin is not just for streamers, but anyone who wants to conceal their environment  
variables and other sensitive information.  

![Streamer-Mode Demo](https://github.com/Kolkhis/streamer-mode.nvim/assets/36500473/3fc1fc02-f4f4-4c6f-a5f7-bbc077f384fa)  

##### *Short demo of the basic modes.*  

If you find a bug, please let me know! I'll try to fix it as soon as I can.  


> #### Side note: It's recommended that you find a more secure way to store VERY private information than in plain text environment variables. But sometimes it's just easier for a temporary solution.  
> #### NOTE: Streamer mode may affect `:help` docs, as it utilizes the `conceallevel` variable.

If anyone has any requests for new customizations or other features, please don't hesitate to let me know.  
Just [open an issue](https://github.com/Kolkhis/streamer-mode.nvim/issues)!  




## Table of Contents
* [Current Features](#current-features) 
* [Installation](#installation) 
* [Setup](#setup) 
    * [Default Setup](#default-setup) 
* [Usage](#usage) 
* [Commands](#commands) 
* [Advanced Setup](#advanced-setup) 
* [Default Settings](#default-settings) 
* [Setup Parameters](#setup-parameters) 
    * [Setting Keywords to Conceal](#setting-keywords-to-conceal) 
    * [Setting Paths and Filetypes](#setting-paths-and-filetypes) 
    * [Enabling Streamer Mode in all files](#enabling-streamer-mode-in-all-files) 
    * [Custom Behavior and Style Options](#custom-behavior-and-style-options) 
    * [Example Custom Setup](#example-custom-setup) 
* [Levels](#levels) 
* [Currently Working On](#currently-working-on) 
* [Known Issues](#known-issues) 


## Current Features  

By default, Streamer Mode currently supports the concealment of a number of  
keywords (see [default settings](#default-settings)).  
You can specify your own keywords to conceal in the [`setup()`](#setup) function.  

* Hides the contents of all SSH private keys (`id_rsa`, `id_ed25519`, `id_dsa`, etc.)  
  in any `.ssh` directory.  
    * Note that this is reliant on the filename starting with `id_`.  
      I will be adding support for private SSH keys with custom filenames  
      in the future.  

* Hides environment variables and sensitive `.gitconfig` information.  

* Streamer Mode can operate at different **levels** of concealment, which determine how and when hidden text becomes visible.

    * Three different levels: Secure, Edit, and Soft  

    * See [Levels](#levels) or `:help sm.levels` for more information on level behaviors.  

* Ability to type out new secret variables without displaying them ([secure level](#levels)), like sudo password input.  

## Installation  

Install using your favorite plugin manager.  
<details> 
  <summary>packer.nvim</summary>  

```lua  
use('Kolkhis/streamer-mode.nvim')  
```
</details>  


<details>  
  <summary>lazy.nvim</summary> 

```lua  
{ 'Kolkhis/streamer-mode.nvim' },
```
</details>  


<details>  
  <summary>vim-plug</summary>  
 
```vim  
Plug 'Kolkhis/streamer-mode.nvim'  
```
</details>  

## Setup  

###### *:help sm.setup*  
### Default Setup:  
To enable streamer mode by default with the default settings, add the following  
to your `init.lua` file:  
```lua  
require('streamer-mode').setup()  
```
This will enable `streamer-mode.nvim` with the default settings.  

After restarting Neovim, run `:SM` to toggle on Streamer Mode.  
It will be off by default.  

To enable Streamer Mode on launch:  
```lua  
require('streamer-mode').setup({ default_state = 'on' })  
```

Now Streamer Mode will be active every time a new Neovim session is launched.  
Call `:SMoff` to disable Streamer Mode, or simply toggle it with `:SM`.  


`streamer-mode.nvim` applies filters to most of the files that will contain sensitive information by default. See [default settings](#default-settings).  

    

## Usage  

Streamer Mode will be off be default, unless `default_state = 'on'` is passed during [setup](#setup)).  
To toggle it on, use the command `:SM`, or `:SM(level)`.  

Here's an example of binding it to a key:  
```lua  
vim.keymap.set('n', '<leader>sm', '<cmd>SM<CR>', { silent = true })  
```
Now `<leader>sm` will toggle Streamer Mode on and off.  


## Commands  

###### *:h sm.commands*  

There are five commands available for Streamer Mode.  
Each command has an alias for easier typing.  
The new mode will go into effect once the command is called.  

* `:StreamerMode` (`:SM`) - Toggle Streamer Mode on and off.  
* `:StreamerModeOff` (`:SMoff`) - Shuts off Streamer Mode.  
* `:StreamerModeSecure` (`:SMsecure`) - Starts streamer mode with `secure` level enabled.  
* `:StreamerModeEdit` (`:SMedit`) - Starts streamer mode with `edit` level enabled.  
* `:StreamerModeSoft` (`:SMsoft`) - Starts streamer mode with `soft` level enabled.  
  

## Default Settings  

The default settings are as follows:  
```lua  
require('streamer-mode').setup({
  -- Streamer Mode will apply to any path in here. Defaults to all paths. 
  -- This means that Streamer Mode will hide any of the `keywords` below 
  -- when inside any of these directories or filetypes.  
  paths = { '*' },
  -- Exclude all the default keywords and only use the ones you specify
  exclude_all_default_keywords = false, -- | true

  -- Only exclude the given keywords from the default values
  exclude_default_keywords = {},

  -- Exclude the default path (which is '*', all paths) and only use the ones you specify
  exclude_default_paths = false, 

  -- Same as `exclude_default_paths`
  exclude_all_default_paths = false, 

  -- Any text appearing after one of the keywords specified here will be concealed.  
  -- They are case-insensitive.  
  -- E.g., passing in 'API_KEY' will conceal both 'API_KEY' and 'api_key'.  
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

  conceal_char = '*',  -- Default. This is what will be displayed instead  
                       -- of your secrets.  
})  
```


## Setup Parameters:  

##### All optional. Simply calling `require('streamer-mode').setup()` will use the defaults.  

* **DEPRECATED** - `use_defaults` (Boolean): Whether or not to use the default paths and keywords.  
    - Use the `exclude` options instead. This will have no effect.
* `exclude_default_keywords` (List-like table): The default values of `keywords` that
  will **not** be used.  
* `exclude_all_default_keywords` (Boolean): Whether or not to use default keywords.  
    - `true`: Does not use any of the defaults, only what you specify in `.setup()`.  
    - `false` (default): Use the default keywords.  
* `keywords` (List-like Table): Keywords that will be concealed.  
    * Any text that appears **after** one of these keywords will be concealed 
      with `conceal_char` (default is `*`).  
    * It is possible to pass a Vim basic regular expression (BRE) as a keyword.  
* `paths` (List-like Table): The paths and filetypes that Streamer Mode will apply to.  
    * Globbing with `*` is supported.  
    * Pass in paths in the format: `paths = { '*/path/*' }`
    * Pass in filetypes in the same format: ` paths = { '*.txt' }`
* `level` (String): The level in which Streamer Mode will be in effect.  
    * See more about the different [levels](#levels) below.  
* `default_state` (String): Whether or not Streamer Mode will be active  
  when you first launch a Neovim session. It's recommended to set this to `'off'`,
  turning it on when needed.  
* `conceal_char` (String): This is the character that will be displayed in place of your hidden text.  


### Setting Keywords to Conceal  
To set your own keywords to conceal, pass them in as a list-like table to  
the `require('streamer-mode').setup()` function.  

The `keywords` table is formatted as follows:  
```lua  
require('streamer-mode').setup({
    default_state = 'on',
    keywords = {
        "secret",
        "api_key",
        "token",
        "auth_token",
        "MySecretVariable",
        "MyAddress",
    }
})  
```
Keywords are not case-sensitive.  
E.g., passing in `API_KEY` will conceal both `API_KEY` and `api_key`.  


### Setting Paths and Filetypes 
`streamer-mode.nvim` applies to all files by default.  
If you want to apply Streamer Mode to only certain paths or filetypes,
pass them in as a list to the `require('streamer-mode').setup()` function.

For example, to apply Streamer Mode to only files in your home directory,
pass in `~/*`.  
```lua  
require('streamer-mode').setup({
  -- Add your own paths and filetypes for Streamer Mode to be enabled in.  
  paths = {
    '*/*.yaml',  -- Enables Streamer Mode for all YAML files.  
    '*/.bash*',  -- Enables Streamer Mode for all Bash configuration files.  
    '~/*',       -- Enables Streamer Mode for all files in your home directory.  
  },
})  
```

### Enabling Streamer Mode in all files  
Streamer Mode is now enabled in all files by default.


### Custom Behavior and Style Options  
You can customize the following style and behavior options:  
* `conceal_char`: The character used to conceal text.  
* `level`: Determines the behavior of the concealed text (see [levels](#levels)).  
* `default_state`: Whether or not Streamer Mode is enabled when Neovim is launched.  
```lua  
require('streamer-mode').setup({
  level = 'secure',
  default_state = 'off',
  conceal_char = '-'  
})  
```
  


### Example Custom Setup  

Here's an example of a custom configuration.  


Note that all the default `paths` and `keywords` will be used unless explicitly disabled:
* `exclude_all_default_keywords = true` or `exclude_default_keywords = { 'keyword1', 'keyword2' }` etc.  
* `exclude_default_paths = true` (there is only one value here, `'*'`).  
    * `exclude_all_default_paths = true` will work too.  

```lua  
require('streamer-mode').setup({
  -- Use the default paths and keywords in addition to your own.  
  exclude_default_keywords = { 'alias', 'export' },
  exclude_all_default_paths = true, 
  paths = {
    -- While working in buffers that match any path or filetype listed here,
    -- streamer-mode will conceal all keywords in the `keywords` table.  
    '*/dotenv/*',
    '*/.env',
    '*.c',
    '~/.bash*',
    '~/.dotfiles/*',
    '~/.my_config/*',
    '*/.gitconfig',
  },
  keywords = {
    'token',
    'auth_token',
    'auth_key',
    'my_key',
    'MySecretVariable',
    'MyAddress',
  }
  level = 'edit', -- | 'secure' | 'soft'  
  default_state = 'on', -- | 'off'  
  conceal_char = 'X' -- Can be any character  
})  
```


## Levels  

###### *:h sm.levels*  

There are three different levels, each with different behavior.  

* `'secure'` (default) will prevent the concealed text from becoming  
  visible at all.  
  This will also conceal any keywords while typing  
  them (like sudo password input).  
* `'edit'` will allow the concealed text to become visible  
  only when the cursor goes into insert mode on the same line.  
* `'soft'` will allow the concealed text to become visible  
  when the cursor is on the same line in any mode.  
  

## Known Issues  

* Concealing doesn't currently work in Telescope pickers/previwers.




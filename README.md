<div align="center">

# `buffer_manager.nvim`
##### A simple plugin to easily manage Neovim buffers

[![Neovim](https://img.shields.io/badge/Neovim%200.5+-green.svg?style=for-the-badge&logo=neovim)](https://neovim.io)
[![Lua](https://img.shields.io/badge/Lua-blue.svg?style=for-the-badge&logo=lua)](http://www.lua.org)

:warning: Currently in beta - may have bugs or instability :warning:

</div>



## The never-ending problem

I want to manage Neovim buffers easily, without the mental overhead of remembering its ids or partial names. Buffer management includes moving to a buffer and deleting/adding one or more buffers.

## The proposed solution

Use a buffer-like floating window where all the open buffers are listed. To select one buffer, just hit its line number, or move to it and press `<CR>`. To delete the buffer, delete it from the list. To add it (predictably) add a filename to the list.


## Installation

* Neovim 0.5.0+ required
* Install `buffer_manager` using your favorite plugin manager. E.g. `Packer.nvim`:

```lua
use 'nvim-lua/plenary.nvim'  -- basic dependency
use 'j-morano/buffer_manager.nvim'
```

## Usage

### View all buffers and go to a buffer

```lua
:lua require("buffer_manager.ui").toggle_quick_menu()
```

Then, move to one of them, and open it with `<CR>`.
Alternative: press the key corresponding to its line number (notice that, in this case, 0 maps to 10, since there is no 0 line).

### Add buffer

Write the filename of the new buffer.

(Some people will find this useless, but I often use this functionality together with an autocomplete for files.)

### Remove buffer

Delete it in the buffer menu.


## Configuration


### Example
```
map({ 't', 'n' }, '<M-Space>', require("buffer_manager.ui").toggle_quick_menu, {noremap = true})
```


## Logging

- Logs are written to `buffer_manager.log` within the nvim cache path (`:echo stdpath("cache")`)
- Available log levels are `trace`, `debug`, `info`, `warn`, `error`, or `fatal`. `warn` is default
- Log level can be set with `vim.g.buffer_manager_log_level` (must be **before** `setup()`)
- Launching nvim with `BUFFER_MANAGER_LOG=debug nvim` takes precedence over `vim.g.buffer_manager_log_level`.
- Invalid values default back to `warn`.

## Others

### Use a dynamic width for the `buffer_manager` pop-up menu

Sometimes the default width of (`60`) is not enough.
The following example demonstrates how to configure a custom width by setting
the menu's width relative to the current window's width.

```lua
require("buffer_manager").setup({
    width = vim.api.nvim_win_get_width(0) - 4,
})
```

## TODO

* Disable/enable automatic save.


## Acknowledgements

This plugin is based on [Harpoon](https://github.com/ThePrimeagen/harpoon), an amazing plugin written by ThePrimeagen to easily navigate previously marked terminals and files.

Also, special thanks to [bufdelete.nvim](https://github.com/famiu/bufdelete.nvim), for showing how to remove buffers correctly.

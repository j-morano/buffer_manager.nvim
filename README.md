<div align="center">

# peruse.nvim
##### A lightweight plugin to easily navigate open buffers

[![Neovim](https://img.shields.io/badge/Neovim%200.5+-green.svg?style=for-the-badge&logo=neovim)](https://neovim.io)
[![Lua](https://img.shields.io/badge/Lua-blue.svg?style=for-the-badge&logo=lua)](http://www.lua.org)

</div>


## The never-ending problem

I want to move easily between buffers, without relying on heavy plugins with a thousand features or thinking in advance about marking buffers to access them later.

And what about `:buffers<CR>:b<space>`? For me, it's not an option. Certain plugins cause the buffer ids to grow out of proportion. The same happens after hours of working on a project opening and closing files... Besides, remembering portions of filenames to access them seems to me to be an excessive mental overhead.


## The proposed solution

Use a buffer-like floating window where all the open buffers are listed. To select one buffer, just move to it and press `<CR>`.


## Installation

* Neovim 0.5.0+ required
* Install peruse using your favorite plugin manager. E.g. `Packer.nvim`:

```lua
use 'nvim-lua/plenary.nvim'  -- basic dependency
use 'sonarom/peruse.nvim'
```

## Usage

View all buffers using
```lua
:lua require("peruse.ui").toggle_quick_menu()
```
move to one of them, and open it with `<CR>`. _Finis_.


## Configuration

peruse can be configured through the setup function:

```lua
require("peruse").setup({ ... })
```


## Logging

- Logs are written to `peruse.log` within the nvim cache path (`:echo stdpath("cache")`)
- Available log levels are `trace`, `debug`, `info`, `warn`, `error`, or `fatal`. `warn` is default
- Log level can be set with `vim.g.peruse_log_level` (must be **before** `setup()`)
- Launching nvim with `PERUSE_LOG=debug nvim` takes precedence over `vim.g.peruse_log_level`.
- Invalid values default back to `warn`.

## Others

### Use a dynamic width for the peruse popup menu

Sometimes the default width of `60` is not wide enough.
The following example demonstrates how to configure a custom width by setting
the menu's width relative to the current window's width.

```lua
require("peruse").setup({
    menu = {
        width = vim.api.nvim_win_get_width(0) - 4,
    }
})
```

## TODO

### Actions on listed buffers
* Add, delete, remove, etc.


## Acknowledgements

This plugin is based on [Harpoon](https://github.com/ThePrimeagen/harpoon), an amazing plugin written by ThePrimeagen to easily navigate marked terminals and files.

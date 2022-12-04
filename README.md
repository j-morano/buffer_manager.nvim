<div align="center">

# `buffer_manager.nvim`
##### A simple plugin to easily manage Neovim buffers

[![Neovim](https://img.shields.io/badge/Neovim%200.5+-green.svg?style=for-the-badge&logo=neovim)](https://neovim.io)
[![Lua](https://img.shields.io/badge/Lua-blue.svg?style=for-the-badge&logo=lua)](http://www.lua.org)

https://user-images.githubusercontent.com/48717183/205488331-fbd939bf-d8e2-42bf-bea5-8956e2e02f51.mp4

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

### Add buffer/Create file

Write the filename of the new buffer.

(Some people will find this useless, but I often use this functionality together with an autocomplete for files.)

Tip: you can use the Neovim built-in file autocomplete functionality (`<C-x><C-f>`) to ease the opening of new files.

If the file does not exist, a new empty buffer will be created, which will be written to the specified file when it is saved.

### Remove buffer

Delete it in the buffer menu.

**Note:** the plugin does not remove terminal buffers or modified buffers.

### Reorganize buffers

The buffers can be reorganized in any way. To do it, just move the name of the buffer to the chosen line.

## Configuration

### Plugin configuration

The plugin can be configured through the setup function:
```lua
require("buffer_manager").setup({ })
```

#### Available configuration options
* `select_menu_item_commands`: Lua table containing the keys and the corresponding `command` to run for the buffer under the cursor.
* `line_keys`: keys bound to each line of the buffer menu, in order.

#### Default configuration
```lua
  {
    line_keys = "1234567890",
    select_menu_item_commands = {
      edit = {
        key = "<CR>",
        command = "edit"
      }
    }
  }
```

#### Example configuration
```lua
require("buffer_manager").setup({
  line_keys = "",  -- deactivate line keybindings
  select_menu_item_commands = {
    v = {
      key = "<C-v>",
      command = "vsplit"
    },
    h = {
      key = "<C-h>",
      command = "split"
    }
  }
})
```


### Example keybinding for opening the buffer menu

To open the buffer menu, you can put this line in your Lua configuration file.
```lua
vim.keymap.set({ 't', 'n' }, '<M-Space>', require("buffer_manager.ui").toggle_quick_menu, {noremap = true})
```

### Other useful settings

Since the buffer menu is just a buffer with the specific file type `buffer_manager`, you can define your own remaps using an autocmd for this filetype. For example, the following remaps allow to move a line up and down in visual mode with capital K and J, respectively.
```vim
autocmd FileType buffer_manager vnoremap J :m '>+1<CR>gv=gv
autocmd FileType buffer_manager vnoremap J :m '<-2<CR>gv=gv
```
This is very useful for reorganizing the buffers.

You can also set the previous autocmds with Lua as follows:
```lua
vim.api.nvim_command([[
autocmd FileType buffer_manager vnoremap J :m '>+1<CR>gv=gv
autocmd FileType buffer_manager vnoremap J :m '<-2<CR>gv=gv
]])
```


## Logging

- Logs are written to `buffer_manager.log` within the nvim cache path (`:echo stdpath("cache")`)
- Available log levels are `trace`, `debug`, `info`, `warn`, `error`, or `fatal`. `warn` is default
- Log level can be set with `vim.g.buffer_manager_log_level` (must be **before** `setup()`)
- Launching nvim with `BUFFER_MANAGER_LOG=debug nvim` takes precedence over `vim.g.buffer_manager_log_level`.
- Invalid values default back to `warn`.

<!--## Others

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

-->

## Contributing and reporting issues

All contributions are welcome! Just open a pull request.

Furthermore, feel free to open an issue if something is not working as expected.

All feedback is appreciated!

## Acknowledgements

This plugin is based on [Harpoon](https://github.com/ThePrimeagen/harpoon), an amazing plugin written by ThePrimeagen to easily navigate previously marked terminals and files.

Also, special thanks to [bufdelete.nvim](https://github.com/famiu/bufdelete.nvim), for showing how to remove buffers correctly.

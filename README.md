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

### Go to next or previous buffer in the list

```lua
:lua require("buffer_manager.ui").nav_next()
:lua require("buffer_manager.ui").nav_prev()
```

### Save buffer list to a file or load it

Introduce the filename interactively:
```lua
:lua require'buffer_manager.ui'.save_menu_to_file()
:lua require'buffer_manager.ui'.load_menu_from_file()
```

Introduce the filename directly as a function argument:
```lua
:lua require'buffer_manager.ui'.save_menu_to_file('bm')
:lua require'buffer_manager.ui'.load_menu_from_file('bm')
```

## Configuration

### Plugin configuration

The plugin can be configured through the setup function:
```lua
require("buffer_manager").setup({ })
```

#### Available configuration options

* `select_menu_item_commands`: Lua table containing the keys and the corresponding `command` to run for the buffer under the cursor.
* `line_keys`: keys bound to each line of the buffer menu, in order.
* `focus_alternate_buffer`: place the cursor over the alternate buffer instead of the current buffer.
* `width`: Width in columns (if > 1) or relative to window width (if <= 1).
* `height`: Height in rows (if > 1) or relative to window height (if <= 1).
* `short_file_names`: Shorten buffer names: filename+extension, preceded by the number of levels under the current dir and a slash.
* `short_term_names`: Shorten terminal buffer names.
* `loop_nav`: Loop or not the files when using `nav_next` and `nav_prev`. When `false`, `nav_prev` does nothing when at first buffer, and either does `nav_next` when at last one. When `true`, `nav_next` goes to the first buffer when at last one, and `nav_prev` goes to the last buffer when at first one.
* `highlight`: highlight for the window border.
* `win_extra_options`: extra options for the menu window. E.g. `{ relativenumber = true }`.

#### Default configuration

```lua
  {
    line_keys = "1234567890",
    select_menu_item_commands = {
      edit = {
        key = "<CR>",
        command = "edit"
      }
    },
    focus_alternate_buffer = false,
    short_file_names = false,
    short_term_names = false,
    loop_nav = true,
    highlight = "Normal",
    win_extra_options = {},
  }
```

#### Example configuration

```lua
local opts = {noremap = true}
local map = vim.keymap.set
-- Setup
require("buffer_manager").setup({
  select_menu_item_commands = {
    v = {
      key = "<C-v>",
      command = "vsplit"
    },
    h = {
      key = "<C-h>",
      command = "split"
    }
  },
  focus_alternate_buffer = false,
  short_file_names = true,
  short_term_names = true,
  loop_nav = false,
})
-- Navigate buffers bypassing the menu
local bmui = require("buffer_manager.ui")
local keys = '1234567890'
for i = 1, #keys do
  local key = keys:sub(i,i)
  map(
    'n',
    string.format('<leader>%s', key),
    function () bmui.nav_file(i) end,
    opts
  )
end
-- Just the menu
map({ 't', 'n' }, '<M-Space>', bmui.toggle_quick_menu, opts)
-- Open menu and search
map({ 't', 'n' }, '<M-m>', function ()
  bmui.toggle_quick_menu()
  -- wait for the menu to open
  vim.defer_fn(function ()
    vim.fn.feedkeys('/')
  end, 50)
end, opts)
-- Next/Prev
map('n', '<M-j>', bmui.nav_next, opts)
map('n', '<M-k>', bmui.nav_prev, opts)
```


### Useful settings

#### Reorder buffers

Since the buffer menu is just a buffer with the specific file type `buffer_manager`, you can define your own remaps using an autocmd for this filetype. For example, the following remaps allow to move a line up and down in visual mode with capital K and J, respectively.
```vim
autocmd FileType buffer_manager vnoremap J :m '>+1<CR>gv=gv
autocmd FileType buffer_manager vnoremap K :m '<-2<CR>gv=gv
```
This is very useful for reorganizing the buffers.

You can also set the previous autocmds with Lua as follows:
```lua
vim.api.nvim_command([[
autocmd FileType buffer_manager vnoremap J :m '>+1<CR>gv=gv
autocmd FileType buffer_manager vnoremap K :m '<-2<CR>gv=gv
]])
```

## Logging

- Logs are written to `buffer_manager.log` within the nvim cache path (`:echo stdpath("cache")`)
- Available log levels are `trace`, `debug`, `info`, `warn`, `error`, or `fatal`. `warn` is default
- Log level can be set with `vim.g.buffer_manager_log_level` (must be **before** `setup()`)
- Launching nvim with `BUFFER_MANAGER_LOG=debug nvim` takes precedence over `vim.g.buffer_manager_log_level`.
- Invalid values default back to `warn`.


## Contributing and reporting issues

All contributions are welcome! Just open a pull request.

Furthermore, feel free to open an issue if something is not working as expected.

All feedback is appreciated!

## Acknowledgements

This plugin is based on [Harpoon](https://github.com/ThePrimeagen/harpoon), an amazing plugin written by ThePrimeagen to easily navigate previously marked terminals and files.

Also, special thanks to [bufdelete.nvim](https://github.com/famiu/bufdelete.nvim), for showing how to remove buffers correctly.

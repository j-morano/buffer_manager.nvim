<div align="center">

![bm_logo_simple](https://github.com/user-attachments/assets/5bb65a2a-358f-4c3f-a776-93df0242ccba)

### A simple plugin to easily manage Neovim buffers

[![Neovim](https://img.shields.io/badge/Neovim%200.5+-green.svg?style=for-the-badge&logo=neovim)](https://neovim.io)
[![Lua](https://img.shields.io/badge/Lua-blue.svg?style=for-the-badge&logo=lua)](http://www.lua.org)

https://user-images.githubusercontent.com/48717183/205488331-fbd939bf-d8e2-42bf-bea5-8956e2e02f51.mp4

</div>


## The never-ending problem

I want to manage Neovim buffers easily, without the mental overhead of remembering its ids or partial names. Buffer management includes moving to a buffer and deleting/adding one or more buffers.

## The proposed solution

Use a buffer-like floating window where all the open buffers are listed. To select one buffer, just hit its line identifier (a char), or move to it and press `<CR>`. To delete the buffer, delete it from the list. To add it (predictably) add a filename to the list.


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
Alternative: press the key corresponding to its line identifier char, which are numbers by default (notice that, in this case, 0 maps to 10, since there is no 0 line).

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

* `select_menu_item_commands` (table): Lua table containing the keys and the corresponding `command` to run for the buffer under the cursor.
* `line_keys` (string): keys bound to each line of the buffer menu, in order.
* `focus_alternate_buffer` (boolean): place the cursor over the alternate buffer instead of the current buffer.
* `width` (number|nil): Width in columns (if > 1) or relative to window width (if <= 1). When relative, the value is treated as a percentage of the window width. For example, `0.5` means 50% of the window width.
* `height` (number|nil): Height in rows (if > 1) or relative to window height (if <= 1). When relative, the value is treated as a percentage of the window height. For example, `0.5` means 50% of the window height.
* `short_file_names` (boolean): Shorten buffer names: filename+extension, preceded by the number of levels under the current dir and a slash.
* `show_depth` (boolean): Show the number of levels under the current dir before the filename (`n|filename`).
* `short_term_names` (boolean): Shorten terminal buffer names.
* `show_cols` (string): show columns in the menu. Options are `"number"` (show only the line number), `"kbs"` (show only the keybindings), and `"both"` (show both line number and keybindings).
* `loop_nav` (boolean): Loop or not the files when using `nav_next` and `nav_prev`. When `false`, `nav_prev` does nothing when at first buffer, and either does `nav_next` when at last one. When `true`, `nav_next` goes to the first buffer when at last one, and `nav_prev` goes to the last buffer when at first one.
* `highlight` (string): highlight for the window. Format: `from1:to1,from2:to2`. E.g. `Normal:MyCustomNormal`. (See `:help winhighlight`.)
* `win_extra_options` (table): extra options for the menu window. E.g. `{ relativenumber = true }`. (See `:help option-list`.)
* `borderchars` (table): border characters for the menu window.
* `format_function` (function|nil): support for custom function to format buffer names. The function should receive a string and return a string. This option is incompatible with `short_file_names`. To use it, `short_file_names` must be set to `false`. By default, the function is `nil`, which means no special formatting is applied.
* `order_buffers` (string|nil): order the buffers in the menu. Options are `"filename"`, `"bufnr"`, `"lastused"` and `"fullpath"`. By default, it is `nil`, which means the buffers are not automatically ordered. If `reverse` is added to the option, the buffers are ordered in reverse order. For example, `order_buffers = 'filename:reverse'`.
* `show_indicators` (string|nil): show indicators for buffers in virtual text. See `:help ls` for more information about indicators. Possible values are `"before"` (before filename) and `"after"` (after filename). When set to `nil`, no indicators are shown.
* `toggle_key_bindings` (table): table with the keys to toggle the menu. The default is `{ "q", "<ESC>" }`, which means that the menu can be closed with `q` or `<ESC>`.
* `use_shortcuts` (boolean): whether to use characters from filenames to navigate to them. If `true`, the first character of the filename is used as a shortcut (i.e. as a key for the line). If the character is already used by another filename, the next character is used, and so on. It is important to note that this mode overrides the default Vim keybindings. E.g., `d`, if there is file names `data.lua`, would behave as a shortcut in normal mode, instead of Vim's `delete`. To avoid this, and enter the regular `Normal` mode with default keybindings, just press `<space>`. The default is for this option `false`.
* `win_position` (table): position of the window in the screen. It is a table with two fields: `h` and `v`, which represent the horizontal and vertical position, respectively. The values are relative to the screen size, so they should be between `0` and `1`. For example, `{ h = 0.5, v = 0.5 }` places the window in the center of the screen.
* `quick_kbs` (table): whether to use quick keybindings to open the files. Quick keybindings overwrite the Neovim keybindings for the other buffers using `nowait = true`, so there is no delay. The option can be activated by setting `enabled` to `true`. In addition, in case some quick keybindings overlap with those useful for editing the buffers, you can specify a keybinding to temporarily disable the quick keybindings by setting the `kb` field.


In addition, you can specify a custom color for the modified buffers, the indicators, and the shortcut characters, by setting the corresponding highlight groups to the desired color. For example:

```lua
vim.api.nvim_set_hl(0, "BufferManagerModified", { fg = "#0000af" })
vim.api.nvim_set_hl(0, "BufferManagerShortcut", { fg = "#cc0000", bold = true })
vim.api.nvim_set_hl(0, "BufferManagerIndicator", { fg = "#999999", italic = true })
```

#### Default configuration

```lua
  local default_config = {
    line_keys = "1234567890",
    select_menu_item_commands = {
      edit = {
        key = "<CR>",
        command = "edit"
      }
    },
    focus_alternate_buffer = false,
    width = nil,
    height = nil,
    short_file_names = false,
    show_depth = true,
    short_term_names = false,
    show_cols = "number", -- "kbs", "both"
    loop_nav = true,
    highlight = "",
    win_extra_options = {},
    borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
    format_function = nil,
    order_buffers = nil, -- "filename", "bufnr", "lastused", "fullpath"
    show_indicators = nil,
    toggle_key_bindings = { "q", "<ESC>" },
    use_shortcuts = false,
    win_position = { h=0.5, v=0.5 },
    quick_kbs = {
      enabled = false,
      kb = nil
    },
  }
```

#### Example configuration

```lua
local opts = {noremap = true}
local map = vim.keymap.set

---- Setup
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
  highlight = 'Normal:BufferManagerBorder',
  win_extra_options = {
    winhighlight = 'Normal:BufferManagerNormal',
  },
  use_shortcuts = true,
})

---- Navigate buffers bypassing the menu
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

---- Just the menu
map({ 't', 'n' }, '<M-Space>', bmui.toggle_quick_menu, opts)

---- Open menu and search
map({ 't', 'n' }, '<M-m>', function ()
  bmui.toggle_quick_menu()
  -- wait for the menu to open
  vim.defer_fn(function ()
    vim.fn.feedkeys('/')
  end, 50)
end, opts)

---- Next/Prev
map('n', '<M-j>', bmui.nav_next, opts)
map('n', '<M-k>', bmui.nav_prev, opts)

---- Navigate to the first terminal buffer
local function string_starts(string, start)
  return string.sub(string, 1, string.len(start)) == start
end

local function nav_term()
  -- Go to the first terminal buffer
  bmui.update_marks()
  for idx, mark in pairs(bm.marks) do
    if string_starts(mark.filename, "term://") then
      bmui.nav_file(idx)
      return
    end
  end
  -- If no terminal buffer is found, create a new one
  vim.cmd('terminal')
end

map('n', '<leader>t', nav_term, opts)
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

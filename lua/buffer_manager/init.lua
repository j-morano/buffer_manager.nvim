local Dev = require("buffer_manager.dev")
local log = Dev.log
local merge_tables = require("buffer_manager.utils").merge_tables


local M = {}

BufferManagerConfig = BufferManagerConfig or {}


function M.setup(config)
  log.trace("setup(): Setting up...")

  if not config then
    config = {}
  end

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
    loop_nav = true,
    highlight = "",
    win_extra_options = {},
    borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
    format_function = nil,
    order_buffers = nil,
    show_indicators = nil,
    toggle_key_bindings = { "q", "<ESC>" },
  }

  local complete_config = merge_tables(default_config, config)

  BufferManagerConfig = complete_config
  log.debug("setup(): Config", BufferManagerConfig)
end


function M.get_config()
  log.trace("get_config()")
  return BufferManagerConfig or {}
end

-- Sets a default config with no values
M.setup()


return M

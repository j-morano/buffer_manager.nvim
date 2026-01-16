local Dev = require("buffer_manager.dev")
local log = Dev.log
local utils = require("buffer_manager.utils")


local M = {}

BufferManagerConfig = BufferManagerConfig or {}

M.marks = {}

function M.initialize_marks()
  local buffers = vim.api.nvim_list_bufs()

  for idx = 1, #buffers do
    local buf_id = buffers[idx]
    local buf_name = vim.api.nvim_buf_get_name(buf_id)
    -- if buffer is listed, then add to contents and marks
    if utils.buffer_is_valid(buf_id, buf_name) then
      table.insert(
        M.marks,
        {
          buf_name = buf_name,
          buf_id = buf_id,
          shortcut = utils.assign_shortcut(M.marks, buf_name),
        }
      )
    end
  end
end


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
    use_shortcuts = false,
    win_position = { h=0.5, v=0.5 },
  }

  local complete_config = utils.merge_tables(default_config, config)

  BufferManagerConfig = complete_config
  log.debug("setup(): Config", BufferManagerConfig)
end


function M.get_config()
  log.trace("get_config()")
  return BufferManagerConfig or {}
end

-- Sets a default config with no values
M.setup()

M.initialize_marks()

return M

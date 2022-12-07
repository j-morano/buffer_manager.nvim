local Dev = require("buffer_manager.dev")
local log = Dev.log

local M = {}

BufferManagerConfig = BufferManagerConfig or {}

M.marks = {}

-- tbl_deep_extend does not work the way you would think
local function merge_table_impl(t1, t2)
  for k, v in pairs(t2) do
    if type(v) == "table" then
      if type(t1[k]) == "table" then
        merge_table_impl(t1[k], v)
      else
        t1[k] = v
      end
    else
      t1[k] = v
    end
  end
end

local function merge_tables(...)
  log.trace("_merge_tables()")
  local out = {}
  for i = 1, select("#", ...) do
    merge_table_impl(out, select(i, ...))
  end
  return out
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

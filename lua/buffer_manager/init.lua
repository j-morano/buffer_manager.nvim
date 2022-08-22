local Dev = require("buffer_manager.dev")
local log = Dev.log

local M = {}

BufferManagerConfig = BufferManagerConfig or {}

M.marks = {}


-- 1. saved.  Where do we save?
function M.setup(config)
  log.trace("setup(): Setting up...")

  if not config then
    config = {}
  end

  -- TODO: add defaults here
  -- config = {
  --     borderchars = borderchars,
  --     ...
  -- }

  BufferManagerConfig = config
  log.debug("setup(): Config", BufferManagerConfig)
end


function M.get_config()
  log.trace("get_config()")
  return BufferManagerConfig or {}
end

-- Sets a default config with no values
M.setup()

return M

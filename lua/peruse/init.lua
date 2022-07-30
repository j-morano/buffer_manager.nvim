local Dev = require("peruse.dev")
local log = Dev.log

local M = {}

PeruseConfig = PeruseConfig or {}

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

    PeruseConfig = config
    log.debug("setup(): Config", PeruseConfig)
end


function M.get_config()
    log.trace("get_config()")
    return PeruseConfig or {}
end

-- Sets a default config with no values
M.setup()

return M

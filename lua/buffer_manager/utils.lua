local Path = require("plenary.path")

local M = {}


function M.project_key()
  return vim.loop.cwd()
end

function M.normalize_path(item)
  return Path:new(Path:new(item):absolute()):make_relative(M.project_key())
end

function M.is_white_space(str)
  return str:gsub("%s", "") == ""
end

return M

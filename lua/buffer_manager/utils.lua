local Path = require("plenary.path")
local data_path = vim.fn.stdpath("data")

local M = {}

M.data_path = data_path

function M.project_key()
  return vim.loop.cwd()
end

function M.normalize_path(item)
  return Path:new(item):make_relative(M.project_key())
end

function M.is_white_space(str)
  return str:gsub("%s", "") == ""
end

return M

local Path = require("plenary.path")

local M = {}


function M.project_key()
  return vim.loop.cwd()
end

function M.normalize_path(item)
  if string.find(item, ".*:///.*") ~= nil then
      return Path:new(item)
  end
  return Path:new(Path:new(item):absolute()):make_relative(M.project_key())
end

function M.absolute_path(item)
  return Path:new(item):absolute()
end

function M.is_white_space(str)
  return str:gsub("%s", "") == ""
end

function M.buffer_is_valid(buf_id, buf_name)
    return 1 == vim.fn.buflisted(buf_id)
      and buf_name ~= ""
end

return M

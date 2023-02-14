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

function M.get_file_name(file)
  return file:match("[^/\\]*$")
end

function M.get_short_file_name(file)
  -- Get normalized file path
  file = M.normalize_path(file)
  -- File to string
  file = tostring(file)
  -- Count the number of slashes in the relative file path
  local slash_count = 0
  for _ in string.gmatch(file, "/") do
    slash_count = slash_count + 1
  end
  if slash_count == 0 then
    return M.get_file_name(file)
  else
    -- Return the file name preceded by the number of slashes
    return slash_count .. "|" .. M.get_file_name(file)
  end
end

function M.get_short_term_name(term_name)
  return term_name:gsub("://.*//", ":")
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


function M.merge_tables(...)
  local out = {}
  for i = 1, select("#", ...) do
    merge_table_impl(out, select(i, ...))
  end
  return out
end


function M.deep_copy(obj, seen)
    -- Handle non-tables and previously-seen tables.
    if type(obj) ~= 'table' then return obj end
    if seen and seen[obj] then return seen[obj] end

    -- New table; mark it as seen and copy recursively.
    local s = seen or {}
    local res = {}
    s[obj] = res
    for k, v in pairs(obj) do res[M.deep_copy(k, s)] = M.deep_copy(v, s) end
    return setmetatable(res, getmetatable(obj))
end


return M

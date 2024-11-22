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


local function key_in_table(key, table)
  for k, _ in pairs(table) do
    if k == key then
      return true
    end
  end
  return false
end


function M.get_short_file_name(file, current_short_fns)
  local has_win = vim.fn.has('win32') == 1
  if has_win then
  	file = file:gsub('\\','/')
  end
  local short_name = nil
  -- Get normalized file path
  file = M.normalize_path(file)
  -- Get all folders in the file path
  local folders = {}
  -- Convert file to string
  local file_str = tostring(file)
  for folder in string.gmatch(file_str, "([^/]+)") do
    -- insert firts char only
    table.insert(folders, folder)
  end
  -- folders : table which is constitute of file path every '/'
  -- why does this function call files with multiple times?
  -- File to string
  file = tostring(file)
  -- Count the number of slashes in the relative file path
  local slash_count = 0
  for _ in string.gmatch(file, "/") do -- he makes 'folders', but why do this?
    slash_count = slash_count + 1
  end
  if slash_count == 0 then
    short_name = M.get_file_name(file)
  else
    -- Return the file name preceded by the number of slashes
    short_name = slash_count .. "|" .. M.get_file_name(file) -- get file name only regardless of path
  end
  -- Check if the file name is already in the list of short file names
  -- If so, return the short file name with one number in front of it
  local i = #folders-1
  local filename = short_name
  local dirname = ''
  while key_in_table(short_name:gsub('^%d+|', ''), current_short_fns) do
    local folder = folders[i]
    if folder == nil then
      folder = i
    end
	dirname = folder .. '/' .. dirname
	short_name = filename .. ' (' .. dirname .. ')'
    i = i - 1
  end
  return short_name
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


function M.replace_char(string, index, new_char)
  return string:sub(1,index-1)..new_char..string:sub(index+1)
end


return M

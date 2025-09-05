local Path = require("plenary.path")

local M = {}


function M.project_key()
  return vim.loop.cwd()
end


function M.string_starts(string, start)
  return string.sub(string, 1, string.len(start)) == start
end


function M.string_ends(string, ending)
  return ending == "" or string.sub(string, -string.len(ending)) == ending
end


function M.normalize_path(path)
  if string.find(path, ".*:///.*") ~= nil then
      return Path:new(path)
  end
  return Path:new(Path:new(path):absolute()):make_relative(M.project_key())
end


function M.get_file_name(path)
  return path:match("[^/\\]*$")
end


function M.get_dir_name(path)
  return path:match("(.*/)")
end


local function key_in_table(key, table)
  for k, _ in pairs(table) do
    if k == key then
      return true
    end
  end
  return false
end


function M.get_short_file_name(path, current_short_fns)
  local short_name = nil
  -- Get normalized file path
  path = M.normalize_path(path)
  -- Get all folders in the file path
  local folders = {}
  -- Convert path to string
  local path_str = tostring(path)
  for folder in string.gmatch(path_str, "([^/]+)") do
    -- insert firts char only
    table.insert(folders, folder)
  end
  -- Path to string
  path = tostring(path)
  -- Count the number of slashes in the relative file path
  local slash_count = 0
  if require("buffer_manager").get_config().show_depth then
    for _ in string.gmatch(path, "/") do
      slash_count = slash_count + 1
    end
    if slash_count == 0 then
      short_name = M.get_file_name(path)
    else
      -- Return the file name preceded by the number of slashes
      short_name = slash_count .. "|" .. M.get_file_name(path)
    end
  else
    short_name = M.get_file_name(path)
  end
  -- Check if the file name is already in the list of short file names
  -- If so, return the short file name with one number in front of it
  local i = 1
  while key_in_table(short_name, current_short_fns) do
    local folder = folders[i]
    if folder == nil then
      folder = i
    end
    short_name =  short_name.." ("..folder..")"
    i = i + 1
  end
  return short_name
end


function M.get_short_term_name(term_name)
  return term_name:gsub("://.*//", ":")
end

function M.absolute_path(path)
  return Path:new(path):absolute()
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


function M.assign_shortcut(cmarks, buf_name)
  -- Iterate over the filename, and assing the first char that is not already
  --  assigned in marks.
  local assigned_chars = {}
  for _, mark in pairs(cmarks) do
    if mark.shortcut then
      assigned_chars[mark.shortcut] = true
    end
  end
  local filename = M.get_file_name(buf_name)
  for i = 1, #filename do
    local c = string.lower(filename:sub(i,i))
    if c:match("%w") and not assigned_chars[c] then
      assigned_chars[c] = true
      return c
    end
  end
  return nil
end


return M

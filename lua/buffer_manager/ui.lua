local Path = require("plenary.path")
local buffer_manager = require("buffer_manager")
local popup = require("plenary.popup")
local utils = require("buffer_manager.utils")
local log = require("buffer_manager.dev").log
local marks = require("buffer_manager").marks


local M = {}

Buffer_manager_win_id = nil
Buffer_manager_bufh = nil
local initial_marks = {}
local config = buffer_manager.get_config()

-- We save before we close because we use the state of the buffer as the list
-- of items.
local function close_menu(force_save)
  force_save = force_save or false

  vim.api.nvim_win_close(Buffer_manager_win_id, true)

  Buffer_manager_win_id = nil
  Buffer_manager_bufh = nil
end

local function create_window()
  log.trace("_create_window()")

  local width = 60
  local height = 10

  if config then
    if config.width ~= nil then
      if config.width <= 1 then
        local gwidth = vim.api.nvim_list_uis()[1].width
        width = math.floor(gwidth * config.width)
      else
        width = config.width
      end
    end

    if config.height ~= nil then
      if config.height <= 1 then
        local gheight = vim.api.nvim_list_uis()[1].height
        height = math.floor(gheight * config.height)
      else
        height = config.height
      end
    end
  end

  local borderchars = config.borderchars
  local bufnr = vim.api.nvim_create_buf(false, false)

  local win_config = {
    title = "Buffers",
    line = math.floor(((vim.o.lines - height) / 2) - 1),
    col = math.floor((vim.o.columns - width) / 2),
    minwidth = width,
    minheight = height,
    borderchars = borderchars,
  }
  local Buffer_manager_win_id, win = popup.create(bufnr, win_config)

  if config.highlight ~= "" then
    vim.api.nvim_set_option_value(
      "winhighlight",
      config.highlight,
      { win = win.border.win_id }
    )
  end

  return {
    bufnr = bufnr,
    win_id = Buffer_manager_win_id,
  }
end

local function string_starts(string, start)
  return string.sub(string, 1, string.len(start)) == start
end

local function can_be_deleted(bufname, bufnr)
  return (
    vim.api.nvim_buf_is_valid(bufnr)
    and (not string_starts(bufname, "term://"))
    and (not vim.bo[bufnr].modified)
    and bufnr ~= -1
  )
end


local function is_buffer_in_marks(bufnr)
  for _, mark in pairs(marks) do
    if mark.buf_id == bufnr then
      return true
    end
  end
  return false
end


local function get_mark_by_name(name, specific_marks)
  local ref_name = nil
  local current_short_fns = {}
  for _, mark in pairs(specific_marks) do
    ref_name = mark.filename
    if string_starts(mark.filename, "term://") then
      if config.short_term_names then
        ref_name = utils.get_short_term_name(mark.filename)
      end
    else
      if config.short_file_names then
        ref_name = utils.get_short_file_name(mark.filename, current_short_fns)
        current_short_fns[ref_name] = true
      elseif config.format_function then
        ref_name = config.format_function(mark.filename)
      else
        ref_name = utils.normalize_path(mark.filename)
      end
    end
    if name == ref_name then
      return mark
    end
  end
  return nil
end


local function update_buffers()
  -- Check deletions
  for _, mark in pairs(initial_marks) do
    if not is_buffer_in_marks(mark.buf_id) then
      if can_be_deleted(mark.filename, mark.buf_id) then
        vim.api.nvim_buf_clear_namespace(mark.buf_id, -1, 1, -1)
        vim.api.nvim_buf_delete(mark.buf_id, {})
      end
    end
  end

  -- Check additions
  for idx, mark in pairs(marks) do
    local bufnr = vim.fn.bufnr(mark.filename)
    -- Add buffer only if it does not already exist or if it is not listed
    if bufnr == -1 or vim.fn.buflisted(bufnr) ~= 1 then
      vim.cmd("badd " .. mark.filename)
      marks[idx].buf_id = vim.fn.bufnr(mark.filename)
    end
  end
end

local function remove_mark(idx)
  marks[idx] = nil
  if idx < #marks then
    for i = idx, #marks do
      marks[i] = marks[i + 1]
    end
  end
end

local function update_marks()
  -- Check if any buffer has been deleted
  -- If so, remove it from marks
  for idx, mark in pairs(marks) do
    if not utils.buffer_is_valid(mark.buf_id, mark.filename) then
      remove_mark(idx)
    end
  end
  -- Check if any buffer has been added
  -- If so, add it to marks
  for _, buf in pairs(vim.api.nvim_list_bufs()) do
    local bufname = vim.api.nvim_buf_get_name(buf)
    if utils.buffer_is_valid(buf, bufname) and not is_buffer_in_marks(buf) then
      table.insert(marks, {
        filename = bufname,
        buf_id = buf,
      })
    end
  end
end


local function set_menu_keybindings()
  vim.api.nvim_buf_set_keymap(
    Buffer_manager_bufh,
    "n",
    "q",
    "<Cmd>lua require('buffer_manager.ui').toggle_quick_menu()<CR>",
    { silent = true }
  )
  vim.api.nvim_buf_set_keymap(
    Buffer_manager_bufh,
    "n",
    "<ESC>",
    "<Cmd>lua require('buffer_manager.ui').toggle_quick_menu()<CR>",
    { silent = true }
  )
  for _, value in pairs(config.select_menu_item_commands) do
    vim.api.nvim_buf_set_keymap(
      Buffer_manager_bufh,
      "n",
      value.key,
      "<Cmd>lua require('buffer_manager.ui').select_menu_item('"..value.command.."')<CR>",
      {}
    )
  end
  vim.cmd(
    string.format(
      "autocmd BufModifiedSet <buffer=%s> set nomodified",
      Buffer_manager_bufh
    )
  )
  vim.cmd(
    "autocmd BufLeave <buffer> ++nested ++once silent"..
    " lua require('buffer_manager.ui').toggle_quick_menu()"
  )
  vim.cmd(
    string.format(
      "autocmd BufWriteCmd <buffer=%s>"..
      " lua require('buffer_manager.ui').on_menu_save()",
      Buffer_manager_bufh
    )
  )
  -- Go to file hitting its line number
  local str = config.line_keys
  for i = 1, #str do
    local c = str:sub(i,i)
    vim.api.nvim_buf_set_keymap(
      Buffer_manager_bufh,
      "n",
      c,
      string.format(
        "<Cmd>%s <bar> lua require('buffer_manager.ui')"..
        ".select_menu_item()<CR>",
        i
      ),
      {}
    )
  end
end


local function set_win_buf_options(contents, current_buf_line)
  vim.api.nvim_set_option_value("number", true, { win = Buffer_manager_win_id })
  for key, value in pairs(config.win_extra_options) do
    vim.api.nvim_set_option_value(key, value, { win = Buffer_manager_win_id })
  end
  vim.api.nvim_buf_set_name(Buffer_manager_bufh, "buffer_manager-menu")
  vim.api.nvim_buf_set_lines(Buffer_manager_bufh, 0, #contents, false, contents)
  vim.api.nvim_buf_set_option(Buffer_manager_bufh, "filetype", "buffer_manager")
  vim.api.nvim_buf_set_option(Buffer_manager_bufh, "buftype", "acwrite")
  vim.api.nvim_buf_set_option(Buffer_manager_bufh, "bufhidden", "delete")
  vim.cmd(string.format(":call cursor(%d, %d)", current_buf_line, 1))
end


function M.toggle_quick_menu()
  log.trace("toggle_quick_menu()")
  if Buffer_manager_win_id ~= nil and vim.api.nvim_win_is_valid(Buffer_manager_win_id) then
    if vim.api.nvim_buf_get_changedtick(vim.fn.bufnr()) > 0 then
      M.on_menu_save()
    end
    close_menu(true)
    update_buffers()
    return
  end
  local current_buf_id = -1
  if config.focus_alternate_buffer then
    current_buf_id = vim.fn.bufnr("#")
  else
    current_buf_id = vim.fn.bufnr()
  end

  local win_info = create_window()
  local contents = {}
  initial_marks = {}

  Buffer_manager_win_id = win_info.win_id
  Buffer_manager_bufh = win_info.bufnr

  update_marks()

  -- set initial_marks
  local current_buf_line = 1
  local line = 1
  local modfied_lines = {}
  local current_short_fns = {}
  for idx, mark in pairs(marks) do
    -- Add buffer only if it does not already exist
    if vim.fn.buflisted(mark.buf_id) ~= 1 then
      marks[idx] = nil
    else
      local current_mark = marks[idx]
      initial_marks[idx] = {
        filename = current_mark.filename,
        buf_id = current_mark.buf_id,
      }
      if vim.bo[current_mark.buf_id].modified then
        table.insert(modfied_lines, line)
      end
      if current_mark.buf_id == current_buf_id then
        current_buf_line = line
      end
      local display_filename = current_mark.filename
      if not string_starts(display_filename, "term://") then
        if config.short_file_names then
          display_filename = utils.get_short_file_name(display_filename, current_short_fns)
          current_short_fns[display_filename] = true
        elseif config.format_function then
          display_filename = config.format_function(display_filename)
        else
          display_filename = utils.normalize_path(display_filename)
        end
      else
        if config.short_term_names then
          display_filename = utils.get_short_term_name(display_filename)
        end
      end
      contents[line] = string.format("%s", display_filename)
      line = line + 1
    end
  end

  set_win_buf_options(contents, current_buf_line)
  set_menu_keybindings()
  for _, modified_line in pairs(modfied_lines) do
    vim.api.nvim_buf_add_highlight(
      Buffer_manager_bufh,
      -1,
      "BufferManagerModified",
      modified_line-1,
      0,
      -1
    )
  end
end



function M.select_menu_item(command)
  local idx = vim.fn.line(".")
  if vim.api.nvim_buf_get_changedtick(vim.fn.bufnr()) > 0 then
    M.on_menu_save()
  end
  close_menu(true)
  M.nav_file(idx, command)
  update_buffers()
end

local function get_menu_items()
  log.trace("_get_menu_items()")
  local lines = vim.api.nvim_buf_get_lines(Buffer_manager_bufh, 0, -1, true)
  local indices = {}

  for _, line in pairs(lines) do
    if not utils.is_white_space(line) then
      table.insert(indices, line)
    end
  end

  return indices
end

local function set_mark_list(new_list)
  log.trace("set_mark_list(): New list:", new_list)

  local original_marks = utils.deep_copy(marks)
  marks = {}
  for _, v in pairs(new_list) do
    if type(v) == "string" then
      local filename = v
      local buf_id = nil
      local current_mark = get_mark_by_name(filename, original_marks)
      if current_mark then
        filename = current_mark.filename
        buf_id = current_mark.buf_id
      else
        buf_id = vim.fn.bufnr(v)
      end
      table.insert(marks, {
        filename = filename,
        buf_id = buf_id,
      })
    end
  end
end

function M.on_menu_save()
  log.trace("on_menu_save()")
  set_mark_list(get_menu_items())
end

function M.nav_file(id, command)
  log.trace("nav_file(): Navigating to", id)
  update_marks()

  local mark = marks[id]
  if not mark then
    return
  end
  if command == nil or command == "edit" then
    local bufnr = vim.fn.bufnr(mark.filename)
    -- Check if buffer exists by filename
    if bufnr ~= -1 then
      vim.cmd("buffer " .. bufnr)
    else
      vim.cmd("edit " .. mark.filename)
    end
  else
    vim.cmd(command .. " " .. mark.filename)
  end
end

local function get_current_buf_line()
  local current_buf_id = vim.fn.bufnr()
  for idx, mark in pairs(marks) do
    if mark.buf_id == current_buf_id then
      return idx
    end
  end
  log.error("get_current_buf_line(): Could not find current buffer in marks")
  return -1
end

function M.nav_next()
  log.trace("nav_next()")
  update_marks()
  local current_buf_line = get_current_buf_line()
  if current_buf_line == -1 then
    return
  end
  local next_buf_line = current_buf_line + 1
  if next_buf_line > #marks then
    if config.loop_nav then
      M.nav_file(1)
    end
  else
    M.nav_file(next_buf_line)
  end
end

function M.nav_prev()
  log.trace("nav_prev()")
  update_marks()
  local current_buf_line = get_current_buf_line()
  if current_buf_line == -1 then
    return
  end
  local prev_buf_line = current_buf_line - 1
  if prev_buf_line < 1 then
    if config.loop_nav then
        M.nav_file(#marks)
    end
  else
    M.nav_file(prev_buf_line)
  end
end

function M.location_window(options)
  local default_options = {
    relative = "editor",
    style = "minimal",
    width = 30,
    height = 15,
    row = 2,
    col = 2,
  }
  options = vim.tbl_extend("keep", options, default_options)

  local bufnr = options.bufnr or vim.api.nvim_create_buf(false, true)
  local win_id = vim.api.nvim_open_win(bufnr, true, options)

  return {
    bufnr = bufnr,
    win_id = win_id,
  }
end

function M.save_menu_to_file(filename)
  log.trace("save_menu_to_file()")
  if filename == nil or filename == "" then
    filename = vim.fn.input("Enter filename: ")
    if filename == "" then
      return
    end
  end
  local file = io.open(filename, "w")
  if file == nil then
    log.error("save_menu_to_file(): Could not open file for writing")
    return
  end
  for _, mark in pairs(marks) do
    file:write(Path:new(mark.filename):absolute() .. "\n")
  end
  file:close()
end

function M.load_menu_from_file(filename)
  log.trace("load_menu_from_file()")
  if filename == nil or filename == "" then
    filename = vim.fn.input("Enter filename: ")
    if filename == "" then
      return
    end
  end
  local file = io.open(filename, "r")
  if file == nil then
    log.error("load_menu_from_file(): Could not open file for reading")
    return
  end
  local lines = {}
  for line in file:lines() do
    table.insert(lines, line)
  end
  file:close()
  set_mark_list(lines)
  update_buffers()
end


return M

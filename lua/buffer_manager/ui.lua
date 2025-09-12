local Path = require("plenary.path")
local bm = require("buffer_manager")
local popup = require("plenary.popup")
local utils = require("buffer_manager.utils")
local log = require("buffer_manager.dev").log


local version_info = vim.inspect(vim.version())
local version_minor = tonumber(version_info:match("minor = (%d+)"))

local ns_mod = vim.api.nvim_create_namespace("BufferManagerModified")
local ns_ind = vim.api.nvim_create_namespace("BufferManagerIndicator")
local ns_short = vim.api.nvim_create_namespace("BufferManagerShortcut")


local function copy_hl(hl)
  return {
    fg = hl.fg,
    bg = hl.bg,
    sp = hl.sp,
    bold = hl.bold,
    italic = hl.italic,
    underline = hl.underline,
    undercurl = hl.undercurl,
    reverse = hl.reverse,
    standout = hl.standout,
    strikethrough = hl.strikethrough,
    nocombine = hl.nocombine,
  }
end

-- Check if highlight groups exist, if not, create them
if vim.fn.hlexists("BufferManagerModified") == 0 then
  -- If the hl group does not exist, just set it to bold
  vim.api.nvim_set_hl(0, 'BufferManagerModified', { bold = true })
end
if vim.fn.hlexists("BufferManagerIndicator") == 0 then
  -- If the hl group does not exist, copy the Comment hl group
  local hl = vim.api.nvim_get_hl(0, { name = "Comment" })
  vim.api.nvim_set_hl(0, 'BufferManagerIndicator', copy_hl(hl))
end
if vim.fn.hlexists("BufferManagerShortcut") == 0 then
  -- If the hl group does not exist, just set it to bold and underline
  vim.api.nvim_set_hl(0, 'BufferManagerShortcut', { bold = true, underline = true })
end

local M = {}

Buffer_manager_win_id = nil
Buffer_manager_bufh = nil
local initial_marks = {}
local config = bm.get_config()

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


local function can_be_deleted(bufname, bufnr)
  return (
    vim.api.nvim_buf_is_valid(bufnr)
    and (not utils.string_starts(bufname, "term://"))
    and (not vim.bo[bufnr].modified)
    and bufnr ~= -1
  )
end


local function is_buffer_in_marks(bufnr)
  for _, mark in pairs(bm.marks) do
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
    ref_name = mark.buf_name
    if utils.string_starts(mark.buf_name, "term://") then
      if config.short_term_names then
        ref_name = utils.get_short_term_name(mark.buf_name)
      end
    else
      if config.short_file_names then
        ref_name = utils.get_short_file_name(mark.buf_name, current_short_fns)
        current_short_fns[ref_name] = true
      elseif config.format_function then
        ref_name = config.format_function(mark.buf_name)
      else
        ref_name = utils.normalize_path(mark.buf_name)
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
      if can_be_deleted(mark.buf_name, mark.buf_id) then
        vim.api.nvim_buf_clear_namespace(mark.buf_id, -1, 1, -1)
        vim.api.nvim_buf_delete(mark.buf_id, {})
      end
    end
  end

  -- Check additions
  for idx, mark in pairs(bm.marks) do
    local bufnr = vim.fn.bufnr(mark.buf_name)
    -- Add buffer only if it does not already exist or if it is not listed
    if bufnr == -1 or vim.fn.buflisted(bufnr) ~= 1 then
      vim.cmd("badd " .. mark.buf_name)
      bm.marks[idx].buf_id = vim.fn.bufnr(mark.buf_name)
      bm.marks[idx].shortcut = utils.assign_shortcut(bm.marks, mark.buf_name)
    end
  end
end

local function remove_mark(idx)
  bm.marks[idx] = nil
  if idx < #bm.marks then
    for i = idx, #bm.marks do
      bm.marks[i] = bm.marks[i + 1]
    end
  end
end


local function order_buffers()
  if utils.string_starts(config.order_buffers, "filename") then
    table.sort(bm.marks, function(a, b)
      local a_name = string.lower(utils.get_file_name(a.buf_name))
      local b_name = string.lower(utils.get_file_name(b.buf_name))
      return a_name < b_name
    end)
  elseif utils.string_starts(config.order_buffers, "fullpath") then
    table.sort(bm.marks, function(a, b)
      local a_name = string.lower(a.buf_name)
      local b_name = string.lower(b.buf_name)
      return a_name < b_name
    end)
  elseif utils.string_starts(config.order_buffers, "bufnr") then
    table.sort(bm.marks, function(a, b)
      return a.buf_id < b.buf_id
    end)
  elseif utils.string_starts(config.order_buffers, "lastused") then
    table.sort(bm.marks, function(a, b)
      local a_lastused = vim.fn.getbufinfo(a.buf_id)[1].lastused
      local b_lastused = vim.fn.getbufinfo(b.buf_id)[1].lastused
      if a_lastused == b_lastused then
        return a.buf_id < b.buf_id
      else
        return a_lastused > b_lastused
      end
    end)
  end
  if utils.string_ends(config.order_buffers, "reverse") then
    -- Reverse the order of the marks
    local reversed_marks = {}
    for i = #bm.marks, 1, -1 do
      table.insert(reversed_marks, bm.marks[i])
    end
    bm.marks = reversed_marks
  end
end


function M.update_marks()
  -- Check if any buffer has been deleted
  -- If so, remove it from marks
  for idx, mark in pairs(bm.marks) do
    if not utils.buffer_is_valid(mark.buf_id, mark.buf_name) then
      remove_mark(idx)
    end
  end
  -- Check if any buffer has been added
  -- If so, add it to marks
  for _, buf in pairs(vim.api.nvim_list_bufs()) do
    local bufname = vim.api.nvim_buf_get_name(buf)
    if utils.buffer_is_valid(buf, bufname) and not is_buffer_in_marks(buf) then
      table.insert(bm.marks, {
        buf_name = bufname,
        buf_id = buf,
        shortcut = utils.assign_shortcut(bm.marks, bufname),
      })
    end
  end
  -- Order the buffers, if the option is set
  if config.order_buffers then
    order_buffers()
  end
end


local function set_menu_keybindings()
  for _, key in pairs(config.toggle_key_bindings) do
    vim.api.nvim_buf_set_keymap(
      Buffer_manager_bufh,
      "n",
      key,
      "<Cmd>lua require('buffer_manager.ui').toggle_quick_menu()<CR>",
      { silent = true }
    )
  end
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
  -- Go to file hitting its line key
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
  -- Go to file hitting its shortcut key
  if config.use_shortcuts then
    for idx, mark in pairs(bm.marks) do
      if mark.shortcut then
        vim.api.nvim_buf_set_keymap(
          Buffer_manager_bufh,
          "n",
          mark.shortcut,
          string.format(
            "<Cmd>%s <bar> lua require('buffer_manager.ui')"..
            ".select_menu_item()<CR>",
            idx
          ),
          {noremap = true, silent = true, nowait = true}
        )
      end
    end
    -- Add keybinding "e" to start editing mode and unmap the previous keybindings
    vim.api.nvim_buf_set_keymap(
      Buffer_manager_bufh,
      "n",
      "e",
      "<Cmd>lua require('buffer_manager.ui').unmap_shortcuts()<CR>",
      { noremap = true, silent = true }
    )
  end
end


function M.unmap_shortcuts()
  for _, mark in pairs(bm.marks) do
    if mark.shortcut then
      vim.api.nvim_buf_del_keymap(Buffer_manager_bufh, "n", mark.shortcut)
    end
  end
  vim.api.nvim_buf_del_keymap(Buffer_manager_bufh, "n", "e")
end


local function set_win_buf_options(contents, current_buf_line)
  vim.api.nvim_set_option_value("number", true, { win = Buffer_manager_win_id })
  for key, value in pairs(config.win_extra_options) do
    vim.api.nvim_set_option_value(key, value, { win = Buffer_manager_win_id })
  end
  vim.api.nvim_buf_set_name(Buffer_manager_bufh, "buffer_manager-menu")
  vim.api.nvim_buf_set_lines(Buffer_manager_bufh, 0, #contents, false, contents)
  -- Set functions depending on Neovim version
  if version_minor > 9 then
    vim.api.nvim_set_option_value(
      "filetype",
      "buffer_manager",
      { buf = Buffer_manager_bufh }
    )
    vim.api.nvim_set_option_value(
      "buftype",
      "acwrite",
      { buf = Buffer_manager_bufh }
    )
    vim.api.nvim_set_option_value(
      "bufhidden",
      "delete",
      { buf = Buffer_manager_bufh }
    )
  else
    vim.api.nvim_buf_set_option(Buffer_manager_bufh, "filetype", "buffer_manager")
    vim.api.nvim_buf_set_option(Buffer_manager_bufh, "buftype", "acwrite")
    vim.api.nvim_buf_set_option(Buffer_manager_bufh, "bufhidden", "delete")
  end
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
  local real_alternate_buf = vim.fn.bufnr("#")
  local real_current_buf = vim.fn.bufnr()

  local win_info = create_window()
  local contents = {}
  initial_marks = {}

  Buffer_manager_win_id = win_info.win_id
  Buffer_manager_bufh = win_info.bufnr

  M.update_marks()

  -- set initial_marks
  local current_buf_line = 1
  local line = 1
  local current_short_fns = {}
  for idx, mark in pairs(bm.marks) do
    -- Add buffer only if it does not already exist
    if vim.fn.buflisted(mark.buf_id) ~= 1 then
      bm.marks[idx] = nil
    else
      local current_mark = bm.marks[idx]
      -- Marks contain the absolute path, the buffer id and the shortcut char
      initial_marks[idx] = {
        buf_name = current_mark.buf_name,
        buf_id = current_mark.buf_id,
        shortcut = current_mark.shortcut,
      }
      if current_mark.buf_id == current_buf_id then
        current_buf_line = line
      end
      local display_name = current_mark.buf_name
      if not utils.string_starts(display_name, "term://") then
        if config.short_file_names then
          display_name = utils.get_short_file_name(display_name, current_short_fns)
          current_short_fns[display_name] = true
        elseif config.format_function then
          display_name = config.format_function(display_name)
        else
          display_name = utils.normalize_path(display_name)
        end
      else
        if config.short_term_names then
          display_name = utils.get_short_term_name(display_name)
        end
      end
      if config.show_indicators == 'before' then
         contents[line] = string.format("      %s", display_name)
      else
         contents[line] = string.format("%s", display_name)
      end
      line = line + 1
    end
  end

  set_win_buf_options(contents, current_buf_line)
  set_menu_keybindings()

  -- Indicators (chars in the same column are mutually exclusive):
  -- u       an unlisted buffer (only displayed when [!] is used)
  --        |unlisted-buffer|
  --  %     the buffer in the current window
  --  #     the alternate buffer for ":e #" and CTRL-^
  --   a    an active buffer: it is loaded and visible
  --   h    a hidden buffer: It is loaded, but currently not
  --        displayed in a window |hidden-buffer|
  --    -   a buffer with 'modifiable' off
  --    =   a readonly buffer
  --    R   a terminal buffer with a running job
  --    F   a terminal buffer with a finished job
  --    ?   a terminal buffer without a job: `:terminal NONE`
  --     +  a modified buffer
  --     x  a buffer with read errors
  -- Also highlight shortcut chars and modified buffers
  local bufs_list = vim.api.nvim_list_bufs()
  for idx, mark in pairs(bm.marks) do
    if mark.shortcut and config.use_shortcuts then
      local file_name = utils.get_file_name(contents[idx])
      local dir_name = utils.get_dir_name(contents[idx])
      -- Char pos is dir_name + 1 (for the /) + position of the shortcut in the
      -- line.
      -- Check if dir_name is nil
      if dir_name == nil then
        dir_name = ""
      end
      local char_pos = #dir_name + string.lower(file_name):find(mark.shortcut, 1, true)
      if char_pos then
        if version_minor > 9 then
          vim.hl.range(
            Buffer_manager_bufh,
            ns_short,
            "BufferManagerShortcut",
            {idx-1, char_pos - 1},
            {idx-1, char_pos},
            {}
          )
        else
          vim.api.nvim_buf_add_highlight(
            Buffer_manager_bufh,
            -1,
            "BufferManagerShortcut",
            idx-1,
            char_pos - 1,
            char_pos
          )
        end
      end
    end
    for _, ibuf in pairs(bufs_list) do
      if mark.buf_id == ibuf then
        local indicators = "     "
        local buflisted
        local modifiable
        local modified
        local readonly
        local buftype
        local terminal_job_id
        if version_minor > 9 then
          buflisted = vim.api.nvim_get_option_value("buflisted", { buf = ibuf })
          modifiable = vim.api.nvim_get_option_value("modifiable", { buf = ibuf })
          modified = vim.api.nvim_get_option_value("modified", { buf = ibuf })
          readonly = vim.api.nvim_get_option_value("readonly", { buf = ibuf })
          buftype = vim.api.nvim_get_option_value("buftype", { buf = ibuf })
        else
          buflisted = vim.api.nvim_buf_get_option(ibuf, "buflisted")
          modifiable = vim.api.nvim_buf_get_option(ibuf, "modifiable")
          modified = vim.api.nvim_buf_get_option(ibuf, "modified")
          readonly = vim.api.nvim_buf_get_option(ibuf, "readonly")
          buftype = vim.api.nvim_buf_get_option(ibuf, "buftype")
        end
        if not buflisted then
          indicators = utils.replace_char(indicators, 1, "u")
        end
        if ibuf == real_current_buf then
          indicators = utils.replace_char(indicators, 2, "%")
        elseif ibuf == real_alternate_buf then
          indicators = utils.replace_char(indicators, 2, "#")
        end
        if vim.tbl_count(vim.fn.win_findbuf(ibuf)) ~= 0 then
          indicators = utils.replace_char(indicators, 3, "a")
        elseif vim.api.nvim_buf_is_loaded(ibuf) then
          indicators = utils.replace_char(indicators, 3, "h")
        end
        if not modifiable then
          indicators = utils.replace_char(indicators, 4, "-")
        elseif readonly then
          indicators = utils.replace_char(indicators, 4, "=")
        elseif buftype == "terminal" then
          if version_minor > 9 then
            terminal_job_id = vim.api.nvim_get_option_value("terminal_job_id", { buf = ibuf })
          else
            terminal_job_id = vim.api.nvim_buf_get_option(ibuf, "terminal_job_id")
          end
          if terminal_job_id then
            indicators = utils.replace_char(indicators, 4, "R")
          elseif terminal_job_id == 0 then
            indicators = utils.replace_char(indicators, 4, "F")
          else
            indicators = utils.replace_char(indicators, 4, "?")
          end
        end
        if modified then
          indicators = utils.replace_char(indicators, 5, "+")
          if version_minor > 9 then
            vim.hl.range(
              Buffer_manager_bufh,
              ns_mod,
              "BufferManagerModified",
              {idx-1, 0},
              {idx-1, -1},
              {}
            )
          else
            vim.api.nvim_buf_add_highlight(
              Buffer_manager_bufh,      -- buffer: integer,
              -1,                       -- ns_id: integer,
              "BufferManagerModified",  -- hl_group: string,
              idx-1,                    -- line: integer,
              0,                        -- col_start: integer,
              -1                        -- col_end: integer
            )
          end
        end
        -- TODO: Add read errors indicator

        if config.show_indicators then
          local virt_text_pos = "eol"
          if config.show_indicators == "before" then
            virt_text_pos = "overlay"
          end
          vim.api.nvim_buf_set_extmark(
            Buffer_manager_bufh,
            ns_ind,
            idx - 1,
            0,
            {
              virt_text = { { indicators, "BufferManagerIndicator" } },
              -- Position: beginning of line, with padding
              virt_text_pos = virt_text_pos,
              hl_mode = "combine",
            }
          )
        end
      end
    end
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
      -- Strip leading spaces from line
      line = line:gsub("^%s+", "")
      table.insert(indices, line)
    end
  end

  return indices
end


local function set_mark_list(new_list)
  log.trace("set_mark_list(): New list:", new_list)

  local original_marks = utils.deep_copy(bm.marks)
  bm.marks = {}
  for _, v in pairs(new_list) do
    if type(v) == "string" then
      local buf_name = v
      local buf_id = nil
      local shortcut = nil
      local current_mark = get_mark_by_name(buf_name, original_marks)
      if current_mark then
        buf_name = current_mark.buf_name
        buf_id = current_mark.buf_id
        shortcut = current_mark.shortcut
      else
        buf_id = vim.fn.bufnr(v)
        shortcut = utils.assign_shortcut(bm.marks, buf_name)
      end
      table.insert(bm.marks, {
        buf_name = buf_name,
        buf_id = buf_id,
        shortcut = shortcut,
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
  M.update_marks()

  local mark = bm.marks[id]
  if not mark then
    return
  end
  if command == nil or command == "edit" then
    local bufnr = vim.fn.bufnr(mark.buf_name)
    -- Check if buffer exists by buffer name
    if bufnr ~= -1 then
      vim.cmd("buffer " .. bufnr)
    else
      vim.cmd("edit " .. mark.buf_name)
    end
  else
    vim.cmd(command .. " " .. mark.buf_name)
  end
end

local function get_current_buf_line()
  local current_buf_id = vim.fn.bufnr()
  for idx, mark in pairs(bm.marks) do
    if mark.buf_id == current_buf_id then
      return idx
    end
  end
  -- If the current buffer has `nobuflisted` set, it will not appear in the buffer list.
  -- To get around this, we return 0 here to allow the `nav_next` and `nav_prev` functionality
  -- to continue working as normal. This is especially needed for the vim intro screen and
  -- for custom dashboards that are not included in the buffer list.
  return 0
end


function M.nav_next()
  log.trace("nav_next()")
  M.update_marks()
  local current_buf_line = get_current_buf_line()
  local next_buf_line = current_buf_line + 1
  if next_buf_line > #bm.marks then
    if config.loop_nav then
      M.nav_file(1)
    end
  else
    M.nav_file(next_buf_line)
  end
end


function M.nav_prev()
  log.trace("nav_prev()")
  M.update_marks()
  local current_buf_line = get_current_buf_line()
  local prev_buf_line = current_buf_line - 1
  if prev_buf_line < 1 then
    if config.loop_nav then
        M.nav_file(#bm.marks)
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


function M.save_menu_to_file(path)
  log.trace("save_menu_to_file()")
  if path == nil or path == "" then
    path = vim.fn.input("Enter file path: ")
    if path == "" then
      return
    end
  end
  local file = io.open(path, "w")
  if file == nil then
    log.error("save_menu_to_file(): Could not open file for writing")
    return
  end
  for _, mark in pairs(bm.marks) do
    file:write(Path:new(mark.buf_name):absolute() .. "\n")
  end
  file:close()
end


function M.load_menu_from_file(path)
  log.trace("load_menu_from_file()")
  if path == nil or path == "" then
    path = vim.fn.input("Enter file path: ")
    if path == "" then
      return
    end
  end
  local file = io.open(path, "r")
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

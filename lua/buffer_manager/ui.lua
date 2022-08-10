local buffer_manager = require("buffer_manager")
local popup = require("plenary.popup")
local utils = require("buffer_manager.utils")
local log = require("buffer_manager.dev").log
local marks = require("buffer_manager").marks


local M = {}

Buffer_manager_win_id = nil
Buffer_manager_bufh = nil
local initial_marks = nil

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
    local config = buffer_manager.get_config()
    local width = config.width or 60
    local height = config.height or 10
    local borderchars = config.borderchars
        or { "─", "│", "─", "│", "╭", "╮", "╯", "╰" }
    local bufnr = vim.api.nvim_create_buf(false, false)

    local Buffer_manager_win_id, win = popup.create(bufnr, {
        title = "Buffers",
        highlight = "BufferManagerWindow",
        line = math.floor(((vim.o.lines - height) / 2) - 1),
        col = math.floor((vim.o.columns - width) / 2),
        minwidth = width,
        minheight = height,
        borderchars = borderchars,
    })

    vim.api.nvim_win_set_option(
        win.border.win_id,
        "winhl",
        "Normal:BufferManagerBorder"
    )

    return {
        bufnr = bufnr,
        win_id = Buffer_manager_win_id,
    }
end


function update_buffers()

    -- Check deletions
    for idx_i = 1, #initial_marks do
        local to_delete = true
        for idx_j = 1, #marks do
            if initial_marks[idx_i].filename == marks[idx_j].filename then
                to_delete = false
            end
        end
        if to_delete then
            local bufnr = vim.fn.bufnr(initial_marks[idx_i].filename)
            if bufnr ~= -1 then
                if vim.api.nvim_buf_is_valid(bufnr) then
                    vim.api.nvim_buf_delete(bufnr, {})
                end
            end
        end
    end

    -- Check additions
    for idx = 1, #marks do
        vim.api.nvim_command("badd " .. marks[idx].filename)
    end
end


function M.toggle_quick_menu()
    log.trace("toggle_quick_menu()")
    local current_buf_id = 0
    if Buffer_manager_win_id ~= nil and vim.api.nvim_win_is_valid(Buffer_manager_win_id) then
        if vim.api.nvim_buf_get_changedtick(vim.fn.bufnr()) > 0 then
            M.on_menu_save()
        end
        close_menu(true)
        update_buffers()
        return
    else
        current_buf_id = vim.fn.bufnr()
    end

    local win_info = create_window()
    local contents = {}
    initial_marks = {}

    Buffer_manager_win_id = win_info.win_id
    Buffer_manager_bufh = win_info.bufnr

    local buffers = vim.api.nvim_list_bufs()

    local len = 0
    local current_buf_line = 1
    for idx = 1, #buffers do
        local buf_id = buffers[idx]
        local buf_name = vim.api.nvim_buf_get_name(buf_id)
        local filename = utils.normalize_path(buf_name)
        -- if buffer is listed, then add to contents and marks
        if 1 == vim.fn.buflisted(buf_id) and buf_name ~= "" then
            len = len + 1
            if buf_id == current_buf_id then
                current_buf_line = len
            end
            marks[len] = {
                filename = filename,
            }
            initial_marks[len] ={
                filename = filename,
            }
            contents[len] = string.format("%s", filename)
        end
    end

    vim.api.nvim_win_set_option(Buffer_manager_win_id, "number", true)
    vim.api.nvim_buf_set_name(Buffer_manager_bufh, "buffer_manager-menu")
    vim.api.nvim_buf_set_lines(Buffer_manager_bufh, 0, #contents, false, contents)
    vim.api.nvim_buf_set_option(Buffer_manager_bufh, "filetype", "buffer_manager")
    vim.api.nvim_buf_set_option(Buffer_manager_bufh, "buftype", "acwrite")
    vim.api.nvim_buf_set_option(Buffer_manager_bufh, "bufhidden", "delete")
    vim.cmd(string.format(":call cursor(%d, %d)", current_buf_line, 1))
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
    vim.api.nvim_buf_set_keymap(
        Buffer_manager_bufh,
        "n",
        "<CR>",
        "<Cmd>lua require('buffer_manager.ui').select_menu_item()<CR>",
        {}
    )
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
    vim.cmd(
        "setlocal completeopt=noinsert,menuone,noselect"
    )
    vim.cmd(
        "inoremap <buffer> <Tab> <C-x><C-f>"
    )
    -- Go to file hitting its line number
    local str = "1234567890"
    for i = 1, #str do
        local c = str:sub(i,i)
        local line = c
        if c == "0" then
            line = "10"
        end
        vim.api.nvim_buf_set_keymap(
            Buffer_manager_bufh,
            "n",
            c,
            string.format(
                "<Cmd>%s <bar> lua require('buffer_manager.ui')"..
                ".select_menu_item()<CR>",
                line
            ),
            {}
        )
    end
end

function M.select_menu_item()
    local idx = vim.fn.line(".")
    if vim.api.nvim_buf_get_changedtick(vim.fn.bufnr()) > 0 then
        M.on_menu_save()
    end
    close_menu(true)
    M.nav_file(idx)
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

    marks = {}
    -- Check additions
    for line, v in pairs(new_list) do
        if type(v) == "string" then
            marks[line] = {
                filename = v
            }
        end
    end
end

function M.on_menu_save()
    log.trace("on_menu_save()")
    set_mark_list(get_menu_items())
end

function M.nav_file(id)
    log.trace("nav_file(): Navigating to", id)

    local mark = marks[id]
    if not mark then
        return
    else
        vim.cmd("edit " .. mark.filename)
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


return M

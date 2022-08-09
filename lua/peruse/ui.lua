local peruse = require("peruse")
local popup = require("plenary.popup")
local utils = require("peruse.utils")
local log = require("peruse.dev").log
local marks = require("peruse").marks

local M = {}

Peruse_win_id = nil
Peruse_bufh = nil

-- We save before we close because we use the state of the buffer as the list
-- of items.
local function close_menu(force_save)
    force_save = force_save or false

    vim.api.nvim_win_close(Peruse_win_id, true)

    Peruse_win_id = nil
    Peruse_bufh = nil
end

local function create_window()
    log.trace("_create_window()")
    local config = peruse.get_config()
    local width = config.width or 60
    local height = config.height or 10
    local borderchars = config.borderchars
        or { "─", "│", "─", "│", "╭", "╮", "╯", "╰" }
    local bufnr = vim.api.nvim_create_buf(false, false)

    local Peruse_win_id, win = popup.create(bufnr, {
        title = "Buffers",
        highlight = "PeruseWindow",
        line = math.floor(((vim.o.lines - height) / 2) - 1),
        col = math.floor((vim.o.columns - width) / 2),
        minwidth = width,
        minheight = height,
        borderchars = borderchars,
    })

    vim.api.nvim_win_set_option(
        win.border.win_id,
        "winhl",
        "Normal:PeruseBorder"
    )

    return {
        bufnr = bufnr,
        win_id = Peruse_win_id,
    }
end


function M.toggle_quick_menu()
    log.trace("toggle_quick_menu()")
    local current_buf_id = 0
    if Peruse_win_id ~= nil and vim.api.nvim_win_is_valid(Peruse_win_id) then
        close_menu()
        return
    else
        current_buf_id = vim.fn.bufnr()
    end

    local win_info = create_window()
    local contents = {}

    Peruse_win_id = win_info.win_id
    Peruse_bufh = win_info.bufnr

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
            contents[len] = string.format("%s", filename)
        end
    end

    vim.api.nvim_win_set_option(Peruse_win_id, "number", true)
    vim.api.nvim_buf_set_name(Peruse_bufh, "peruse-menu")
    vim.api.nvim_buf_set_lines(Peruse_bufh, 0, #contents, false, contents)
    vim.api.nvim_buf_set_option(Peruse_bufh, "filetype", "peruse")
    vim.api.nvim_buf_set_option(Peruse_bufh, "buftype", "acwrite")
    vim.api.nvim_buf_set_option(Peruse_bufh, "bufhidden", "delete")
    vim.cmd(string.format(":call cursor(%d, %d)", current_buf_line, 1))
    vim.api.nvim_buf_set_keymap(
        Peruse_bufh,
        "n",
        "q",
        "<Cmd>lua require('peruse.ui').toggle_quick_menu()<CR>",
        { silent = true }
    )
    vim.api.nvim_buf_set_keymap(
        Peruse_bufh,
        "n",
        "<ESC>",
        "<Cmd>lua require('peruse.ui').toggle_quick_menu()<CR>",
        { silent = true }
    )
    vim.api.nvim_buf_set_keymap(
        Peruse_bufh,
        "n",
        "<CR>",
        "<Cmd>lua require('peruse.ui').select_menu_item()<CR>",
        {}
    )
    vim.cmd(
        string.format(
            "autocmd BufModifiedSet <buffer=%s> set nomodified",
            Peruse_bufh
        )
    )
    vim.cmd(
        "autocmd BufLeave <buffer> ++nested ++once silent"..
        " lua require('peruse.ui').toggle_quick_menu()"
    )
    vim.cmd(
        string.format(
            "autocmd BufWriteCmd <buffer=%s>"..
            " lua require('peruse.ui').on_menu_save()",
            Peruse_bufh
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
            Peruse_bufh,
            "n",
            c,
            string.format(
                "<Cmd>%s <bar> lua require('peruse.ui')"..
                ".select_menu_item()<CR>",
                line
            ),
            {}
        )
    end
end

function M.select_menu_item()
    local idx = vim.fn.line(".")
    close_menu(true)
    M.nav_file(idx)
end

local function get_menu_items()
    log.trace("_get_menu_items()")
    local lines = vim.api.nvim_buf_get_lines(Peruse_bufh, 0, -1, true)
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

    local new_marks = {}
    -- Check additions
    for line, v in pairs(new_list) do
        if type(v) == "string" then
            local was_added = true
            for idx = 1, #marks do
                if marks[idx].filename == v then
                    was_added = false
                end
            end
            if was_added then
                vim.api.nvim_command("badd " .. v)
            end
            new_marks[line] = {
                filename = v
            }
        end
    end

    -- Check deletions
    for idx = 1, #marks do
        local to_delete = true
        for _, v in pairs(new_list) do
            if marks[idx].filename == v then
                to_delete = false
            end
        end
        if to_delete then
            vim.cmd("bdelete " .. marks[idx].filename)
        end
    end
    marks = new_marks
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

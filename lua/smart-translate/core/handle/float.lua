local float = {}

local manager = {}
local cache_scrolloff = vim.opt.scrolloff:get()

local function footer_handle(winner, bufnr)
    local cursor_line = vim.fn.line(".", winner)
    local buffer_total_line = vim.api.nvim_buf_line_count(bufnr)
    local window_height = vim.api.nvim_win_get_height(winner)
    local window_last_line = vim.fn.line("w$", winner)

    local progress = math.floor(window_last_line / buffer_total_line * 100)

    if buffer_total_line <= window_height + 1 then
        return
    end

    if cursor_line == 1 then
        progress = 0
    end

    local footer = ("%s%%"):format(progress)

    vim.api.nvim_win_set_config(winner, {
        footer = footer,
        footer_pos = "right",
    })
end

local function scroll_hover(count, winner, bufnr)
    local cursor_line = vim.fn.line(".", winner)
    local buffer_line_count = vim.api.nvim_buf_line_count(bufnr)
    local window_head_line = vim.fn.line("w0", winner)
    local window_last_line = vim.fn.line("w$", winner)

    vim.opt.scrolloff = 0

    if count > 0 then
        if cursor_line < window_last_line then
            local target = math.min(window_last_line + count, buffer_line_count)
            vim.api.nvim_win_set_cursor(winner, { target, 0 })
        else
            local target = math.min(cursor_line + count, buffer_line_count)
            vim.api.nvim_win_set_cursor(winner, { target, 0 })
        end
        footer_handle(winner, bufnr)
    else
        if cursor_line > window_head_line then
            local target = math.max(window_head_line + count, 1)
            vim.api.nvim_win_set_cursor(winner, { target, 0 })
        else
            local target = math.max(cursor_line + count, 1)
            vim.api.nvim_win_set_cursor(winner, { target, 0 })
        end

        footer_handle(winner, bufnr)
    end

    vim.opt.scrolloff = cache_scrolloff
end

local function scroll_or_fallback(count, winner, bufnr)
    if vim.api.nvim_win_is_valid(winner) then
        scroll_hover(count, winner, bufnr)
        return ""
    end

    local key = count > 0 and "<c-f>" or "<c-b>"
    return vim.api.nvim_replace_termcodes(key, true, false, true)
end

---Editor-relative position of the float: anchored to the selected text when
---it is visible, otherwise to the cursor.
---@param translator SmartTranslate.Translator
---@return table
local function float_position(translator)
    local first, last = translator.range[1], translator.range[#translator.range]

    if first and vim.api.nvim_win_is_valid(translator.window) then
        -- screenpos() is 1-based and accounts for wrapped lines and folds
        local start_pos = vim.fn.screenpos(
            translator.window,
            first.lnum,
            math.max(first.scol, 1)
        )
        local end_pos = vim.fn.screenpos(
            translator.window,
            last.lnum,
            math.max(last.ecol, 1)
        )

        if start_pos.row > 0 and end_pos.row > 0 then
            return {
                relative = "editor",
                -- 0-based screen row just below / just above the selection
                below = end_pos.row,
                above = start_pos.row - 1,
                col = start_pos.col - 1,
            }
        end
    end

    local cursor = vim.api.nvim_win_get_cursor(0)
    local pos = vim.fn.screenpos(0, cursor[1], cursor[2] + 1)
    return {
        relative = "editor",
        below = pos.row,
        above = pos.row - 1,
        col = math.max(pos.col - 1, 0),
    }
end

---@param translator SmartTranslate.Translator
function float.render(translator)
    local title = "SmartTranslate(cache)"

    if not translator.use_cache_translation then
        title = ("SmartTranslate(%s)"):format(translator.engine)
    end

    -- strdisplaywidth() returns the number of screen cells a string occupies
    -- (CJK and other wide characters take 2 cells, tabs expand), unlike `#`
    -- which counts bytes, so the window width matches what is rendered
    local width = vim.fn.strdisplaywidth(title)
    for _, l in ipairs(translator.translation) do
        width = math.max(width, vim.fn.strdisplaywidth(l))
    end

    -- When the display length is not long enough to display the title, we will hide the title
    if
        #translator.translation == 1
        and vim.fn.strdisplaywidth(translator.translation[1]) < width
    then
        title = ""
        width = vim.fn.strdisplaywidth(translator.translation[1])
    end

    local win_config = float_position(translator)
    -- Keep the window (plus its border) within the editor, long lines are wrapped;
    -- shift it left rather than squeezing it when the selection is near the right edge
    width = math.max(1, math.min(width, vim.o.columns - 2))
    win_config.col =
        math.max(0, math.min(win_config.col, vim.o.columns - width - 2))

    -- Height counted in screen rows after wrapping
    local height = 0
    for _, l in ipairs(translator.translation) do
        height = height
            + math.max(1, math.ceil(vim.fn.strdisplaywidth(l) / width))
    end
    height = math.min(height, math.floor(vim.o.lines * 3 / 4))

    -- Place below the selection, or above it when there is not enough room below
    local editor_height = vim.o.lines - vim.o.cmdheight
    if
        win_config.below + height + 2 > editor_height
        and win_config.above - height - 2 >= 0
    then
        win_config.row = win_config.above
        win_config.anchor = "SW"
    else
        win_config.row = win_config.below
        win_config.anchor = "NW"
    end
    win_config.below, win_config.above = nil, nil

    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, translator.translation)
    vim.bo[bufnr].filetype = "translate-float"

    local winner = vim.api.nvim_open_win(
        bufnr,
        false,
        vim.tbl_extend("force", win_config, {
            width = width,
            height = height,
            title = title,
            title_pos = "center",
            style = "minimal",
            border = "rounded",
            focusable = false,
            zindex = 200,
        })
    )
    vim.wo[winner].wrap = true
    vim.wo[winner].linebreak = true

    footer_handle(winner, bufnr)

    -- Page turning system, restore the default function of <c-f> <c-b> when any key is pressed
    vim.keymap.set({ "n" }, "<c-f>", function()
        return scroll_or_fallback(5, winner, bufnr)
    end, { expr = true, silent = true, buffer = 0 })

    vim.keymap.set({ "n" }, "<c-b>", function()
        return scroll_or_fallback(-5, winner, bufnr)
    end, { expr = true, silent = true, buffer = 0 })

    table.insert(manager, winner)
    vim.on_key(function(_, keystr)
        local key = vim.fn.keytrans(keystr):lower()
        if key ~= "" and key ~= "<c-f>" and key ~= "<c-b>" then
            local manager_copy = vim.deepcopy(manager)

            for index, winid in ipairs(manager_copy) do
                if vim.api.nvim_win_is_valid(winid) then
                    vim.api.nvim_win_close(winid, false)
                end

                table.remove(manager, index)
            end

            vim.on_key(nil, translator.namespace)
            vim.api.nvim_buf_del_keymap(0, "n", "<c-f>")
            vim.api.nvim_buf_del_keymap(0, "n", "<c-b>")
            return
        end
    end, translator.namespace)
end

return float

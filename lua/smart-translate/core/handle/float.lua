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

---@param translator SmartTranslate.Translator
function float.render(translator)
    local title = "SmartTranslate(cache)"

    if not translator.use_cache_translation then
        title = ("SmartTranslate(%s)"):format(translator.engine)
    end

    local width = title:len()
    for _, l in ipairs(translator.translation) do
        width = math.max(width, #l)
    end

    local height =
        math.min(#translator.translation, math.floor(vim.o.lines * 3 / 4))

    -- When the display length is not long enough to display the title, we will hide the title
    if #translator.translation == 1 and #translator.translation[1] < width then
        title = ""
        width = #translator.translation[1]
    end

    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, translator.translation)
    vim.bo[bufnr].filetype = "translate-float"

    local winner = vim.api.nvim_open_win(bufnr, false, {
        relative = "cursor",
        row = 1,
        col = 1,
        width = width,
        height = height,
        title = title,
        title_pos = "center",
        style = "minimal",
        border = "rounded",
        focusable = false,
        zindex = 200,
    })

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

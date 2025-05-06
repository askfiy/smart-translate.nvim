local Events = require("smart-translate.core.events")

local split = {}

local global_window = nil

---@param translator SmartTranslate.Translator
function split.render(translator)
    local min_lnum = nil
    local max_lnum = nil

    for _, range in ipairs(translator.range) do
        local lnum = range.lnum

        if not min_lnum and not max_lnum then
            min_lnum, max_lnum = lnum, lnum
        else
            min_lnum = lnum < min_lnum and lnum or min_lnum
            max_lnum = lnum > max_lnum and lnum or max_lnum
        end
    end

    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, translator.translation)

    if not global_window or not vim.api.nvim_win_is_valid(global_window) then
        global_window = vim.api.nvim_open_win(bufnr, false, {
            split = "above",
            style = "minimal",
            width = vim.api.nvim_win_get_width(0),
            height = math.min(
                math.max(#translator.translation, 5),
                math.floor(vim.o.lines * 1 / 5)
            ),
            focusable = false,
        })

        vim.wo[global_window].conceallevel = 2
    end

    vim.bo[bufnr].modifiable = false
    vim.api.nvim_win_set_buf(global_window, bufnr)
    vim.bo[bufnr].filetype = "translate-split"

    -- Build an automatic sliding window and follow the main window to adjust the split cursor position
    if vim.api.nvim_win_is_valid(translator.window) then
        local events = Events.new()

        events:register(
            vim.api.nvim_create_autocmd(
                { "CursorMoved", "CursorMovedI", "ModeChanged" },
                {
                    callback = function()
                        if not vim.api.nvim_win_is_valid(global_window) then
                            events:cleanup()
                            return
                        end

                        local mode = vim.fn.mode()

                        vim.api.nvim_buf_clear_namespace(
                            bufnr,
                            translator.namespace,
                            0,
                            -1
                        )

                        -- For nvim_win_set_cursor, the main window line number and the split window line number are inconsistent.
                        -- For example, we translate in line 300 of the main window
                        -- The line number in split is actually 1, so if you need to directly set the cursor in split to the main window 300, an error will be reported
                        -- A conversion should be made
                        if mode == "v" or mode == "V" or mode == "\22" then
                            -- Handle visual mode selection
                            local pos1 = vim.fn.getpos("v")
                            local pos2 = vim.fn.getpos(".")

                            local start_line = math.min(pos1[2], pos2[2])
                            local end_line = math.max(pos1[2], pos2[2])

                            if
                                start_line >= min_lnum
                                and end_line <= max_lnum
                            then
                                local buf_start = #translator.translation
                                    - (max_lnum - start_line)

                                local buf_end = #translator.translation
                                    - (max_lnum - end_line)

                                for line = buf_start, buf_end do
                                    vim.api.nvim_buf_add_highlight(
                                        bufnr,
                                        translator.namespace,
                                        "Visual",
                                        line - 1,
                                        0,
                                        -1
                                    )
                                end

                                vim.api.nvim_win_set_cursor(
                                    global_window,
                                    { buf_end, 0 }
                                )
                            end
                        else
                            -- Normal mode: highlight current line only
                            local cursor =
                                vim.api.nvim_win_get_cursor(translator.window)

                            if
                                cursor[1] >= min_lnum
                                and cursor[1] <= max_lnum
                            then
                                local buf_line = #translator.translation
                                    - (max_lnum - cursor[1])

                                vim.api.nvim_win_set_cursor(
                                    global_window,
                                    { buf_line, 0 }
                                )
                                vim.api.nvim_buf_add_highlight(
                                    bufnr,
                                    translator.namespace,
                                    "Visual",
                                    buf_line - 1,
                                    0,
                                    -1
                                )
                            end
                        end
                    end,
                }
            )
        )

        events:register(vim.api.nvim_create_autocmd({ "BufWinLeave" }, {
            buffer = translator.buffer,
            callback = function()
                if vim.api.nvim_win_is_valid(global_window) then
                    vim.api.nvim_win_hide(global_window)
                end
                events:cleanup()
            end,
        }))
    end
end

return split

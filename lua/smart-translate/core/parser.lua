local u8 = require("smart-translate.util.u8")
local treesitter = require("smart-translate.util.treesitter")

local parser = {}

---@param bufnr buffer
---@return table<string, any>[]
function parser.comment(bufnr)
    local node = treesitter.get_cursor_node(bufnr)

    -- Check for special mappings
    local nodes = treesitter.get_range_nodes(node, {
        "comment",
        "string_start",
        "string_end",
        "string_content",
        "comment_content",
    }, {
        "comment",
        "string_content",
        "comment_content",
    })

    if vim.tbl_isempty(nodes) then
        return { {}, {} }
    end

    local content = {}
    local range = {}

    -- Get the range directly from the first and last nodes
    local first_node = nodes[1]
    local last_node = nodes[#nodes]
    local start_row, start_col, _, _ = first_node:range()
    local _, _, end_row, end_col = last_node:range()

    -- Convert to 1-based index
    start_row = start_row + 1
    start_col = start_col + 1
    end_row = end_row + 1
    end_col = end_col + 1

    -- Get all rows in range
    local lines =
        vim.api.nvim_buf_get_lines(bufnr, start_row - 1, end_row, false)

    -- Process each row
    for index, line_text in ipairs(lines) do
        local current_row = start_row + index - 1

        -- Determine the starting and ending columns of the current row
        local line_start_col = (index == 1) and start_col or 1
        local line_end_col = (current_row == end_row) and (end_col - 1)
            or #line_text

        -- Make sure the column index is within the valid range
        line_start_col = math.min(line_start_col, #line_text + 1)
        line_end_col = math.min(line_end_col, #line_text)

        -- Extract actual content
        local line_content = ""
        if line_start_col <= line_end_col then
            line_content = line_text:sub(line_start_col, line_end_col)
        end

        table.insert(range, {
            lnum = current_row,
            scol = line_start_col,
            ecol = line_end_col,
        })
        table.insert(content, line_content)
    end

    return { range, content }
end

---@param mode string
---@return table<string, any>[]
function parser.select(mode)
    if mode == "n" then
        local srow, _ = unpack(vim.api.nvim_win_get_cursor(0))
        local ecol = #vim.fn.getline(srow)
        local range = {
            {
                lnum = srow,
                scol = 1,
                ecol = ecol,
            },
        }
        local content = { vim.api.nvim_get_current_line() }
        return { range, content }
    else
        local start_pos = vim.fn.getpos("'<")
        local end_pos = vim.fn.getpos("'>")

        local srow, scol = start_pos[2], start_pos[3]
        local erow, ecol = end_pos[2], end_pos[3]

        if srow > erow or (srow == erow and scol > ecol) then
            srow, scol, erow, ecol = erow, ecol, srow, scol
        end

        if mode == "V" then
            local range = vim.tbl_map(function(lnum)
                return {
                    lnum = lnum,
                    scol = 1,
                    ecol = #vim.fn.getline(lnum),
                }
            end, vim.fn.range(srow, erow))

            local content = vim.api.nvim_buf_get_lines(0, srow - 1, erow, true)

            return { range, content }
        end

        if mode == "v" then
            local range = {}
            local content = {}

            for _, lnum in ipairs(vim.fn.range(srow, erow)) do
                local line_text = vim.fn.getline(lnum)
                local line_ecol = math.min(#line_text, ecol)
                line_ecol = u8.adjust_boundary(line_text, line_ecol)

                table.insert(range, {
                    lnum = lnum,
                    scol = scol,
                    ecol = line_ecol,
                })
                table.insert(content, line_text:sub(scol, line_ecol))
            end

            return { range, content }
        end

        if mode == "\22" then
            local range = {}
            local content = {}

            for _, lnum in ipairs(vim.fn.range(srow, erow)) do
                local line_text = vim.fn.getline(lnum)
                local line_ecol = math.min(#line_text, ecol)
                line_ecol = u8.adjust_boundary(line_text, line_ecol)

                table.insert(range, {
                    lnum = lnum,
                    scol = scol,
                    ecol = line_ecol,
                })
                table.insert(content, line_text:sub(scol, line_ecol))
            end

            return { range, content }
        end
    end

    return {}
end

return parser

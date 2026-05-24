local vsplit = {}

local global_window = nil

---@param translator SmartTranslate.Translator
function vsplit.render(translator)
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, translator.translation)
    vim.bo[bufnr].filetype = "translate-vsplit"
    vim.bo[bufnr].buftype = "nofile"
    vim.bo[bufnr].bufhidden = "hide"
    vim.bo[bufnr].modifiable = true
    vim.bo[bufnr].swapfile = false

    if not global_window or not vim.api.nvim_win_is_valid(global_window) then
        global_window = vim.api.nvim_open_win(bufnr, true, {
            split = "right",
            width = math.floor(vim.o.columns / 2),
        })

        vim.wo[global_window].number = true
        vim.wo[global_window].wrap = true
        vim.wo[global_window].linebreak = true
    else
        vim.api.nvim_win_set_buf(global_window, bufnr)
        vim.api.nvim_set_current_win(global_window)
    end
end

return vsplit

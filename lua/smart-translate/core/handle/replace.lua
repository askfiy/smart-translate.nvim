local replace = {}

---@param translator SmartTranslate.Translator
function replace.render(translator)
    -- When getting range, the row number and other data we get will always be + 1
    -- Therefore, -1 is processed uniformly here.
    for index, position in ipairs(translator.range) do
        if vim.trim(translator.translation[index]):len() > 0 then
            vim.api.nvim_buf_set_text(
                translator.buffer,
                position.lnum - 1,
                position.scol - 1,
                position.lnum - 1,
                position.ecol,
                { translator.translation[index] }
            )
        end
    end
end

return replace

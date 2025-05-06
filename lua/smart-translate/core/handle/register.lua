local register = {}

---@param translator SmartTranslate.Translator
function register.render(translator)
    vim.fn.setreg(vim.v.register, table.concat(translator.translation, "\n"))
    vim.notify("Save register success", "ERROR", {
        annote = "[smart-translate]",
    })
end

return register

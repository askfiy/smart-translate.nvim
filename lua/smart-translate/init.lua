-- author: askfiy

local config = require("smart-translate.config")
local parser = require("smart-translate.core.parser")
local cacher = require("smart-translate.core.cacher")
local complete = require("smart-translate.core.complete")
local Translator = require("smart-translate.core.translator")

-- require("smart-translate.debug")

local M = {}

---@param opts? table<string, any>
function M.setup(opts)
    config.update(opts)
    cacher.load_cache()

    vim.api.nvim_create_user_command("Translate", function(env)
        local translator = Translator.new(env)

        if not vim.tbl_isempty(translator.special) then
            if #translator.special > 1 then
                vim.notify("Many special operations", "ERROR", {
                    annote = "[smart-translate]",
                })
                return
            end

            if not vim.tbl_isempty(translator.original) then
                vim.notify(
                    "Unable to translate when special operations are executed",
                    "ERROR",
                    {
                        annote = "[smart-translate]",
                    }
                )
                return
            end
        end

        if vim.tbl_contains(translator.special, "--stream") then
            vim.notify("Not implemented", "ERROR", {
                annote = "[smart-translate]",
            })
            return
        end

        if vim.tbl_contains(translator.special, "--cleanup") then
            vim.notify("Cleanup cacher success", "INFO", {
                annote = "[smart-translate]",
            })
            cacher.cleanup()
            return
        end

        if not vim.tbl_isempty(translator.original) then
            translator.original = { table.concat(translator.original, " ") }
        else
            if not vim.tbl_contains(translator.special, "--comment") then
                translator.range, translator.original =
                    unpack(parser.select(translator.mode))
            else
                translator.range, translator.original =
                    unpack(parser.comment(translator.buffer))
            end

            local content = table.concat(translator.original, "\n")
            if #vim.trim(content) == 0 then
                vim.notify("No content", "ERROR", {
                    annote = "[smart-translate]",
                })
                return
            end
            translator.original =
                vim.split(content, "\n", { trimempty = false })
        end

        translator:translate()
    end, {
        nargs = "*",
        range = true,
        complete = complete.get_complete_list,
        desc = "Translate command",
    })
end

return M

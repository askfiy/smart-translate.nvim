local util = require("smart-translate.util")
local language = require("smart-translate.core.language")

local dirname = vim.fn.fnamemodify(util.filepath(), ":h")
local engine = util.filelist(dirname .. "/engine")
local handle = util.filelist(dirname .. "/handle")

local complete = {
    -- When -- appears, you can use the following key to complete it
    -- When something like --source= appears, = can be completed with options in language, and so on.
    options = {
        handle = handle,
        engine = engine,
        source = language,
        target = language,
        comment = {},
        cleanup = {},
        -- TODO: Later implementation
        -- stream = {},
    },
}

function complete.get_complete_list(arglead, cmdline, cursorpos)
    -- Show completion only if -- is explicitly entered
    if arglead:match("^%-%-") then
        local items = {}

        -- Parse options that have been used
        local used_options = {}
        for option in cmdline:gmatch("%-%-([^%s=]+)") do
            used_options[option] = true
        end

        local option_name = arglead:match("^%-%-([^=]*)")
        local has_equal = arglead:find("=") ~= nil

        -- If an equal sign is included, provide value completion for the corresponding option
        if has_equal then
            local option = arglead:match("^%-%-([^=]*)=")
            local value_prefix = arglead:match("^%-%-[^=]*=(.*)")

            if complete.options[option] then
                for _, value in ipairs(complete.options[option]) do
                    if
                        value:lower():find(value_prefix:lower() or "", 1, true)
                        == 1
                    then
                        table.insert(items, "--" .. option .. "=" .. value)
                    end
                end
            end
        else
            -- Provide unused option name completion
            for opt, _ in pairs(complete.options) do
                if
                    not used_options[opt]
                    and opt:find(option_name or "", 1, true) == 1
                then
                    table.insert(items, "--" .. opt)
                end
            end
        end

        return items
    end
end

return complete

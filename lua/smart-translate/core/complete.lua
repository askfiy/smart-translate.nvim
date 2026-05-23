local util = require("smart-translate.util")
local language = require("smart-translate.core.language")

local complete = {
    -- Each entry maps an option name to the list of valid values.
    -- An empty list means the option is a flag (no `=value`).
    options = {
        source = language,
        target = language,
        handle = util.handles(),
        engine = util.engines(),
        comment = {},
        cleanup = {},
        -- TODO: Later implementation
        -- stream = {},
    },
}

function complete.get_complete_list(arglead, cmdline, cursorpos)
    local items = {}

    -- Track options already used in the cmdline so we don't suggest them again.
    -- Accept both `opt=val` and the legacy `--opt=val` forms.
    local used_options = {}
    for word in cmdline:gmatch("%S+") do
        local clean = word:gsub("^%-%-", "")
        local key = clean:match("^([%w_]+)=")
            or (complete.options[clean] and clean)
            or nil
        if key then
            used_options[key] = true
        end
    end

    -- Strip optional leading `--` so users can tab-complete with or without it.
    local lead = arglead:gsub("^%-%-", "")
    local has_equal = lead:find("=") ~= nil

    if has_equal then
        local option = lead:match("^([^=]*)=")
        local value_prefix = lead:match("^[^=]*=(.*)") or ""

        if complete.options[option] then
            for _, value in ipairs(complete.options[option]) do
                if
                    value:lower():find(value_prefix:lower(), 1, true) == 1
                then
                    table.insert(items, option .. "=" .. value)
                end
            end
        end
    else
        for opt, _ in pairs(complete.options) do
            if
                not used_options[opt]
                and opt:find(lead, 1, true) == 1
            then
                table.insert(items, opt)
            end
        end
    end

    return items
end

return complete

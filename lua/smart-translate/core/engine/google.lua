local http = require("http")

local google = {}

-- https://cloud.google.com/translate/docs/languages
local source_mappings = {
    ["auto"] = "",
}

local target_mappings = {}

---@param lang string
---@return string?
function google.source_lang(lang)
    if source_mappings[lang] then
        return source_mappings[lang]
    end

    if lang:find("-") then
        return lang:sub(1, 2):upper()
    end

    return lang
end

---@param lang string
---@return string
function google.target_lang(lang)
    if target_mappings[lang] then
        return target_mappings[lang]
    end

    return lang
end

---@param source string
---@param target string
---@param original string[]
---@param callback function
function google.translate(source, target, original, callback)
    local text = table.concat(original, "\n")

    local json_body = {
        text = text,
        source = google.source_lang(source),
        target = google.target_lang(target),
    }

    http.post(
        "https://script.google.com/macros/s/AKfycbx6yuInp-GFwvL1wRX7efsWu88ZVeV6wBzIAzLzST0kS2nuWKiwCCa84_eCUwHiD1Lt/exec",
        {
            headers = { ["Content-Type"] = "application/json" },
            json = json_body,
            allow_redirects = true,
        }
    ):add_done_callback(function(future)
        local err = future:exception()

        if err then
            vim.api.nvim_echo({
                {
                    err,
                    "ErrorMsg",
                },
            }, true, {})
            return
        end

        local response = future:result()

        if response:ok() then
            local translation = response:json()["translated"]
            callback(vim.split(translation, "\n", { trimempty = false }))
        end
    end)
end

return google

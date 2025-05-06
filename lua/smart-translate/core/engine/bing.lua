local http = require("http")

local bing = {}

-- https://learn.microsoft.com/zh-cn/azure/ai-services/translator/language-support
local source_mappings = {
    ["auto"] = "auto-detect",
}

local target_mappings = {
    ["zh-CN"] = "ZH-Hans",
    ["zh-TW"] = "ZH-Hant",
}

---@param lang string
---@return string
function bing.source_lang(lang)
    if source_mappings[lang] then
        return source_mappings[lang]
    end
    return lang
end

---@param lang string
---@return string
function bing.target_lang(lang)
    if target_mappings[lang] then
        return target_mappings[lang]
    end
    return lang
end

---@param source string
---@param target string
---@param original string[]
---@param callback function
function bing.translate(source, target, original, callback)
    local text = table.concat(original, "\n")
    local json_body = {
        text = text,
        source = bing.source_lang(source),
        target = bing.target_lang(target),
    }

    http.post(
        "https://script.google.com/macros/s/AKfycbyUeA-GVbT1UtX6dMzwlXDkrZ5Euv0SJAjkBbnXlN3f057YhfD4N4JwseQPEhlvmc1vxw/exec",
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

return bing

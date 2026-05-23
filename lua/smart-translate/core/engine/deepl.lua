local config = require("smart-translate.config")
local http = require("http")
local log = require("smart-translate.util.log")

local deepl = {}

--  https://developers.deepl.com/docs/getting-started/supported-languages
local source_mappings = {
    ["auto"] = "",
}

local target_mappings = {
    ["no"] = "NB",
    ["zh-CN"] = "ZH-HANS",
    ["zh-TW"] = "ZH-HANT",
    ["en"] = "EN-US",
    ["pt"] = "PT-BR",
}

---@param lang string
---@return string?
function deepl.source_lang(lang)
    if source_mappings[lang] then
        return source_mappings[lang]
    end

    -- Check for special mappings
    if lang:find("-") then
        return lang:sub(1, 2):upper()
    end

    -- Other language codes are directly converted to uppercase letters
    return lang:upper()
end

---@param lang string
---@return string
function deepl.target_lang(lang)
    if target_mappings[lang] then
        return target_mappings[lang]
    end

    return lang:upper()
end

---@param source string
---@param target string
---@param original string[]
---@param callback function
function deepl.translate(source, target, original, callback)
    local json_body = {
        text = original,
        source_lang = deepl.source_lang(source),
        target_lang = deepl.target_lang(target),
    }

    local api_key = config.engine.deepl.api_key

    if api_key:sub(1, 1) == "$" then
        local env = os.getenv(api_key:sub(2))
        assert(env, "DeepL api_key: %s get failed")
        api_key = env
    end

    log.debug(("deepl: request source=%s target=%s lines=%d"):format(
        json_body.source_lang, json_body.target_lang, #original
    ))

    http.post(config.engine.deepl.base_url, {
        headers = {
            Authorization = "DeepL-Auth-Key " .. api_key,
            ["Content-Type"] = "application/json",
        },
        json = json_body,
        allow_redirects = true,
    }):add_done_callback(function(future)
        local err = future:exception()
        if err then
            log.debug("deepl: request failed: " .. tostring(err))
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
            local translations = response:json()["translations"]
            log.debug(("deepl: response ok, translated %d lines"):format(#translations))
            callback(vim.tbl_map(function(item)
                return item.text
            end, translations))
        else
            log.debug(("deepl: response not ok, status=%s"):format(tostring(response.status)))
        end
    end)
end

return deepl

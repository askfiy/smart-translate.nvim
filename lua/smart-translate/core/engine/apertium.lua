local config = require("smart-translate.config")
local http = require("http")
local log = require("smart-translate.util.log")

local apertium = {}

-- Apertium APY expects ISO 639-3 codes ("eng", "cat", "spa"...).
-- https://wiki.apertium.org/wiki/Apertium-apy
local iso3_mappings = {
    en = "eng",
    ca = "cat",
    es = "spa",
    fr = "fra",
    pt = "por",
    it = "ita",
    de = "deu",
    oc = "oci",
    eu = "eus",
    gl = "glg",
    ro = "ron",
    nl = "nld",
}

---@param lang string
---@return string
function apertium.source_lang(lang)
    if lang == "auto" or lang == "" then
        lang = "eng"
    end
    return iso3_mappings[lang] or lang
end

---@param lang string
---@return string
function apertium.target_lang(lang)
    return iso3_mappings[lang] or lang
end

---@param source string
---@param target string
---@param original string[]
---@param callback function
function apertium.translate(source, target, original, callback)
    -- A delimiter unlikely to appear in user text, so a single request
    -- can carry the whole buffer and the response can be split back
    -- into the original line count.
    local delim = "\n\n\n"

    local result = {}
    local non_empty = {}
    for i, line in ipairs(original) do
        result[i] = line
        if line:match("%S") then
            table.insert(non_empty, i)
        end
    end

    if #non_empty == 0 then
        callback(result)
        return
    end

    local parts = {}
    for _, i in ipairs(non_empty) do
        table.insert(parts, original[i])
    end
    local combined = table.concat(parts, delim)

    local langpair = apertium.source_lang(source)
        .. "|"
        .. apertium.target_lang(target)

    local base_url = config.engine.apertium.base_url

    log.debug(("apertium: request langpair=%s lines=%d (non-empty=%d)"):format(
        langpair, #original, #non_empty
    ))

    http.post(base_url, {
        headers = { ["Content-Type"] = "application/x-www-form-urlencoded" },
        data = {
            langpair = langpair,
            q = combined,
            savetext = "false",
        },
        allow_redirects = true,
    }):add_done_callback(function(future)
        local err = future:exception()
        if err then
            log.debug("apertium: request failed: " .. tostring(err))
            vim.api.nvim_echo({
                { "Apertium: translation request failed", "ErrorMsg" },
            }, true, {})
            callback(result)
            return
        end

        local response = future:result()
        if response:ok() then
            local data = response:json()
            if data and data.responseData and data.responseData.translatedText then
                local translated = vim.split(
                    data.responseData.translatedText,
                    delim,
                    { plain = true }
                )
                log.debug(("apertium: response ok, translated %d segment(s)"):format(#translated))
                for k, idx in ipairs(non_empty) do
                    result[idx] = translated[k] or original[idx]
                end
            else
                log.debug("apertium: response ok but no translatedText in payload")
                vim.api.nvim_echo({
                    { "Apertium: translation request failed", "ErrorMsg" },
                }, true, {})
            end
        else
            log.debug(("apertium: response not ok, status=%s"):format(tostring(response.status)))
            vim.api.nvim_echo({
                { "Apertium: translation request failed", "ErrorMsg" },
            }, true, {})
        end
        callback(result)
    end)
end

return apertium

local md5 = require("smart-translate.libs.md5")
local config = require("smart-translate.config")
local cacher = require("smart-translate.core.cacher")
local content = require("smart-translate.util.content")

--[[
    A sophisticated caching mechanism is integral to our translator's design. The system generates cache keys using MD5 hashing, combining four essential components:
    - Source language
    - Target language
    - Original text content
    - Translation engine identifier

    The translation process optimizes performance by:
    1. Checking the cache before translation
    2. Only processing uncached lines
    3. Maintaining line-level granularity

    The cache validation enforces a line count match between source and translation. When line counts differ, the system continues to function but excludes those results from the cache, ensuring cache integrity without compromising translation functionality.
]]

---@class SmartTranslate.Engine
---@field translate fun(source: string, target: string, original: string[], callback: fun(translation: string[]))

---@class SmartTranslate.EngineProxy
---@field private placeholder string
---@field private proxy string
---@field private engine SmartTranslate.Engine
local EngineProxy = {}
EngineProxy.__index = EngineProxy

---@param proxy string
function EngineProxy.new(proxy)
    local self = setmetatable({}, EngineProxy)
    self.proxy = proxy
    self.engine = require(("smart-translate.core.engine.%s"):format(proxy:lower()))
    self.placeholder = "{{NO_CACHE}}"

    assert(
        type(self.engine) == "table"
            and type(self.engine.translate) == "function",
        ("Not implemented `translate`, form: %s"):format(proxy)
    )
    return self
end

---@param source string
---@param target string
---@param original string[]
---@param callback function(translation: string[])
function EngineProxy:translate(source, target, original, callback)
    if not config.default.cache then
        self.engine.translate(source, target, original, function(translation)
            callback(false, translation)
        end)
        return
    end

    local cached, no_cache = self:query_cache(source, target, original)

    if vim.tbl_isempty(no_cache) then
        callback(true, cached)
    else
        self.engine.translate(source, target, original, function(translation)
            local cached_copy = vim.deepcopy(cached)

            -- When we cannot ensure that the number of lines of the translation and the original text are always consistent, caching should not be performed
            -- The engines currently experiencing this situation are:
            -- - bing
            if #translation ~= #cached_copy then
                callback(false, translation)
            else
                local no_cache_index = 1
                for index, line in ipairs(cached) do
                    if line == self.placeholder then
                        cached_copy[index] = translation[index]

                        local key = self:cache_key(
                            source,
                            target,
                            vim.trim(no_cache[no_cache_index])
                        )

                        cacher.set(key, vim.trim(translation[index]))

                        no_cache_index = no_cache_index + 1
                    end
                end
                callback(false, cached_copy)
            end
        end)
    end
end

---@param source string
---@param target string
---@param original_text string
---@return string
function EngineProxy:cache_key(source, target, original_text)
    return md5.sumhexa(
        self.proxy:lower() .. source:lower() .. target:lower() .. original_text
    )
end

---@param source string
---@param target string
---@param original string[]
---@return string[], string[]
function EngineProxy:query_cache(source, target, original)
    local cached = {}
    local no_cache = {}

    for index, line in ipairs(original) do
        local trim_line = vim.trim(line)

        if trim_line:len() > 0 then
            local key = self:cache_key(source, target, trim_line)
            local cache = cacher.get(key)

            if cache then
                --Get the indent of the current line and add the cached content
                cached[index] = content.get_indentation(line) .. cache
            else
                -- placeholder
                cached[index] = self.placeholder
                table.insert(no_cache, line)
            end
        else
            cached[index] = line
        end
    end

    return cached, no_cache
end

return EngineProxy

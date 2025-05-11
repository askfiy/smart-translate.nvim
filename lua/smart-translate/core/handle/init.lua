local util = require("smart-translate.util")
local config = require("smart-translate.config")

---@param handle string
---@return boolean
local function has_handle(handle)
    return vim.tbl_contains(util.handles(), handle)
end

---@param handle string
---@return table
local function get_handle(handle)
    local ok, pkg = pcall(
        require,
        ("smart-translate.core.handle.%s"):format(handle:lower())
    )

    if ok then
        return pkg
    end

    ---@param item SmartTranslate.Config.Translator.Handle
    local filters = vim.tbl_filter(function(item)
        return item.name == handle
    end, config.translator.handle)
    return not vim.tbl_isempty(filters) and filters[1] or {}
end

---@class SmartTranslate.Handle
---@field public render fun(translator: SmartTranslate.Translator)

---@class SmartTranslate.HandleProxy
---@field private proxy any
---@field private handle SmartTranslate.Handle
local HandleProxy = {}
HandleProxy.__index = HandleProxy

---@param proxy string
function HandleProxy.new(proxy)
    local self = setmetatable({}, HandleProxy)
    assert(has_handle(proxy), ("Invalid handle: %s"):format(proxy))

    self.proxy = proxy
    self.handle = get_handle(proxy)

    assert(
        type(self.handle) == "table" and type(self.handle.render) == "function",
        ("Not implemented `render`, form: %s"):format(proxy)
    )
    return self
end

---@param translator SmartTranslate.Translator
function HandleProxy:render(translator)
    self.handle.render(translator)
end

return HandleProxy

---@class SmartTranslate.Handle
---@field render fun(translator: SmartTranslate.Translator)

---@class SmartTranslate.HandleProxy
---@field private proxy any
---@field private handle SmartTranslate.Handle
local HandleProxy = {}
HandleProxy.__index = HandleProxy

---@param proxy string
function HandleProxy.new(proxy)
    local self = setmetatable({}, HandleProxy)
    self.proxy = proxy
    self.handle = require(("smart-translate.core.handle.%s"):format(proxy:lower()))

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

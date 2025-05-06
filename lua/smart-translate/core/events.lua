---@class SmartTranslate.Events
---@field private registers integer[]
local Events = {}
Events.__index = Events

function Events.new()
    local self = setmetatable({}, Events)
    self.registers = {}
    return self
end

---@param event integer
function Events:register(event)
    table.insert(self.registers, event)
end

function Events:cleanup()
    local registers = vim.deepcopy(self.registers)
    for index, event in ipairs(registers) do
        vim.api.nvim_del_autocmd(event)
        table.remove(self.registers, index)
    end
end

return Events

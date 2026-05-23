local config = require("smart-translate.config")

local log = {}

---@param msg string
function log.debug(msg)
    if config.debug then
        vim.notify("[smart-translate] " .. msg, vim.log.levels.DEBUG)
    end
end

return log

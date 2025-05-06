local content = {}

---@param line string
---@return string
function content.get_indentation(line)
    local indent = line:match("^%s*")
    return indent or ""
end

return content

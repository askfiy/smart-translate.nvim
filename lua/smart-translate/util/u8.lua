local u8 = {}

---@param line string
---@param pos integer
function u8.is_char_boundary(line, pos)
    -- The beginning or end of a string is a valid boundary
    if pos <= 1 or pos > #line then
        return true
    end

    -- Check if the position is a UTF-8 continuation byte (10xxxxxx)
    local b = line:byte(pos)
    -- If not a continuation byte, it is the beginning of a new character
    return b < 0x80 or b >= 0xC0
end

---@param line string
---@param pos integer
function u8.adjust_boundary(line, pos)
    -- If the position exceeds the line length, return the line length
    if pos >= #line then
        return #line
    end

    -- Otherwise adjust to next character boundary
    while pos < #line and not u8.is_char_boundary(line, pos + 1) do
        pos = pos + 1
    end
    return pos
end

return u8

local cacher = {}

-- Each key maps to { value = string, hint = integer }
cacher._local = {}

local uv = vim.uv or vim.loop
local filepath = vim.fn.stdpath("data") .. "/translate-cacher.msgpack"
local MAX_FILE_SIZE = 1024 * 1024 * 1024 -- 1GB

---@param key string
---@return string | nil
function cacher.get(key)
    local entry = cacher._local[key]
    if entry and entry.value ~= nil then
        entry.hint = (entry.hint or 0) + 1
        return entry.value
    end
    return nil
end

---@param key string
---@param value string
function cacher.set(key, value)
    local hint = 0
    if cacher._local[key] then
        hint = cacher._local[key].hint or 0
    end
    cacher._local[key] = {
        value = value,
        hint = hint,
    }
end

---@param key string
function cacher.del(key)
    cacher._local[key] = nil
end

function cacher.cleanup()
    cacher._local = {}
end

function cacher.clean()
    local stat = uv.fs_stat(filepath)
    if not stat or stat.size < MAX_FILE_SIZE then
        return
    end

    local sorted = {}
    for key, entry in pairs(cacher._local) do
        table.insert(sorted, { key = key, hint = entry.hint or 0 })
    end

    table.sort(sorted, function(a, b)
        return a.hint < b.hint
    end)

    local remove_count = math.floor(#sorted * 0.2)
    for i = 1, remove_count do
        local key = sorted[i].key
        cacher.del(key)
    end
end

--- Save cache to file (use uv to write binary)
function cacher.save()
    cacher.clean()

    local ok, encoded = pcall(vim.mpack.encode, cacher._local)
    if not ok then
        vim.notify("Failed to encode cache", "ERROR", {
            annote = "[smart-translate]",
        })
        return
    end

    local fd = uv.fs_open(filepath, "w", 438) -- 0666
    if not fd then
        vim.notify("Failed to open cache file for writing", "ERROR", {
            annote = "[smart-translate]",
        })
        return
    end

    ---@diagnostic disable-next-line: param-type-mismatch
    uv.fs_write(fd, encoded)
    uv.fs_close(fd)
end

--- Load cache file (use uv to read binary)
function cacher.load_cache()
    local fd = uv.fs_open(filepath, "r", 438)
    if not fd then
        --Create empty file
        local enc = vim.mpack.encode({})
        local file = uv.fs_open(filepath, "w", 438)
        if file then
            ---@diagnostic disable-next-line: param-type-mismatch
            uv.fs_write(file, enc)
            uv.fs_close(file)
        end
        return
    end

    local stat = uv.fs_fstat(fd)
    if not stat then
        return
    end

    local data = uv.fs_read(fd, stat.size, 0)
    uv.fs_close(fd)

    if data then
        local ok, result = pcall(vim.mpack.decode, data)
        if ok and type(result) == "table" then
            cacher._local = result
        end
    end
end

-- Save cache (before exiting)
vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
        cacher.save()
    end,
})

return cacher

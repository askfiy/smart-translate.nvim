local util = {}

---@param source table<string, any>
---@param defaults table<string, any>
function util.with_defaults(source, defaults)
    for k, v in pairs(defaults) do
        source[k] = v
    end
end

---@return string
function util.filepath()
    return debug.getinfo(2, "S").source:sub(2)
end

---@param directory_path string
---@return string[]
function util.filelist(directory_path)
    local ignore_packages = { "init" }

    local packages = vim.tbl_map(function(package_abspath)
        return vim.fn.fnamemodify(package_abspath, ":t:r")
    end, vim.fn.globpath(directory_path, "*", false, true))

    return vim.tbl_filter(function(package_name)
        return not vim.tbl_contains(ignore_packages, package_name)
    end, packages)
end

return util

local config = require("smart-translate.config")

local util = {}

---@return string
function util.filepath()
    return debug.getinfo(2, "S").source:sub(2)
end

---@param source table<string, any>
---@param defaults table<string, any>
function util.with_defaults(source, defaults)
    for k, v in pairs(defaults) do
        source[k] = v
    end
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

---@return string[]
function util.engines()
    if not util._engins then
        local build_engine = util.filelist(util.rootpath .. "/core/engine")
        ---@param engine SmartTranslate.Config.Translator.Engine
        local custom_engine = vim.tbl_map(function(engine)
            return engine.name:lower()
        end, config.translator.engine)

        util._engins = vim.fn.extend(build_engine, custom_engine)
    end

    return util._engins
end

---@return string[]
function util.handles()
    if not util._handles then
        local build_handle = util.filelist(util.rootpath .. "/core/handle")
        ---@param handle SmartTranslate.Config.Translator.Handle
        local custom_handle = vim.tbl_map(function(handle)
            return handle.name:lower()
        end, config.translator.handle)

        util._handles = vim.fn.extend(build_handle, custom_handle)
    end
    return util._handles
end

util.rootpath = vim.fn.fnamemodify(util.filepath(), ":h:h")

return util

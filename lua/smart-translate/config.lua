---@class SmartTranslate.Config
---@field public default SmartTranslate.Config.DefaultOpts
---@field public engine SmartTranslate.Config.EngineOpts
---@field public hooks SmartTranslate.Config.HooksOpts
---@field public translator SmartTranslate.Config.Translator
local config = {}

local default_config = {
    default = {
        cmds = {
            source = "auto",
            target = "zh-CN",
            handle = "float",
            engine = "google",
        },
        cache = true,
    },
    engine = {
        deepl = {
            --Support SHELL variables, or fill in directly
            api_key = "$DEEPL_API_KEY",
            base_url = "https://api-free.deepl.com/v2/translate",
        },
    },
    hooks = {
        ---@param opts SmartTranslate.Config.Hooks.BeforeCallOpts
        ---@return string[]
        before_translate = function(opts)
            return opts.original
        end,
        ---@param opts SmartTranslate.Config.Hooks.AfterCallOpts
        ---@return string[]
        after_translate = function(opts)
            return opts.translation
        end,
    },
    translator = {
        engine = {},
        handle = {},
    },
}

setmetatable(config, {
    -- getter
    __index = function(_, key)
        return default_config[key]
    end,

    -- setter
    __newindex = function(_, key, value)
        default_config[key] = value
    end,
})

---@param opts? table<string, any>
function config.update(opts)
    default_config = vim.tbl_deep_extend("force", default_config, opts or {})
end

return config

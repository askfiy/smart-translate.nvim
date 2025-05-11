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
        engine = {
            {
                name = "translate-shell",
                ---@param source string
                ---@param target string
                ---@param original string[]
                ---@param callback fun(translation: string[])
                translate = function(source, target, original, callback)
                    source = "en"
                    target = "zh"
                    vim.system(
                        {
                            "trans",
                            "-b",
                            ("%s:%s"):format(source, target),
                            table.concat(original, "\n"),
                            ---@param completed vim.SystemCompleted
                        },
                        { text = true },
                        vim.schedule_wrap(function(completed)
                            callback(
                                vim.split(
                                    completed.stdout,
                                    "\n",
                                    { trimempty = false }
                                )
                            )
                        end)
                    )
                end,
            },
        },
        handle = {
            {
                name = "echo",
                ---@param translator SmartTranslate.Translator
                render = function(translator)
                    vim.print(translator.translation)
                end,
            },
        },
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

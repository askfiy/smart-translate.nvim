---@class SmartTranslate.Config.DefaultOpts.Cmds
---@field public source string
---@field public target string
---@field public handle string
---@field public engine string

---@class SmartTranslate.Config.DefaultOpts
---@field public cmds SmartTranslate.Config.DefaultOpts.Cmds
---@field public cache string

---@class SmartTranslate.Config.EngineOpts.Openai
---@field public model string
---@field public api_key string
---@field public base_url string

---@class SmartTranslate.Config.EngineOpts.Baidu
---@field public app_id string
---@field public api_key string
---@field public base_url string

---@class SmartTranslate.Config.EngineOpts.DeepL
---@field public api_key string
---@field public base_url string

---@class SmartTranslate.Config.EngineOpts
---@field public deepl SmartTranslate.Config.EngineOpts.DeepL

---@class SmartTranslate.Config.Hooks.BeforeCallOpts
---@field public mode string
---@field public engine string
---@field public source string
---@field public target string
---@field public original string[]

---@class SmartTranslate.Config.Hooks.AfterCallOpts
---@field public mode string
---@field public engine string
---@field public source string
---@field public target string
---@field public translation string[]

---@class SmartTranslate.Config.HooksOpts
---@field before_translate fun(otps: SmartTranslate.Config.Hooks.BeforeCallOpts): string[]
---@field after_translate fun(otps: SmartTranslate.Config.Hooks.AfterCallOpts): string[]

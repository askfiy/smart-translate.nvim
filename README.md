<h3 align="center">
smart-translate.nvim
</h3>

<h6 align="center">
<img src="https://github.com/user-attachments/assets/837721df-350b-456c-9af7-e3c21c1d9e72" alt="" width="100%">
</h6>

<h6 align="center">
Powerful Caching System Builds Intelligent Translators
</h6>

<h6 align="center" style="font-size:.8rem; font-weight:lighter;color:#E95793">
<p>`smart-translate.nvim` is a very fast and elegantly designed plugin that provides you with an experience like no other translation plugin</p>.
</h6>

## Features

> The following features build the powerful `smart-translate.nvim`.

- Intelligent caching system, no need for repeated API calls, fast and accurate we have it all!
- Multiple engine support (`google`, `bing`, `deepl`), more will be added in the future.
- Rich export capabilities (floating window, split window, replace, clipboard)

## Install and Use

> [!IMPORTANT]
>
> - `curl`
> - [tree-sitter-http](https://github.com/rest-nvim/tree-sitter-http) is not mandatory, you will be missing some of the functionality.

To install using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
    "askfiy/smart-translate.nvim",
    cmd = { "Translate" },
    dependencies = {
        "askfiy/http.nvim" -- a wrapper implementation of the Python aiohttp library that uses CURL to send requests.
    }
    config = function()
        require("smart-translate").setup()
    end,

}
```

## Default Configuration

`smart-translate.nvim` uses `Google` translation by default. But you can change the default translation engine:

```lua
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
}
```

## Plugin Commands

The default command for the plugin is `Translate`, which provides the following multi-seed options.

- `--source`: the source language of the translation, supports `auto`.
- `--target`: target language of translation
- `--engine`: engine of translation
- `--handle`: Translation handler

Some special sub-options.

- `--comment`: translates the content of the comment block
- `--cleanup`: Clears all caches.

Here are some examples.

```vim
-- Manual translation, using the default configuration for scheduling translators
:Translate hello world

-- Automatically selects the original based on the current Mode
:Translate

--Select the Comment Block under the current cursor for translation.
:Translate --comment

-- with option parameters
:Translate --source=auto --target=zh-CN --engine=google --handle=float --comment

-- Translation of words
:normal! m'viw<cr>:Translate --target=zh-CN --source=en --handle=float<cr>`'
```

## Hook functions

`smart-translate.nvim` provides 2 `hooks` functions.

- `before_translate`
- `after_translate`

They take one argument, `Opts` as follows.

```lua
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
```

The `after_translate` always happens after the cache has been built. So you don't have to worry about your changes affecting the cache, it actually only affects the handling of the `handle`.

## Similar

The design and style of `smart-translate.nvim` is very much inspired by `translate.nvim`. We would like to thank you.

- [uga-rosa/translate.nvim](https://github.com/uga-rosa/translate.nvim)

## License

This plugin is licensed under the MIT License. See the [LICENSE](https://github.com/askfiy/smart-translate.nvim/blob/master/LICENSE) file for details.

## Contributing

Contributions are welcome! If you encounter a bug or want to enhance this plugin, feel free to open an issue or create a pull request.

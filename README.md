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
- Multiple engine support (`google`, `bing`, `deepl`) or build your own translator, more will be added in the future.
- Rich export capabilities (floating window, split window, replace, clipboard)

## Install and Use

> [!IMPORTANT]
>
> - `curl`
> - [tree-sitter-http](https://github.com/rest-nvim/tree-sitter-http) is not mandatory, you will be missing some of the functionality, such as `--comment`.

To install using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
    "askfiy/smart-translate.nvim",
    cmd = { "Translate" },
    dependencies = {
        "askfiy/http.nvim" -- a wrapper implementation of the Python aiohttp library that uses CURL to send requests.
    },
    opts = {},
}
```

## Default Configuration

`smart-translate.nvim` uses `Google` translation by default and renders the result in a floating window. You can change the defaults via `opts`:

- `default.cmds.source`: default source language (`"auto"` to detect)
- `default.cmds.target`: default target language (e.g. `"zh-CN"`, `"en"`, `"es"`)
- `default.cmds.handle`: default handler (`"float"`, `"split"`, `"replace"`, `"register"`, or a custom handle name)
- `default.cmds.engine`: default engine (`"google"`, `"bing"`, `"deepl"`, or a custom engine name)
- `default.cache`: whether to cache translations (boolean)
- `engine.deepl.api_key` / `engine.deepl.base_url`: credentials for the DeepL engine
- `hooks.before_translate` / `hooks.after_translate`: see [Hook functions](#hook-functions)
- `translator.engine` / `translator.handle`: see [Custom translator](#custom-translatoradvanced)


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
            -- Support SHELL variables, or fill in directly
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
    -- Custom translator
    translator = {
        engine = {},
        handle = {}
    }
}
```

## Plugin Commands

The default command for the plugin is `Translate`, which accepts the following options.

| Option      | Description                                              | Accepted values                                                   |
| ----------- | -------------------------------------------------------- | ----------------------------------------------------------------- |
| `--source`  | Source language of the original text                     | `auto` or any [Google Translate language code](https://cloud.google.com/translate/docs/languages) (e.g. `en`, `es`, `ja`) |
| `--target`  | Target language of the translation                       | Any [Google Translate language code](https://cloud.google.com/translate/docs/languages) (e.g. `zh-CN`, `de`, `fr`) |
| `--engine`  | Translation engine to use                                | `google`, `bing`, `deepl`, or any custom engine `name`            |
| `--handle`  | How the translation is rendered / delivered              | `float`, `split`, `replace`, `register`, or any custom handle `name` |

Special sub-options (flags, no value):

- `--comment`: translate only the content of the comment block under the cursor. Requires [tree-sitter-http](https://github.com/rest-nvim/tree-sitter-http).
- `--cleanup`: clear all caches.

### Available `--handle` values

| Handle     | Behavior                                                                                                                                  |
| ---------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| `float`    | Show the translation in a floating window anchored at the cursor. Closes on any key press. Supports paging with `<C-f>` / `<C-b>`.        |
| `split`    | Show the translation in a split window above the current window. The split follows the cursor and highlights the line being translated.  |
| `replace`  | Replace the original text in the buffer with the translation, preserving the original range.                                              |
| `register` | Write the translation into the current Vim register (`vim.v.register`). Use `"ay` etc. to choose the target register before invoking.     |

Custom handles defined under `translator.handle` are also valid values (use the value you set in `name`).

### Available `--engine` values

| Engine   | Notes                                                                                                                          |
| -------- | ------------------------------------------------------------------------------------------------------------------------------ |
| `google` | Default. No API key required.                                                                                                  |
| `bing`   | No API key required.                                                                                                           |
| `deepl`  | Requires `api_key` (and optionally `base_url`) under `engine.deepl`. The api_key field supports shell variables like `$DEEPL_API_KEY`. |

Custom engines defined under `translator.engine` are also valid values (use the value you set in `name`).

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

## language supports

The language is unified using Google Translate style:

- [languages](https://cloud.google.com/translate/docs/languages)

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

## Custom translator(Advanced)

`smart-translate.nvim` Support custom translator.

> [!TIP]
>
> - If the lines length of the original text and translation are consistent, the result will be stored in the cache
> - This will greatly improve the speed of subsequent repeated translations

Examples are as follows:

```lua
require("smart-translate").setup({
    translator = {
        engine = {
            {
                name = "translate-shell",
                ---@param source string
                ---@param target string
                ---@param original string[]
                ---@param callback fun(translation: string[])
                translate = function(source, target, original, callback)
                    -- 1. Optional: Do you need to convert the command line input language to the language supported by the translator?
                    source = "en"
                    target = "zh"
                    -- 2. Add your custom processing logic
                    vim.system(
                        {
                            "trans",
                            "-b",
                            ("%s:%s"):format(source, target),
                            table.concat(original, "\n"),
                        },
                        { text = true },
                        ---@param completed vim.SystemCompleted
                        vim.schedule_wrap(function(completed)
                            -- 3. Call callback for rendering processing, the translation needs to return string[]
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

                    --[[
                        SmartTranslate.Translator is an object that contains a lot of useful information:

                        ---@class SmartTranslate.Translator
                        ---@field public namespace integer                          -- Namespace
                        ---@field public special string[]                           -- Special operations, e.g., --comment/--cleanup
                        ---@field public buffer buffer                              -- The buffer the original text came from
                        ---@field public window window                              -- The window the original text came from
                        ---@field public mode string                                -- Mode when translation was invoked
                        ---@field public source string                              -- Source language
                        ---@field public target string                              -- Target language
                        ---@field public handle string                              -- Handler
                        ---@field public engine string                              -- Translation engine
                        ---@field public original string[]                          -- Original text
                        ---@field public public translation string[]                -- Translated text
                        ---@field public use_cache_translation boolean              -- Whether cache was hit
                        ---@field public range table<string, integer>[]             -- Original text range
                    ]]
                end,
            },
        },
    },
})
```

If you need to send an `http` request, you can use the [askfiy/http.nvim](https://github.com/askfiy/http.nvim) plug-in or `vim.system`, refer to [Google](./lua/smart-translate/core/engine/google.lua) translation implementation.

## Similar

The design and style of `smart-translate.nvim` is very much inspired by `translate.nvim`. We would like to thank you.

- [uga-rosa/translate.nvim](https://github.com/uga-rosa/translate.nvim)

## License

This plugin is licensed under the MIT License. See the [LICENSE](https://github.com/askfiy/smart-translate.nvim/blob/master/LICENSE) file for details.

## Contributing

Contributions are welcome! If you encounter a bug or want to enhance this plugin, feel free to open an issue or create a pull request.

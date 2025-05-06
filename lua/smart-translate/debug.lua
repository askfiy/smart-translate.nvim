local mod = "smart-translate"

local function reload()
    for k, _ in pairs(package.loaded) do
        if k:match(mod:gsub("-", "%%-")) then
            package.loaded[k] = nil
        end
    end
    require(mod).setup()
    vim.notify("reload completed")
    vim.cmd([[messages clear]])
end

vim.keymap.set(
    { "n" },
    "<leader>pr",
    reload,
    { silent = true, desc = "Reload plugin in debug mode" }
)

vim.keymap.set(
    { "n", "v" },
    "<leader>pt",
    ":Translate --handle=split --source=en --target=zh-CN --engine=google<cr>",
    { silent = true, desc = "Translate test" }
)

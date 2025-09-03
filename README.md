# NVim + LaTeX snippets setup

## NVim configuration

Copy `luasnip.lua` to `~/.config/nvim/lua/plugins` assuming you're using [LazyVim](https://www.lazyvim.org/)
as your plugin manager.

```lua
return {
    {
        "L3MON4D3/LuaSnip",
        build = "make install_jsregexp",
        dependencies = {
            "rafamadriz/friendly-snippets",
        },
        config = function()
            local ls = require("luasnip")

            require("luasnip.loaders.from_lua").lazy_load({
                paths = { "~/.config/nvim/lua/snippets", "~/.config/nvim/lua/snippets/tex" },
            })

            -- User config
            ls.config.set_config({
                enable_autosnippets = true,
                store_selection_keys = "<Tab>",
                update_events = "TextChanged,TextChangedI",
            })

            -- Keybindings
            -- Expand or jump forward
            vim.keymap.set({ "i", "s" }, "jk", function()
                if ls.expand_or_jumpable() then
                    return "<Plug>luasnip-expand-or-jump"
                else
                    return "jk"
                end
            end, { expr = true, silent = true })

            -- Jump backward
            vim.keymap.set({ "i", "s" }, "kl", function()
                if ls.expand_or_jumpable() then
                    return "<Plug>luasnip-jump-prev"
                else
                    return "kl"
                end
            end, { expr = true, silent = true })

            vim.keymap.set({ "i", "s" }, "<C-E>", function()
                if ls.choice_active() then
                    ls.change_choice(1)
                end
            end, { silent = true })

            ls.filetype_extend("tex", { "htb" })
        end,
    },
}
```

And copy `tex.lua` to `~/.config/nvim/lua/snippets` to keep thing organized.

> [!NOTE]
> Snippets are still in development, I'm currently learning the syntax and best practices
> of the plugin.

return {
	{
		"L3MON4D3/LuaSnip",
		build = "make instalL_jsregexp",
		dependencies = {
			"rafamadriz/friendly-snippets",
		},
		config = function()
			local ls = require("luasnip")

			require("luasnip.loaders.from_lua").lazy_load({ paths = { "~/.config/nvim/lua/snippets" } })

			-- User config
			ls.config.set_config({
				enable_autsnippets = true,
				store_selecction_keys = "<Tab>",
				update_events = "TextChanged,TextChangedI",
			})

			-- Keybindings
			-- Expand or jump forward
			vim.keymap.set({ "i", "s" }, "<Tab>", function()
				if ls.expand_or_jumpable() then
					return "<Plug>luasnip-expand-or-jump"
				else
					return "<Tab>"
				end
			end, { expr = true, silent = true })

			-- Jump backward
			vim.keymap.set({ "i", "s" }, "<S-Tab>", function()
				if ls.expand_or_jumpable() then
					return "<Plug>luasnip-jump-prev"
				else
					return "<S-Tab>"
				end
			end, { expr = true, silent = true })

			ls.filetype_extend("tex", { "htb" })
		end,
	},
}

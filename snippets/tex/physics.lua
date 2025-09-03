local ls = require("luasnip")
local extras = require("luasnip.extras")
local events = require("luasnip.util.events")
local fmt = require("luasnip.extras.fmt").fmt
local fmta = require("luasnip.extras.fmt").fmta
local rep = require("luasnip.extras").rep
local postfix = require("luasnip.extras.postfix").postfix
local line_begin = require("luasnip.extras").line_begin
local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local m = extras.match
local d = ls.dynamic_node
local c = ls.choice_node
-- local conds = require("luasnip.extras.expand_conditions")
-- local make_condition = require("luasnip.extras.conditions").make_condition

-- Context table
local tex = {}

-- Math context
tex.in_mathzone = function()
    return vim.fn["vimtex#syntax#in_mathzone"]() == 1
end

-- Plain text context
tex.in_text = function()
    return not tex.in_mathzone()
end

-- Comment detection
tex.in_comment = function() -- comment detection
    return vim.fn["vimtex#syntax#in_comment"]() == 1
end

-- Inside specific environment
local function env(name)
    local is_inside = vim.fn["vimtex#env#is_inside"](name)
    return (is_inside[1] > 0 and is_inside[2] > 0)
end

-- Expand command
local function cmd(name)
    return vim.fn["vimtex#syntax#in"](name) == 1
end

-- Helper function to insert space
_G.if_char_insert_space = function()
    if string.find(vim.v.char, "%a") then
        vim.v.char = " " .. vim.v.char
    end
end

-- Helper function to get visual selection
local get_visual = function(args, parent)
    if #parent.snippet.env.LS_SELECT_RAW > 0 then
        return sn(nil, i(1, parent.snippet.env.LS_SELECT_RAW))
    else -- If LS_SELECT_RAW is empty, return a blank insert node
        return sn(nil, i(1))
    end
end

local physics_ctes = {
    s({ trig = "hb", wordTrig = false, desc = "hbar" }, {
        t("\\hbar"),
    }, { condition = tex.in_mathzone }),
}

ls.add_snippets("tex", physics_ctes)

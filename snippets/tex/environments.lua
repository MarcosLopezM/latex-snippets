local ls = require("luasnip")
local extras = require("luasnip.extras")
local events = require("luasnip.util.events")
local fmta = require("luasnip.extras.fmt").fmta
local rep = extras.rep
local postfix = require("luasnip.extras.postfix").postfix
local line_begin = require("luasnip.extras").line_begin
local ai = require("luasnip.nodes.absolute_indexer")
local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
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

local table_node = function(args)
    local tabs = {}
    local count
    table = args[1][1]:gsub("%s", ""):gsub("|", "")
    count = table:len()
    for j = 1, count do
        local iNode
        iNode = i(j)
        tabs[2 * j - 1] = iNode
        if j ~= count then
            tabs[2 * j] = t(" & ")
        end
    end
    return sn(nil, tabs)
end

-- TODO: Fix recursion to avoid empty last line
rec_table = function()
    return sn(nil, {
        c(1, {
            t({ "" }),
            sn(nil, { t({ "\\\\", "" }), d(1, table_node, { ai[1] }), d(2, rec_table, { ai[1] }) }),
        }),
    })
end

local tabularray = {
    s(
        { trig = "tblr", wordTrig = false, desc = "Table environment from tabularray" },
        fmta(
            [[
      	\begin{tblr}{
        	colspec = <>,
          hlines,
          vlines,
        }
        	<>
          <>
        \end{tblr}
      ]],
            {
                i(1, "colspec"),
                d(2, table_node, { 1 }, {}),
                d(3, rec_table, { 1 }),
            }
        ),
        { condition = line_begin }
    ),
}

ls.add_snippets("tex", tabularray)

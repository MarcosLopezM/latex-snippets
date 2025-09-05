local ls = require("luasnip")
local extras = require("luasnip.extras")
local events = require("luasnip.util.events")
local fmta = require("luasnip.extras.fmt").fmta
local rep = require("luasnip.extras").rep
local line_begin = require("luasnip.extras").line_begin
local postfix = require("luasnip.extras.postfix").postfix
local r = ls.restore_node
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

-- Helper function to get visual selection
local get_visual = function(args, parent)
    if #parent.snippet.env.LS_SELECT_RAW > 0 then
        return sn(nil, i(1, parent.snippet.env.LS_SELECT_RAW))
    else -- If LS_SELECT_RAW is empty, return a blank insert node
        return sn(nil, i(1))
    end
end

local generate_matrix = function(_, snip)
    local rows = tonumber(snip.captures[2])
    local cols = tonumber(snip.captures[3])
    local nodes = {}
    local ins_indx = 1
    for j = 1, rows do
        table.insert(nodes, r(ins_indx, tostring(j) .. "x1", i(1)))
        ins_indx = ins_indx + 1
        for k = 2, cols do
            table.insert(nodes, t(" & "))
            table.insert(nodes, r(ins_indx, tostring(j) .. "x" .. tostring(k), i(1)))
            ins_indx = ins_indx + 1
        end
        table.insert(nodes, t({ "\\\\", "" }))
    end
    -- fix last node.
    nodes[#nodes] = t("\\\\")
    return sn(nil, nodes)
end

local differentiation_cmds = {
    s(
        { trig = "([mpo])dv", regTrig = true, wordTrig = false, desc = "Material, partial, and ordinary derivatives" },
        fmta(
            [[
              \<>{<>}{<>}
            ]],
            {
                f(function(_, snip)
                    return snip.captures[1] .. "dv"
                end),
                i(1, "f"),
                i(2, "x"),
            }
        ),
        { condition = tex.in_mathzone }
    ),

    s(
        { trig = "curl", wordTrig = false, desc = "Curl operator" },
        fmta(
            [[
              \nabla \mul{<>}
            ]],
            {
                i(1),
            }
        ),
        { condition = tex.in_mathzone }
    ),

    s(
        { trig = "div", wordTrig = false, desc = "Divergence operator" },
        fmta(
            [[
              \nabla \cdot{<>}
            ]],
            {
                i(1),
            }
        ),
        { condition = tex.in_mathzone }
    ),

    s(
        { trig = "grad", wordTrig = false, desc = "Gradient operator" },
        fmta(
            [[
                  \nabla{<>}
                ]],
            {
                i(1),
            }
        ),
        { condition = tex.in_mathzone }
    ),

    s(
        { trig = "lap", wordTrig = false, desc = "Laplacian operator" },
        fmta(
            [[
                  <>{<>}
                ]],
            {
                c(1, {
                    t("\\nabla^{2}"),
                    t("\\Delta"),
                }),
                i(2),
            }
        ),
        { condition = tex.in_mathzone }
    ),

    postfix({
        trig = ".dt",
        match_pattern = [[[\\%w%.%_%-%"%']+$]],
        desc = "First derivative of time",
        snippetType = "autosnippet",
    }, {
        f(function(_, parent)
            return "\\dot{" .. parent.snippet.env.POSTFIX_MATCH .. "}"
        end, {}),
    }, { condition = tex.in_mathzone }),

    postfix({
        trig = ".ddt",
        match_pattern = [[[\\%w%.%_%-%"%']+$]],
        desc = "Second derivative of time",
        snippetType = "autosnippet",
    }, {
        f(function(_, parent)
            return "\\ddot{" .. parent.snippet.env.POSTFIX_MATCH .. "}"
        end, {}),
    }, { condition = tex.in_mathzone }),

    postfix({
        trig = ".Dif",
        match_pattern = [[[\\%w%.%_%-%"%']+$]],
        desc = "Difference of quantity",
        snippetType = "autosnippet",
    }, {
        f(function(_, parent)
            return "\\adif{" .. parent.snippet.env.POSTFIX_MATCH .. "}"
        end, {}),
    }, { condition = tex.in_mathzone }),
}

local vectors = {
    postfix({
        trig = ".vec",
        match_pattern = [[[\\%w%.%_%-%"%']+$]],
        desc = "Vector",
        wordTrig = false,
        snippetType = "autosnippet",
    }, {
        f(function(_, parent)
            return "\\vect{" .. parent.snippet.env.POSTFIX_MATCH .. "}"
        end, {}),
    }, { condtion = tex.in_mathzone }),

    postfix({
        trig = ".hat",
        match_pattern = [[[\\%w%.%_%-%"%']+$]],
        desc = "Unitary vector or operator",
        wordTrig = false,
        snippetType = "autosnippet",
    }, {
        f(function(_, parent)
            return "\\op{" .. parent.snippet.env.POSTFIX_MATCH .. "}"
        end, {}),
    }, { condtion = tex.in_mathzone }),

    postfix({
        trig = ".bvec",
        match_pattern = [[[\\%w%.%_%-%"%']+$]],
        desc = "Bold vector",
        wordTrig = false,
        snippetType = "autosnippet",
    }, {
        f(function(_, parent)
            return "\\boldvect\\vect{" .. parent.snippet.env.POSTFIX_MATCH .. "}"
        end, {}),
    }, { condtion = tex.in_mathzone }),
}

local elements = function(_, snip)
    local nelems = tonumber(snip.captures[1])
    local elems = {}

    for j = 1, nelems do
        table.insert(elems, i(j))
        table.insert(elems, t("^{2}"))

        if j < nelems then
            table.insert(elems, t(" + "))
        end
    end

    return sn(nil, elems)
end

local math_objects = {
    s(
        {
            trig = "([pbvV])mat(%d+)x(%d+)",
            regTrig = true,
            wordTrig = false,
            desc = "[pbvV] matrices of dimension m by n (m x n)",
        },
        fmta(
            [[
      	\begin{<>}
        	<>
        \end{<>}
      ]],
            {
                f(function(_, snip)
                    return snip.captures[1] .. "NiceMatrix"
                end, { 1 }),
                d(1, generate_matrix),
                f(function(_, snip)
                    return snip.captures[1] .. "NiceMatrix"
                end, { 1 }),
            }
        ),
        { condtion = tex.in_mathzone }
    ),

    s(
        { trig = "norm(%d)", regTrig = true, wordTrig = false, desc = "Norm in 2D or 3D", snippetType = "autosnippet" },
        fmta([[\norm{<>}]], {
            d(1, elements),
        }),
        {
            condition = tex.in_mathzone,
        }
    ),

    s(
        { trig = "abs", wordTrig = false, desc = "Absolute value" },
        fmta([[\abs{<>}]], { i(1) }),
        { condition = tex.in_mathzone }
    ),

    s(
        { trig = "avg", wordTrig = false, desc = "Average of a quantity" },
        fmta([[\avg{<>}]], { i(1) }),
        { condition = tex.in_mathzone }
    ),
}

local integrals_cmds = {
    -- Integral snippets
    s(
        { trig = "int", wordTrig = false, desc = "Integrals" },
        fmta(
            [[
              \int<>\odif[sep-end=\medspace]{<>} <>
            ]],
            {
                c(1, {
                    fmta(
                        [[
            	_{<>}^{<>}
            ]],
                        {
                            i(1),
                            i(2),
                        }
                    ),
                    sn(nil, { t(" ") }),
                }),
                i(2),
                i(3),
            }
        ),
        { condition = tex.in_mathzone }
    ),
}

ls.add_snippets("tex", differentiation_cmds)
ls.add_snippets("tex", math_objects)
ls.add_snippets("tex", integrals_cmds)
ls.add_snippets("tex", vectors)

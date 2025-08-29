local ls = require("luasnip")
local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local d = ls.dynamic_node
-- local conds = require("luasnip.extras.expand_conditions")
-- local make_condition = require("luasnip.extras.conditions").make_condition
local events = require("luasnip.util.events")
local fmt = require("luasnip.extras.fmt").fmt
local fmta = require("luasnip.extras.fmt").fmta
local rep = require("luasnip.extras").rep
local line_begin = require("luasnip.extras").line_begin

-- Context table
local tex = {}

-- Math context
tex.in_mathzone = function()
    return vim.fn["vimtex#syntax#in_mathzone"]() == 1
end

local function in_mathzone()
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

-- this will only expand \qty{}{<here>} in the \SI command
-- function M.in_siunitx()
--     return cmd("texSIArgUnit")
-- end

-- helper for parentheses
local function make_paren_snip(trig, size)
    return s(
        { trig = trig .. "p", wordTrig = true }, -- "p" for parentheses
        { t(size .. "l("), i(1), t(size .. "r)") },
        { condition = in_mathzone }
    )
end

-- helper for brackets
local function make_bracket_snip(trig, size)
    return s(
        { trig = trig .. "b", wordTrig = true }, -- "b" for brackets
        { t(size .. "l["), i(1), t(size .. "r]") },
        { condition = in_mathzone }
    )
end

-- helper for braces
local function make_brace_snip(trig, size)
    return s(
        { trig = trig .. "c", wordTrig = true }, -- "c" for curly
        { t(size .. "l\\lbrace "), i(1), t(" " .. size .. "r\\rbrace") },
        { condition = in_mathzone }
    )
end

local math_envs = {
    -- Empheq environment
    s(
        { trig = "emeq", dscr = "Empheq env with box" },
        fmt(
            [[
                \begin{empheq}[box = \\<>]{<>}
                    <>
                \end{empheq}
            ]],
            { i(1, "style"), i(2, "env"), i(3) },
            { delimiters = "<>" }
        ),
        { condition = tex.in_text }
    ),

    -- Equation environment
    s({ trig = "eq", wordTrig = true }, {
        t({ "\\begin{equation}", "\t" }),
        i(1),
        t({ "", "\\end{equation}" }),
    }),

    -- align
    s({ trig = "al", wordTrig = true }, {
        t({ "\\begin{align}", "\t" }),
        i(1),
        t({ "", "\\end{align}" }),
    }),

    -- auto & for alignment: replace = with &=
    s({ trig = "=", wordTrig = false }, {
        t("&="),
    }, { condition = in_mathzone }),

    -- ^2
    s(
        {
            trig = "([%a%)%]%}])22",
            regTrig = true,
            wordTrig = false,
            snippetType = "autosnippet",
        },
        fmta("<>^{<>}", {
            f(function(_, snip)
                return snip.captures[1]
            end),
            t("2"),
        }),
        { condition = tex.in_mathzone }
    ),

    -- ^3
    s(
        {
            trig = "([%a%)%]%}])33",
            regTrig = true,
            wordTrig = false,
            snippetType = "autosnippet",
        },
        fmta("<>^{<>}", {
            f(function(_, snip)
                return snip.captures[1]
            end),
            t("3"),
        }),
        { condition = tex.in_mathzone }
    ),
    -- d/dt
    s({ trig = "dt", wordTrig = true }, {
        t("\\dot{"),
        i(1),
        t("}"),
    }, { condition = in_mathzone }),

    -- d^2/dt^2
    s({ trig = "ddt", wordTrig = true }, {
        t("\\ddot{"),
        i(1),
        t("}"),
    }, { condition = in_mathzone }),

    -- Aboxedmain
    s({ trig = "am", wordTrig = true }, {
        t("\\Aboxedmain{"),
        i(1, "lhs"),
        t(" &= "),
        i(2, "rhs"),
        t("}"),
    }, { condition = in_mathzone }),

    -- Aboxedsec
    s({ trig = "as", wordTrig = true }, {
        t("\\Aboxedsec{"),
        i(1, "lhs"),
        t(" &= "),
        i(2, "rhs"),
        t("}"),
    }, { condition = in_mathzone }),

    -- New line in align
    s({ trig = "ll", wordTrig = true }, {
        t("\\\\"),
    }, { condition = in_mathzone }),
}

local delim_snippets = {
    -- parentheses
    make_paren_snip("bg", "\\big"),
    make_paren_snip("Bg", "\\Big"),
    make_paren_snip("bgg", "\\bigg"),
    make_paren_snip("Bgg", "\\Bigg"),

    -- brackets
    make_bracket_snip("bg", "\\big"),
    make_bracket_snip("Bg", "\\Big"),
    make_bracket_snip("bgg", "\\bigg"),
    make_bracket_snip("Bgg", "\\Bigg"),

    -- braces
    make_brace_snip("bg", "\\big"),
    make_brace_snip("Bg", "\\Big"),
    make_brace_snip("bgg", "\\bigg"),
    make_brace_snip("Bgg", "\\Bigg"),
}

local ref_snippets = {
    s({ trig = "ref", wordTrig = true }, {
        t("\\zcref{"),
        i(1),
        t("}"),
    }),
}

local nom_snippets = {
    s({ trig = "qq", wordTrig = false }, {
        t("``"),
        i(1),
        t("''"),
    }),

    s({ trig = "oo", wordTrig = true }, {
        t("\\infty"),
    }, { condition = in_mathzone }),

    s({ trig = "-oo", wordTrig = true }, {
        t("-\\infty"),
    }, { condition = in_mathzone }),

    -- Exponential: e^{}
    s(
        { trig = "([^%a])ee", regTrig = true, wordTrig = false },
        fmta("<>\\mathrm{e}^{<>}", {
            f(function(_, snip)
                return snip.captures[1]
            end),
            d(1, get_visual),
        }),
        { condition = tex.in_mathzone }
    ),

    -- Square root: \sqrt{}
    s({ trig = "sq", wordTrig = false }, {
        t("\\sqrt{"),
        i(1),
        t("}"),
    }, { condition = in_mathzone }),

    -- Bold text: \textbf{}
    s("tbd", {
        t("\\textbf{"),
        d(1, get_visual),
        t("}"),
    }),

    -- Emphasized text: \emph{}
    s("tem", {
        t("\\emph{"),
        d(1, get_visual),
        t("}"),
    }),

    -- Differential
    s("dd", {
        t("\\odif{"),
        i(1),
        t("}"),
    }),

    -- Label equation
    s("leq", {
        t("\\label{eq:"),
        i(1),
        t("}"),
    }),

    -- Generic environment
    s(
        { trig = "new", dscr = "New environment", condition = line_begin },
        fmta(
            [[
              \begin{<>}
                  <>
              \end{<>}
            ]],
            {
                i(1),
                i(2),
                rep(1),
            }
        )
    ),

    -- Enumerate environment
    s(
        "enum",
        fmt(
            [[
\begin{{enumerate}}
    \item {}
\end{{enumerate}}
    ]],
            {
                i(1, "first item"),
            }
        )
    ),

    -- Itemize environment
    s(
        "itemize",
        fmt(
            [[
\begin{{itemize}}
    \item {}
\end{{itemize}}
    ]],
            {
                i(1, "first item"),
            }
        )
    ),

    s("itm", { t("\\item "), i(0) }),
    s("nn", { t("\\nonumber") }),

    s({ trig = "sp", wordTrig = false }, { t("^{"), i(1), t("}") }, { condition = in_mathzone }),
    s({ trig = "sb", wordTrig = false }, { t("_{"), i(1), t("}") }, { condition = in_mathzone }),
    s(
        { trig = "ss", wordTrig = false },
        { t("_{"), i(1, "i"), t("}^{"), i(2, "n"), t("}") },
        { condition = in_mathzone }
    ),

    s("mk", {
        t("\\("),
        i(1),
        t("\\)"),
    }, {
        callbacks = {
            -- index `-1` means the callback is on the snippet as a whole
            [-1] = {
                [events.leave] = function()
                    vim.cmd([[
            autocmd InsertCharPre <buffer> ++once lua _G.if_char_insert_space()
          ]])
                end,
            },
        },
    }),

    -- Vector snippets
    s({ trig = "vb" }, { t("\\vb{"), i(1, "v"), t("}") }, { condition = in_mathzone }),
    s({ trig = "va" }, { t("\\va{"), i(1, "v"), t("}") }, { condition = in_mathzone }),
    s({ trig = "eu" }, { t("\\eu{"), i(1, "i"), t("}") }, { condition = in_mathzone }),
    s({ trig = "uv" }, { t("\\uvec{"), i(1, "i"), t("}") }, { condition = in_mathzone }),
    s({ trig = "ei" }, { t("\\uveci") }, { condition = in_mathzone }),
    s({ trig = "ej" }, { t("\\uvecj") }, { condition = in_mathzone }),
    s({ trig = "ek" }, { t("\\uveck") }, { condition = in_mathzone }),
    s({ trig = "ev", wordTrig = false }, { t("\\ev{"), i(1, "i"), t("}") }, { condition = in_mathzone }),
    s({ trig = "evc", wordTrig = false }, { t("\\evc{"), i(1, "i"), t("}") }, { condition = in_mathzone }),

    -- Product snippets
    s(
        { trig = "dot", wordTrig = false },
        { t("\\dotp{"), i(1, "a"), t("}{"), i(2, "b"), t("}") },
        { condition = in_mathzone }
    ),
    s(
        { trig = "vecp", wordTrig = false },
        { t("\\crossp{"), i(1, "a"), t("}{"), i(2, "b"), t("}") },
        { condition = in_mathzone }
    ),

    -- Fraction snippets
    s({ trig = "frac", wordTrig = false }, { t("\\dfrac{"), i(1), t("}{"), i(2), t("}") }, { condition = in_mathzone }),
    s({ trig = "trac", wordTrig = false }, { t("\\tfrac{"), i(1), t("}{"), i(2), t("}") }, { condition = in_mathzone }),

    -- Integral snippets
    s(
        { trig = "int", wordTrig = false },
        { t("\\int "), i(1, "f(x)"), t(" "), t("\\odif{"), i(2, "x"), t("}") },
        { condition = in_mathzone }
    ),

    -- Matrix snippets
    s(
        { trig = "pmat", wordTrig = false },
        fmt(
            [[
\begin{{pNiceMatrix}}
    {}
\end{{pNiceMatrix}}
    ]],
            { i(1) }
        ),
        { condition = in_mathzone }
    ),

    s(
        { trig = "bmat", wordTrig = false },
        fmt(
            [[
\begin{{bNiceMatrix}}
    {}
\end{{bNiceMatrix}}
    ]],
            { i(1) }
        ),
        { condition = in_mathzone }
    ),
}

-- register snippets
ls.add_snippets("tex", nom_snippets)
ls.add_snippets("tex", delim_snippets)
ls.add_snippets("tex", math_envs)
ls.add_snippets("tex", ref_snippets)

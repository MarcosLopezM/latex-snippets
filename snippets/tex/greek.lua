local ls = require("luasnip")
local f = ls.function_node
local s = ls.snippet
local sn = ls.snippet_node
local d = ls.dynamic_node
local t = ls.text_node
local i = ls.insert_node

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

local greek = {
    a = { "\\alpha", "\\Alpha" },
    b = { "\\beta", "\\Beta" },
    g = { "\\gamma", "\\Gamma" },
    d = { "\\delta", "\\Delta" },
    e = { "\\epsilon", "\\Epsilon" },
    z = { "\\zeta", "\\Zeta" },
    q = { "\\theta", "\\Theta" },
    i = { "\\iota", "\\Iota" },
    k = { "\\kappa", "\\Kappa" },
    l = { "\\lambda", "\\Lambda" },
    m = { "\\mu", "\\Mu" },
    n = { "\\nu", "\\Nu" },
    x = { "\\xi", "\\Xi" },
    o = { "\\omicron", "\\Omicron" },
    p = { "\\pi", "\\Pi" },
    r = { "\\rho", "\\Rho" },
    s = { "\\sigma", "\\Sigma" },
    t = { "\\tau", "\\Tau" },
    y = { "\\upsilon", "\\Upsilon" },
    f = { "\\phi", "\\Phi" },
    c = { "\\chi", "\\Chi" },
    u = { "\\psi", "\\Psi" },
    w = { "\\omega", "\\Omega" },
    ve = { "\\varepsilon" },
    vf = { "\\varphi" },
}

local function match_greek(_, snip)
    local letter = snip.captures[1]
    local entry = greek[letter:lower()]

    if not entry then
        return sn(nil, t(""))
    end

    if letter:match("%u") then
        return sn(nil, t(entry[2] or entry[1]))
    else
        return sn(nil, t(entry[1]))
    end
end

local greek_letters = {
    s({ trig = ";(%a)", regTrig = true, desc = "Greek letters", snippetType = "autosnippet", wordTrig = false }, {
        d(1, match_greek),
    }, { condition = tex.in_mathzone }),
}

ls.add_snippets("tex", greek_letters)

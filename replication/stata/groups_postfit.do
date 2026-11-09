* Helper for the agreement runs: adds the coefficients and rates of the last fit (seed in `seed') to the open postfile `h'.
args h seed
matrix b = e(b)
matrix V = e(V)
local nm : colnames b
local j = 0
foreach n of local nm {
    local ++j
    post `h' (`seed') ("`n'") (b[1,`j']) (sqrt(V[`j',`j']))
}
foreach m in rates rates_beh {
    capture matrix r = e(`m')
    if _rc == 0 {
        matrix rs = e(`m'_se)
        local nm : colnames r
        local j = 0
        foreach n of local nm {
            local ++j
            post `h' (`seed') ("`=cond("`m'" == "rates_beh", "beh", "")'`n'") (r[1,`j']) (rs[1,`j'])
        }
    }
}

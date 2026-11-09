* Reads the four Dutch school classes (eight csv files) and stacks them into one data set:
* wave networks w1 and w2 are block-diagonal (no ties between classes); variable class is 1..4.
mata: B1 = J(0, 0, .); B2 = J(0, 0, .)
local sizes ""
forvalues s = 1/4 {
    forvalues w = 1/2 {
        quietly import delimited using "data/groups/school`s'_wave`w'.csv", clear
        local n = _N
        quietly mkmat v1-v`n', matrix(X)
        matrix X = X - diag(vecdiag(X))
        mata: B`w' = blockdiag(B`w', st_matrix("X"))
    }
    local sizes "`sizes' `n'"
}
clear
nwclear
mata: st_matrix("G1", B1); st_matrix("G2", B2)
local N = rowsof(G1)
quietly set obs `N'
quietly generate byte class = .
local first = 1
local s = 0
foreach n of local sizes {
    local ++s
    quietly replace class = `s' in `first'/`=`first'+`n'-1'
    local first = `first' + `n'
}
nwset, mat(G1) directed name(w1) nooutput
nwset, mat(G2) directed name(w2) nooutput

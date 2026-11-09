* Example 1, agreement with RSiena: the same model fitted with ten seeds; writes results/groups/ex1_nwsaom.csv (compared in R/06_groups_compare.R)
do stata/setup.do
set linesize 100
capture mkdir results
capture mkdir results/groups
do stata/groups_stack_classes.do
tempname h
postfile `h' seed str20 name double(theta se) using results/groups/ex1_nwsaom.dta, replace
forvalues s = 1/10 {
    quietly nwsaom, waves(w1 w2) groups(class) outdegree reciprocity transtrip seed(`s')
    matrix b = e(b)
    matrix V = e(V)
    local nm : colnames b
    local j = 0
    foreach n of local nm {
        local ++j
        post `h' (`s') ("`n'") (b[1,`j']) (sqrt(V[`j',`j']))
    }
    matrix r = e(rates)
    matrix rs = e(rates_se)
    local nm : colnames r
    local j = 0
    foreach n of local nm {
        local ++j
        post `h' (`s') ("`n'") (r[1,`j']) (rs[1,`j'])
    }
}
postclose `h'
use results/groups/ex1_nwsaom.dta, clear
export delimited using results/groups/ex1_nwsaom.csv, replace
erase results/groups/ex1_nwsaom.dta

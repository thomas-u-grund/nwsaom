* Example 3, agreement with RSiena: ten seeds; writes results/groups/ex3a_nwsaom.csv (co-evolution) and results/groups/ex3b_nwsaom.csv (unequal waves)
do stata/setup.do
set linesize 100
capture mkdir results
capture mkdir results/groups
do stata/groups_stack_s50.do
tempname h
postfile `h' seed str20 name double(theta se) using results/groups/ex3a.dta, replace
forvalues s = 1/10 {
    quietly nwsaom, waves(g1 g2 g3) groups(group) outdegree reciprocity transtrip behavior(alc1 alc2 alc3) linear quadratic avalt behegox behaltx seed(`s')
    do stata/groups_postfit.do `h' `s'
}
postclose `h'
use results/groups/ex3a.dta, clear
export delimited using results/groups/ex3a_nwsaom.csv, replace
erase results/groups/ex3a.dta
do stata/groups_stack_s50.do
tempname h2
postfile `h2' seed str20 name double(theta se) using results/groups/ex3b.dta, replace
forvalues s = 1/10 {
    quietly nwsaom, waves(g1 g2 g3) groups(group) gwaves(2: 1 2 | 3: 2 3) outdegree reciprocity transtrip seed(`s')
    do stata/groups_postfit.do `h2' `s'
}
postclose `h2'
use results/groups/ex3b.dta, clear
export delimited using results/groups/ex3b_nwsaom.csv, replace
erase results/groups/ex3b.dta

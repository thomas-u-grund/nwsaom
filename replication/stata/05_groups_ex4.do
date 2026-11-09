* Example 4, agreement with RSiena: ten seeds; writes results/groups/ex4_nwsaom.csv (time test and score test statistics)
do stata/setup.do
set linesize 100
capture mkdir results
capture mkdir results/groups
do stata/groups_stack_s50.do
tempname h
postfile `h' seed str20 what int k double(c df) using results/groups/ex4.dta, replace
forvalues s = 1/10 {
    quietly nwsaom, waves(g1 g2 g3) groups(group) outdegree reciprocity transtrip egox(alc) altx(alc) unconditional seed(`s')
    quietly estat timetest, fixrates
    post `h' (`s') ("joint") (0) (r(chi2)) (r(df))
    matrix E = r(effect)
    forvalues k = 1/`=rowsof(E)' {
        post `h' (`s') ("effect") (`k') (E[`k',1]) (E[`k',2])
    }
    matrix G = r(group)
    forvalues k = 1/`=rowsof(G)' {
        post `h' (`s') ("group") (`k') (G[`k',1]) (G[`k',2])
    }
    matrix P = r(period)
    forvalues k = 1/`=rowsof(P)' {
        post `h' (`s') ("period") (`k') (P[`k',1]) (P[`k',2])
    }
    quietly nwsaom, waves(g1 g2 g3) groups(group) outdegree reciprocity transtrip egox(alc) altx(alc) fix(egox(alc) altx(alc)) unconditional seed(`s')
    quietly estat score
    post `h' (`s') ("score") (0) (r(chi2)) (r(df))
}
postclose `h'
use results/groups/ex4.dta, clear
export delimited using results/groups/ex4_nwsaom.csv, replace
erase results/groups/ex4.dta

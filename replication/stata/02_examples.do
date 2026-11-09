* Table "The estimates of two examples, nwsaom and RSiena" (Section 5.7): the article's examples E1, E3, E4, E5
* with seeds 12345, 1, 2, 3, 4 and Phase 3 with 1,000 simulations; estimates and standard errors to
* results/examples/val_examples.csv. R/02_examples.R fits the same models in RSiena; then
*     python3 tools/compare_examples.py
* prints the comparison. About 2 minutes.
do stata/setup.do
capture mkdir results
capture mkdir results/examples
cd results/examples
nwwebuse glasgow, nwclear
tempname pf
postfile `pf' str4 model long seed str30 param double(est se tmax) using val_examples.dta, replace
local cmd_E1 "waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity cycle3 nodematch(smoke1)"
local cmd_E3 "waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip"
local cmd_E4 "waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity behsim behavior(alcohol1 alcohol2 alcohol3) linear avalt"
local cmd_E5 "wave1(glasgow1) wave2(glasgow2) outdegree reciprocity behavior(alcohol1 alcohol2) linear quadraticendow quadraticcreation"
foreach m in E1 E3 E4 E5 {
	foreach s in 12345 1 2 3 4 {
		quietly nwsaom, `cmd_`m'' k0(50) k3(1000) seed(`s')
		matrix b = e(b)
		matrix V = e(V)
		local nm : colnames b
		local j 0
		foreach n of local nm {
			local ++j
			post `pf' ("`m'") (`s') ("`n'") (b[1,`j']) (sqrt(V[`j',`j'])) (e(tconv_max))
		}
		capture confirm matrix e(rates)
		if !_rc {
			matrix r = e(rates)
			matrix rs = e(rates_se)
			forvalues p = 1/`=colsof(r)' {
				post `pf' ("`m'") (`s') ("netrate`p'") (r[1,`p']) (rs[1,`p']) (e(tconv_max))
			}
		}
		else post `pf' ("`m'") (`s') ("netrate1") (e(rate)) (e(rate_se)) (e(tconv_max))
		capture confirm matrix e(rates_beh)
		if !_rc {
			matrix r = e(rates_beh)
			matrix rs = e(rates_beh_se)
			forvalues p = 1/`=colsof(r)' {
				post `pf' ("`m'") (`s') ("behrate`p'") (r[1,`p']) (rs[1,`p']) (e(tconv_max))
			}
		}
		else if e(rate_beh) < . post `pf' ("`m'") (`s') ("behrate1") (e(rate_beh)) (e(rate_beh_se)) (e(tconv_max))
	}
}
postclose `pf'
use val_examples.dta, clear
export delimited using val_examples.csv, replace
erase val_examples.dta
cd "$REP"

* The same simulation (see R/15_fixed_sim.R, which must run first): nwsaom simulates 1,000 times at RSiena's
* estimates of N1, N2 and R1, five times (seeds 1 to 5), with all parameters fixed (fix(_all) k3(1000)), and
* records the t-ratio of every statistic (mean deviation from the observed value over its standard deviation).
* Run from the replication folder:  stata -e do stata/15_fixed_sim.do   (about a minute)
* Writes results/fixedsim/nwsaom_fixedsim.csv.
quietly do stata/setup.do
include stata/07_bench_models.do
* RSiena's short names of the effects, in the order of nwsaom's e(b) (which theta0() follows; for R1 not the order of the command)
local rs_N1 "density recip"
local rs_N2 "density recip gwespFF"
local rs_R1 "density recip sameX altX egoX inPopSqrt transRecTrip gwespFF outPopSqrt simX"
tempname pf
postfile `pf' str8 program str4 model seed str16 rsname tconv using results/fixedsim/nwsaom_fixedsim.dta, replace
foreach m in N1 N2 R1 {
	preserve
	import delimited using results/fixedsim/theta.csv, clear varnames(1) stringcols(1 2)
	local th ""
	foreach r of local rs_`m' {
		quietly summarize value if model == "`m'" & rsname == "`r'", meanonly
		if r(N) != 1 {
			di as error "no RSiena estimate for `m' `r'"
			exit 459
		}
		local th "`th' `=string(r(mean), "%21.15g")'"
	}
	restore
	_bench_data `m'
	local np : word count `rs_`m''
	forvalues s = 1/5 {
		quietly nwsaom, `cmd_`m'' theta0(`th') fix(_all) k3(1000) seed(`s')
		matrix t = e(tconv)
		forvalues j = 1/`np' {
			local r : word `j' of `rs_`m''
			post `pf' ("nwsaom") ("`m'") (`s') ("`r'") (t[1,`j'])
		}
	}
}
postclose `pf'
use results/fixedsim/nwsaom_fixedsim.dta, clear
export delimited using results/fixedsim/nwsaom_fixedsim.csv, replace
erase results/fixedsim/nwsaom_fixedsim.dta
collapse (mean) tconv, by(model rsname)
list, noobs sepby(model)

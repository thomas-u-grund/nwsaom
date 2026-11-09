* Timing with a fixed workload (see R/16_fixed_workload.R): nwsaom simulates N1, N2 and R1 at RSiena's
* estimates (results/fixedsim/theta.csv) 1,000 and 5,000 times with all parameters fixed (fix(_all) k3()),
* on one thread, five times each, alternating, after a warm-up. The difference of the medians is the time of
* 4,000 simulations. Run nothing else while timing.
* Run from the replication folder:  stata -e do stata/16_fixed_workload.do   (about a minute)
* Writes results/fixedsim/nwsaom_workload.csv.
quietly do stata/setup.do
include stata/07_bench_models.do
local rs_N1 "density recip"
local rs_N2 "density recip gwespFF"
* in the order of nwsaom's e(b), which theta0() follows
local rs_R1 "density recip sameX altX egoX inPopSqrt transRecTrip gwespFF outPopSqrt simX"
tempname pf
postfile `pf' str8 program str4 model rep n3 secs using results/fixedsim/nwsaom_workload.dta, replace
foreach m in N1 N2 R1 {
	preserve
	import delimited using results/fixedsim/theta.csv, clear varnames(1) stringcols(1 2)
	local th ""
	foreach r of local rs_`m' {
		quietly summarize value if model == "`m'" & rsname == "`r'", meanonly
		local th "`th' `=string(r(mean), "%21.15g")'"
	}
	restore
	_bench_data `m'
	quietly nwsaom, `cmd_`m'' theta0(`th') fix(_all) k3(1000) seed(99) cores(1)
	local t1 ""
	local t5 ""
	forvalues r = 1/5 {
		foreach n3 in 1000 5000 {
			timer clear 1
			timer on 1
			quietly nwsaom, `cmd_`m'' theta0(`th') fix(_all) k3(`n3') seed(`r') cores(1)
			timer off 1
			quietly timer list 1
			post `pf' ("nwsaom") ("`m'") (`r') (`n3') (r(t1))
		}
	}
}
postclose `pf'
use results/fixedsim/nwsaom_workload.dta, clear
export delimited using results/fixedsim/nwsaom_workload.csv, replace
erase results/fixedsim/nwsaom_workload.dta
collapse (median) secs, by(model n3)
reshape wide secs, i(model) j(n3)
generate us_per_sim = 1e6 * (secs5000 - secs1000) / 4000
list, noobs

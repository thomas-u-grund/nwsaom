* The Mata engine against the compiled plugin on benchmark model N1 (Section "How a fit runs": a median of
* 47 seconds in Mata against 0.2 seconds in the plugin). The global NWSAOM_NONATIVE, nwsaom's documented
* testing switch, makes nwsaom use its Mata engine instead of the plugin. Seeds 1 to 3, one thread, first with
* the Mata engine and then with the plugin; about 3 minutes. Writes results/benchmark/mata_engine.csv with
* the time and the estimates of each fit.
do stata/setup.do
include stata/07_bench_models.do
_bench_data N1
tempname pf
postfile `pf' long seed str8 engine double(secs outdegree reciprocity rate) using results/benchmark/mata_engine.dta, replace
foreach eng in mata native {
global NWSAOM_NONATIVE = cond("`eng'" == "mata", 1, 0)
forvalues s = 1/3 {
	timer clear 1
	timer on 1
	quietly nwsaom, `cmd_N1' seed(`s') cores(1)
	timer off 1
	quietly timer list 1
	di as text "seed `s': engine `e(engine)', " %6.1f r(t1) " seconds"
	post `pf' (`s') ("`e(engine)'") (r(t1)) (_b[outdegree]) (_b[reciprocity]) (e(rate))
}
}
global NWSAOM_NONATIVE
postclose `pf'
use results/benchmark/mata_engine.dta, clear
export delimited using results/benchmark/mata_engine.csv, replace
erase results/benchmark/mata_engine.dta
tabstat secs, by(engine) statistics(n p50 min max)

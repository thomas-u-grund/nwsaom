* The cost of a Phase 2 step, where Mata calls the plugin once per simulation, against the cost of a
* simulation in the batches of Phases 1 and 3 (for Appendix D of the nwsaom manual). Models N1 and N2, seed 1, one
* thread. The same seed gives the same Phases 1 and 2 whatever the length of Phase 3, so the difference
* between fits with k3(1000) and k3(5000) is the time of 4,000 batched simulations. The rest of the fit with
* k3(1000), less 1,050 batched simulations, is charged to Phase 2 (which also holds the set-up of the fit,
* so the cost per Phase 2 step is if anything overstated). The Phase 2 count comes from the trace, to within
* 24 per subphase. Run nothing else while timing.
* Run from the replication folder:  stata -e do stata/14_phase_cost.do   (about a minute)
quietly do stata/setup.do
include stata/07_bench_models.do
foreach m in N1 N2 {
	_bench_data `m'
	* the Phase 2 count of seed 1
	global NWSAOM_TRACE 1
	quietly log using phase_cost_trace.log, text replace name(tr) nomsg
	nwsaom, `cmd_`m'' seed(1) cores(1)
	quietly log close tr
	global NWSAOM_TRACE
	forvalues k = 1/4 {
		local last`k' 0
	}
	tempname fh
	file open `fh' using phase_cost_trace.log, read text
	file read `fh' line
	while r(eof) == 0 {
		if substr(`"`line'"', 1, 10) == "TRACE sub " & word(`"`line'"', 4) == "it" {
			local k = real(word(`"`line'"', 3))
			local it = real(word(`"`line'"', 5))
			if `it' > `last`k'' local last`k' = `it'
		}
		file read `fh' line
	}
	file close `fh'
	erase phase_cost_trace.log
	local n2 = 0
	forvalues k = 1/4 {
		local n2 = `n2' + cond(`last`k'' >= 25, `last`k'' + 12, `last`k'')
	}
	* warm-up, then 5 fits of each length, alternating
	quietly nwsaom, `cmd_`m'' seed(1) cores(1)
	local t1 ""
	local t5 ""
	forvalues r = 1/5 {
		foreach k3 in 1000 5000 {
			timer clear 1
			timer on 1
			quietly nwsaom, `cmd_`m'' seed(1) cores(1) k3(`k3')
			timer off 1
			quietly timer list 1
			if `k3' == 1000 local t1 "`t1' `r(t1)'"
			else local t5 "`t5' `r(t1)'"
		}
	}
	mata: t1 = strtoreal(tokens(st_local("t1"))); t5 = strtoreal(tokens(st_local("t5")))
	mata: st_local("m1", strofreal(sort(t1', 1)[3])); st_local("m5", strofreal(sort(t5', 1)[3]))
	local b = (`m5' - `m1') / 4000
	local p2 = (`m1' - 1050 * `b') / `n2'
	display as text "`m': fit with k3(1000) " as result %6.3f `m1' as text " s, with k3(5000) " as result %6.3f `m5' as text " s (medians of 5)"
	display as text "`m': batched simulation " as result %7.1f 1e6 * `b' as text " microseconds; Phase 2 step " as result %7.1f 1e6 * `p2' as text " microseconds (about `n2' steps); ratio " as result %4.2f `p2' / `b'
}

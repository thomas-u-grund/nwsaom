* How many simulations nwsaom runs in each phase of a fit (for Appendix D of the nwsaom manual): benchmark models
* N1, N2 and R1, seeds 1 to 10, default settings as in the benchmark. R/11_phase_counts.R counts the same
* for RSiena. nwsaom does not store the number of Phase 2 iterations; its documented trace switch (global
* NWSAOM_TRACE 1) prints the Phase 1 replicates and every 25th Phase 2 iteration of each subphase, so the
* Phase 2 count is known to within 24 per subphase (columns phase2_lo and phase2_hi). Phase 3 is k3().
* Versions with RSiena's repeated subphases (after 1.5.2) also print "TRACE sub # repeated after it #": the
* length of a repeated run is then known exactly and added to its subphase (column repeats counts them).
* Run from the replication folder: do stata/11_phase_counts.do   (about a minute)
* Writes results/phases/nwsaom_phases.csv.
do stata/setup.do
include stata/07_bench_models.do
capture mkdir results
capture mkdir results/phases
tempname pf fh
postfile `pf' str8 program str4 model seed nparam phase1 phase2_lo phase2_hi phase3 repeats using results/phases/nwsaom_phases.dta, replace
foreach m in N1 N2 R1 {
	forvalues s = 1/10 {
		_bench_data `m'
		global NWSAOM_TRACE 1
		quietly log using results/phases/trace.log, text replace name(tr) nomsg
		nwsaom, `cmd_`m'' seed(`s') cores(1)
		quietly log close tr
		global NWSAOM_TRACE
		local np = colsof(e(b))
		* parse the trace: "TRACE phase 1: replicates #" and "TRACE sub # it # ..."
		local p1 .
		forvalues k = 1/4 {
			local last`k' 0
			local done`k' 0
		}
		local nrep 0
		file open `fh' using results/phases/trace.log, read text
		file read `fh' line
		while r(eof) == 0 {
			if strpos(`"`line'"', "TRACE phase 1: replicates") {
				local p1 = real(word(subinstr(`"`line'"', ",", " ", .), 5))
			}
			if substr(`"`line'"', 1, 10) == "TRACE sub " {
				local k = real(word(`"`line'"', 3))
				if word(`"`line'"', 4) == "repeated" {
					local done`k' = `done`k'' + real(word(`"`line'"', 7))
					local last`k' 0
					local ++nrep
				}
				else {
					local it = real(word(`"`line'"', 5))
					if `it' > `last`k'' local last`k' = `it'
				}
			}
			file read `fh' line
		}
		file close `fh'
		local lo = 0
		local hi = 0
		forvalues k = 1/4 {
			local lo = `lo' + `done`k'' + `last`k''
			local hi = `hi' + `done`k'' + cond(`last`k'' >= 25, `last`k'' + 24, `last`k'')
		}
		post `pf' ("nwsaom") ("`m'") (`s') (`np') (`p1') (`lo') (`hi') (1000) (`nrep')
	}
}
postclose `pf'
erase results/phases/trace.log
use results/phases/nwsaom_phases.dta, clear
export delimited using results/phases/nwsaom_phases.csv, replace
erase results/phases/nwsaom_phases.dta
list, noobs sepby(model)

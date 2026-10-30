* Several co-evolving behaviors with groups() (protocol 152). Data: s50 cut into three groups (see test_nwsaom_groups.do) with alcohol (s50a) and smoking (s50s) as behaviors. Reference: dev/saom_rsiena_groups.R coevmb (RSiena 1.6.14, 10 seeds, unconditional).
* Run: NWCORE=<core dir> stata -e do cscripts/test_nwsaom_groups_mb.do; PASS marker: "PASS: coevmb"
cscript
set linesize 255
local nwcore : env NWCORE
if `"`nwcore'"' == "" {
	di as error "set the environment variable NWCORE to the directory of the nwcommands (core) package"
	exit 198
}
adopath ++ `"`nwcore'"'
adopath ++ `"`c(pwd)'"'
quietly do `"`nwcore'/unw_core.do"'
mata: mata set matalnum on
do unw_saom.do

* fits nwsaom for 3 seeds and keeps the mean estimates (effects, rates, behavior rates with a b prefix, rate-covariate coefficients) in matrix __gm
capture program drop __gfit
program define __gfit
	syntax , OPTS(string) [UNCOND]
	local first 1
	forvalues s = 1/3 {
		quietly nwsaom, waves(g1 g2 g3) groups(group) `opts' k0(30) k3(1000) seed(`s') cores(1) `uncond'
		matrix __gb = e(b), e(rates)
		capture matrix __gbb = e(rates_beh)
		if _rc == 0 {
			local nn : colnames __gbb
			local nn2 ""
			foreach n of local nn {
				local nn2 "`nn2' b`n'"
			}
			matrix colnames __gbb = `nn2'
			matrix __gb = __gb, __gbb
		}
		foreach rc in ratecoefs behratecoefs {
			capture matrix __gc = e(`rc')
			if _rc == 0 {
				local nn : colnames __gc
				local nn2 ""
				foreach n of local nn {
					local nn2 "`nn2' `=cond("`rc'" == "ratecoefs", "rc_", "brc_")'`n'"
				}
				matrix colnames __gc = `nn2'
				matrix __gb = __gb, __gc
			}
		}
		if `first' matrix __gm = __gb
		else matrix __gm = __gm + __gb
		local first 0
	}
	matrix __gm = __gm / 3
end

* compares the mean estimate of a coefficient with the RSiena mean of an effect
capture program drop __gchk
program define __gchk
	args nwsname rname tol rel
	local j = colnumb(__gm, "`nwsname'")
	if `j' >= . {
		di as error "no coefficient `nwsname'"
		exit 111
	}
	local x = __gm[1, `j']
	quietly frame ref: summarize theta if name == "`rname'", meanonly
	if r(N) == 0 {
		di as error "RSiena has no effect `rname'"
		exit 111
	}
	local y = r(mean)
	local t = `tol' + `rel' * abs(`y')
	if abs(`x' - `y') > `t' {
		di as error "`nwsname' = `x' but RSiena `rname' = `y' (tolerance `t')"
		exit 9
	}
end

nwclear

import delimited "dev/saom_groups_actors.csv", clear

import delimited "dev/saom_groups_mbactors.csv", clear
forvalues w = 1/3 {
	preserve
	import delimited "dev/saom_groups_w`w'.csv", clear varnames(nonames)
	mkmat v*, matrix(Gbase`w')
	restore
}
save "__groups_mb.dta", replace
nwclear
use "__groups_mb.dta", clear
forvalues w = 1/3 {
	nwset, mat(Gbase`w') name(g`w') nooutput
}
frame create ref
frame ref: import delimited "dev/saom_rsiena_groups_coevmb_cond0.csv", clear
* three seeds: the mean of the effects, of the network rates and of the rates of the two behaviors (columns ra_period#, rs_period#)
local opts outdegree reciprocity transtrip behavior(alc1 alc2 alc3 : linear quadratic avalt | smk1 smk2 smk3 : linear quadratic avalt) behegox behaltx
forvalues s = 1/3 {
	quietly nwsaom, waves(g1 g2 g3) groups(group) `opts' k0(30) k3(1000) seed(`s') cores(1) unconditional
	matrix __gb = e(b), e(rates)
	foreach nm in alc smk {
		matrix __gr = e(rates_beh)
		matrix __gr = __gr["rate_`nm'", 1...]
		local cn : colnames __gr
		local cn2 ""
		foreach c of local cn {
			local cn2 "`cn2' r`=substr("`nm'", 1, 1)'_`c'"
		}
		matrix colnames __gr = `cn2'
		matrix __gb = __gb, __gr
	}
	if `s' == 1 matrix __gm = __gb
	else matrix __gm = __gm + __gb
}
matrix __gm = __gm / 3
assert e(ngroups) == 3 & colsof(e(rates_period)) == 6
assert e(rates_period)[1, 6] == 8
__gchk outdegree "outdegree (density)" 0.12 0
__gchk reciprocity "reciprocity" 0.12 0
__gchk transtrip "transitive triplets" 0.12 0
__gchk behegox "alc ego" 0.12 0
__gchk behaltx "alc alter" 0.12 0
__gchk beh_alc_linear "alc linear shape" 0.12 0
__gchk beh_alc_quadratic "alc quadratic shape" 0.12 0
__gchk beh_alc_avalt "alc average alter" 0.12 0
__gchk beh_smk_linear "smk linear shape" 0.2 0
__gchk beh_smk_quadratic "smk quadratic shape" 0.25 0
__gchk beh_smk_avalt "smk average alter" 0.3 0
foreach p in 1 2 4 5 7 8 {
	__gchk period`p' "constant net rate (period `p')" 0.1 0.08
	__gchk ra_period`p' "rate alc (period `p')" 0.1 0.08
	__gchk rs_period`p' "rate smk (period `p')" 0.1 0.08
}
frame drop ref
display "PASS: coevmb (uncond) agrees with RSiena"

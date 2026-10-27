* Joint estimation of several groups (groups() option, RSiena's sienaGroupCreate() + siena07()).
* Data: the RSiena data s501-s503 cut into three groups of 15, 20 and 15 actors (actors 1-15, 16-35, 36-50; ties between the groups removed),
* with the alcohol covariate s50a (changing covariate = its three waves; behavior = the same values; dyadic covariate: similar alcohol within a group).
* Reference: dev/saom_rsiena_groups.R (RSiena 1.6.14, 10 seeds, n3 = 2000, conditional and unconditional): dev/saom_rsiena_groups_<feature>_cond<0/1>.csv.
* Each feature is fitted with 3 seeds and the mean estimate is compared with the mean of the 10 RSiena runs (tolerance 0.12 for effects, 8% + 0.1 for rates).
* Rate parameters are one per period of each group, numbered as RSiena numbers them (the switch from the last wave of a group to the first wave of the next one is
* not a period): period1 period2 period4 period5 period7 period8. PASS marker: "PASS: <feature>".
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
forvalues w = 1/3 {
	preserve
	import delimited "dev/saom_groups_w`w'.csv", clear varnames(nonames)
	mkmat v*, matrix(Gbase`w')
	restore
}
save "__groups_base.dta", replace

import delimited "dev/saom_groups_cactors.csv", clear
forvalues w = 1/3 {
	preserve
	import delimited "dev/saom_groups_cw`w'.csv", clear varnames(nonames)
	mkmat v*, matrix(Gcomp`w')
	restore
}
save "__groups_comp.dta", replace

* the missing-tie masks and the dyadic covariate
forvalues w = 1/3 {
	matrix Mm`w' = J(50, 50, 0)
}
foreach w in 2 3 {
	preserve
	import delimited "dev/saom_groups_mm`w'.csv", clear varnames(nonames)
	mkmat v*, matrix(Mm`w')
	restore
}
preserve
import delimited "dev/saom_groups_dyad.csv", clear varnames(nonames)
mkmat v*, matrix(Md)
restore

* ---- base
nwclear
use "__groups_base.dta", clear
forvalues w = 1/3 {
	nwset, mat(Gbase`w') name(g`w') nooutput
}
frame create ref
frame ref: import delimited "dev/saom_rsiena_groups_base_cond1.csv", clear
__gfit, opts(outdegree reciprocity transtrip cycle3 egox(alc) altx(alc)) 
__gchk outdegree "outdegree (density)" 0.12 0
__gchk reciprocity "reciprocity" 0.12 0
__gchk transtrip "transitive triplets" 0.12 0
__gchk cycle3 "3-cycles" 0.12 0
__gchk altx_alc "alc alter" 0.12 0
__gchk egox_alc "alc ego" 0.12 0
__gchk period1 "rate 1" 0.1 0.08
__gchk period2 "rate 2" 0.1 0.08
__gchk period4 "rate 3" 0.1 0.08
__gchk period5 "rate 4" 0.1 0.08
__gchk period7 "rate 5" 0.1 0.08
__gchk period8 "rate 6" 0.1 0.08
frame drop ref
display "PASS: base (cond) agrees with RSiena"

frame create ref
frame ref: import delimited "dev/saom_rsiena_groups_base_cond0.csv", clear
__gfit, opts(outdegree reciprocity transtrip cycle3 egox(alc) altx(alc)) uncond
__gchk outdegree "outdegree (density)" 0.12 0
__gchk reciprocity "reciprocity" 0.12 0
__gchk transtrip "transitive triplets" 0.12 0
__gchk cycle3 "3-cycles" 0.12 0
__gchk altx_alc "alc alter" 0.12 0
__gchk egox_alc "alc ego" 0.12 0
__gchk period1 "constant net rate (period 1)" 0.1 0.08
__gchk period2 "constant net rate (period 2)" 0.1 0.08
__gchk period4 "constant net rate (period 4)" 0.1 0.08
__gchk period5 "constant net rate (period 5)" 0.1 0.08
__gchk period7 "constant net rate (period 7)" 0.1 0.08
__gchk period8 "constant net rate (period 8)" 0.1 0.08
frame drop ref
display "PASS: base (uncond) agrees with RSiena"


* ---- balsim
nwclear
use "__groups_base.dta", clear
forvalues w = 1/3 {
	nwset, mat(Gbase`w') name(g`w') nooutput
}
frame create ref
frame ref: import delimited "dev/saom_rsiena_groups_balsim_cond1.csv", clear
__gfit, opts(outdegree reciprocity balance simx(alc) egox(alc)) 
__gchk outdegree "outdegree (density)" 0.12 0
__gchk reciprocity "reciprocity" 0.12 0
__gchk balance "balance" 0.12 0
__gchk simx_alc "alc similarity" 0.12 0
__gchk egox_alc "alc ego" 0.12 0
__gchk period1 "rate 1" 0.1 0.08
__gchk period2 "rate 2" 0.1 0.08
__gchk period4 "rate 3" 0.1 0.08
__gchk period5 "rate 4" 0.1 0.08
__gchk period7 "rate 5" 0.1 0.08
__gchk period8 "rate 6" 0.1 0.08
frame drop ref
display "PASS: balsim (cond) agrees with RSiena"

frame create ref
frame ref: import delimited "dev/saom_rsiena_groups_balsim_cond0.csv", clear
__gfit, opts(outdegree reciprocity balance simx(alc) egox(alc)) uncond
__gchk outdegree "outdegree (density)" 0.12 0
__gchk reciprocity "reciprocity" 0.12 0
__gchk balance "balance" 0.12 0
__gchk simx_alc "alc similarity" 0.12 0
__gchk egox_alc "alc ego" 0.12 0
__gchk period1 "constant net rate (period 1)" 0.1 0.08
__gchk period2 "constant net rate (period 2)" 0.1 0.08
__gchk period4 "constant net rate (period 4)" 0.1 0.08
__gchk period5 "constant net rate (period 5)" 0.1 0.08
__gchk period7 "constant net rate (period 7)" 0.1 0.08
__gchk period8 "constant net rate (period 8)" 0.1 0.08
frame drop ref
display "PASS: balsim (uncond) agrees with RSiena"


* ---- unequal
nwclear
use "__groups_base.dta", clear
forvalues w = 1/3 {
	nwset, mat(Gbase`w') name(g`w') nooutput
}
frame create ref
frame ref: import delimited "dev/saom_rsiena_groups_unequal_cond1.csv", clear
__gfit, opts(outdegree reciprocity transtrip egox(alc) altx(alc) nocenter gwaves(2: 1 2 | 3: 2 3)) 
__gchk outdegree "outdegree (density)" 0.12 0
__gchk reciprocity "reciprocity" 0.12 0
__gchk transtrip "transitive triplets" 0.12 0
__gchk altx_alc "alc alter" 0.12 0
__gchk egox_alc "alc ego" 0.12 0
__gchk period1 "rate 1" 0.1 0.08
__gchk period2 "rate 2" 0.1 0.08
__gchk period4 "rate 3" 0.1 0.08
__gchk period6 "rate 4" 0.1 0.08
frame drop ref
display "PASS: unequal (cond) agrees with RSiena"

frame create ref
frame ref: import delimited "dev/saom_rsiena_groups_unequal_cond0.csv", clear
__gfit, opts(outdegree reciprocity transtrip egox(alc) altx(alc) nocenter gwaves(2: 1 2 | 3: 2 3)) uncond
__gchk outdegree "outdegree (density)" 0.12 0
__gchk reciprocity "reciprocity" 0.12 0
__gchk transtrip "transitive triplets" 0.12 0
__gchk altx_alc "alc alter" 0.12 0
__gchk egox_alc "alc ego" 0.12 0
__gchk period1 "constant net rate (period 1)" 0.1 0.08
__gchk period2 "constant net rate (period 3)" 0.1 0.08
__gchk period4 "constant net rate (period 5)" 0.1 0.08
__gchk period6 "constant net rate (period 7)" 0.1 0.08
frame drop ref
display "PASS: unequal (uncond) agrees with RSiena"


* ---- tvcov
nwclear
use "__groups_base.dta", clear
forvalues w = 1/3 {
	nwset, mat(Gbase`w') name(g`w') nooutput
}
frame create ref
frame ref: import delimited "dev/saom_rsiena_groups_tvcov_cond0.csv", clear
__gfit, opts(outdegree reciprocity transtrip tvcov(alc1 alc2 alc3) egox(alc) altx(alc) simx(alc)) uncond
__gchk outdegree "outdegree (density)" 0.12 0
__gchk reciprocity "reciprocity" 0.12 0
__gchk transtrip "transitive triplets" 0.12 0
__gchk altx_alc "alc alter" 0.12 0
__gchk egox_alc "alc ego" 0.12 0
__gchk simx_alc "alc similarity" 0.12 0
__gchk period1 "constant net rate (period 1)" 0.1 0.08
__gchk period2 "constant net rate (period 2)" 0.1 0.08
__gchk period4 "constant net rate (period 4)" 0.1 0.08
__gchk period5 "constant net rate (period 5)" 0.1 0.08
__gchk period7 "constant net rate (period 7)" 0.1 0.08
__gchk period8 "constant net rate (period 8)" 0.1 0.08
frame drop ref
display "PASS: tvcov (uncond) agrees with RSiena"


* ---- ratecov
nwclear
use "__groups_base.dta", clear
forvalues w = 1/3 {
	nwset, mat(Gbase`w') name(g`w') nooutput
}
frame create ref
frame ref: import delimited "dev/saom_rsiena_groups_ratecov_cond0.csv", clear
__gfit, opts(outdegree reciprocity transtrip egox(alc) ratecov(alc)) uncond
__gchk outdegree "outdegree (density)" 0.12 0
__gchk reciprocity "reciprocity" 0.12 0
__gchk transtrip "transitive triplets" 0.12 0
__gchk egox_alc "alc ego" 0.12 0
__gchk rc_alc "effect alc on rate" 0.12 0
__gchk period1 "constant net rate (period 1)" 0.1 0.08
__gchk period2 "constant net rate (period 2)" 0.1 0.08
__gchk period4 "constant net rate (period 4)" 0.1 0.08
__gchk period5 "constant net rate (period 5)" 0.1 0.08
__gchk period7 "constant net rate (period 7)" 0.1 0.08
__gchk period8 "constant net rate (period 8)" 0.1 0.08
frame drop ref
display "PASS: ratecov (uncond) agrees with RSiena"


* ---- inter
nwclear
use "__groups_base.dta", clear
forvalues w = 1/3 {
	nwset, mat(Gbase`w') name(g`w') nooutput
}
frame create ref
frame ref: import delimited "dev/saom_rsiena_groups_inter_cond0.csv", clear
__gfit, opts(outdegree reciprocity transtrip egox(alc) interact(egox_alc#reciprocity)) uncond
__gchk outdegree "outdegree (density)" 0.12 0
__gchk reciprocity "reciprocity" 0.12 0
__gchk transtrip "transitive triplets" 0.12 0
__gchk egox_alc "alc ego" 0.12 0
__gchk interact_egox_alc_reciprocity "alc ego x reciprocity" 0.12 0
__gchk period1 "constant net rate (period 1)" 0.1 0.08
__gchk period2 "constant net rate (period 2)" 0.1 0.08
__gchk period4 "constant net rate (period 4)" 0.1 0.08
__gchk period5 "constant net rate (period 5)" 0.1 0.08
__gchk period7 "constant net rate (period 7)" 0.1 0.08
__gchk period8 "constant net rate (period 8)" 0.1 0.08
frame drop ref
display "PASS: inter (uncond) agrees with RSiena"


* ---- dyad
nwclear
use "__groups_base.dta", clear
forvalues w = 1/3 {
	nwset, mat(Gbase`w') name(g`w') nooutput
}
frame create ref
frame ref: import delimited "dev/saom_rsiena_groups_dyad_cond0.csv", clear
__gfit, opts(outdegree reciprocity transtrip dyadcov(Md)) uncond
__gchk outdegree "outdegree (density)" 0.12 0
__gchk reciprocity "reciprocity" 0.12 0
__gchk transtrip "transitive triplets" 0.12 0
__gchk dyadcov_Md "D" 0.12 0
__gchk period1 "constant net rate (period 1)" 0.1 0.08
__gchk period2 "constant net rate (period 2)" 0.1 0.08
__gchk period4 "constant net rate (period 4)" 0.1 0.08
__gchk period5 "constant net rate (period 5)" 0.1 0.08
__gchk period7 "constant net rate (period 7)" 0.1 0.08
__gchk period8 "constant net rate (period 8)" 0.1 0.08
frame drop ref
display "PASS: dyad (uncond) agrees with RSiena"


* ---- miss
nwclear
use "__groups_base.dta", clear
forvalues w = 1/3 {
	nwset, mat(Gbase`w') name(g`w') nooutput
}
frame create ref
frame ref: import delimited "dev/saom_rsiena_groups_miss_cond0.csv", clear
__gfit, opts(outdegree reciprocity transtrip egox(alc) altx(alc) missnet(Mm1 Mm2 Mm3)) uncond
__gchk outdegree "outdegree (density)" 0.12 0
__gchk reciprocity "reciprocity" 0.12 0
__gchk transtrip "transitive triplets" 0.12 0
__gchk altx_alc "alc alter" 0.12 0
__gchk egox_alc "alc ego" 0.12 0
__gchk period1 "constant net rate (period 1)" 0.1 0.08
__gchk period2 "constant net rate (period 2)" 0.1 0.08
__gchk period4 "constant net rate (period 4)" 0.1 0.08
__gchk period5 "constant net rate (period 5)" 0.1 0.08
__gchk period7 "constant net rate (period 7)" 0.1 0.08
__gchk period8 "constant net rate (period 8)" 0.1 0.08
frame drop ref
display "PASS: miss (uncond) agrees with RSiena"


* ---- comp
nwclear
use "__groups_comp.dta", clear
forvalues w = 1/3 {
	nwset, mat(Gcomp`w') name(g`w') nooutput
}
frame create ref
frame ref: import delimited "dev/saom_rsiena_groups_comp_cond0.csv", clear
__gfit, opts(outdegree reciprocity transtrip egox(alc) altx(alc) present(p1 p2 p3)) uncond
__gchk outdegree "outdegree (density)" 0.12 0
__gchk reciprocity "reciprocity" 0.12 0
__gchk transtrip "transitive triplets" 0.12 0
__gchk altx_alc "alc alter" 0.12 0
__gchk egox_alc "alc ego" 0.12 0
__gchk period1 "constant net rate (period 1)" 0.1 0.08
__gchk period2 "constant net rate (period 2)" 0.1 0.08
__gchk period4 "constant net rate (period 4)" 0.1 0.08
__gchk period5 "constant net rate (period 5)" 0.1 0.08
__gchk period7 "constant net rate (period 7)" 0.1 0.08
__gchk period8 "constant net rate (period 8)" 0.1 0.08
frame drop ref
display "PASS: comp (uncond) agrees with RSiena"


* ---- coev
nwclear
use "__groups_base.dta", clear
forvalues w = 1/3 {
	nwset, mat(Gbase`w') name(g`w') nooutput
}
frame create ref
frame ref: import delimited "dev/saom_rsiena_groups_coev_cond0.csv", clear
__gfit, opts(outdegree reciprocity transtrip behavior(alc1 alc2 alc3) linear quadratic avalt behegox behaltx) uncond
__gchk outdegree "outdegree (density)" 0.12 0
__gchk reciprocity "reciprocity" 0.12 0
__gchk transtrip "transitive triplets" 0.12 0
__gchk behegox "alc ego" 0.12 0
__gchk behaltx "alc alter" 0.12 0
__gchk beh_linear "alc linear shape" 0.12 0
__gchk beh_quadratic "alc quadratic shape" 0.12 0
__gchk beh_avalt "alc average alter" 0.12 0
__gchk period1 "constant net rate (period 1)" 0.1 0.08
__gchk bperiod1 "rate alc (period 1)" 0.1 0.08
__gchk period2 "constant net rate (period 2)" 0.1 0.08
__gchk bperiod2 "rate alc (period 2)" 0.1 0.08
__gchk period4 "constant net rate (period 4)" 0.1 0.08
__gchk bperiod4 "rate alc (period 4)" 0.1 0.08
__gchk period5 "constant net rate (period 5)" 0.1 0.08
__gchk bperiod5 "rate alc (period 5)" 0.1 0.08
__gchk period7 "constant net rate (period 7)" 0.1 0.08
__gchk bperiod7 "rate alc (period 7)" 0.1 0.08
__gchk period8 "constant net rate (period 8)" 0.1 0.08
__gchk bperiod8 "rate alc (period 8)" 0.1 0.08
frame drop ref
display "PASS: coev (uncond) agrees with RSiena"


* ---- coevsim
nwclear
use "__groups_base.dta", clear
forvalues w = 1/3 {
	nwset, mat(Gbase`w') name(g`w') nooutput
}
frame create ref
frame ref: import delimited "dev/saom_rsiena_groups_coevsim_cond0.csv", clear
__gfit, opts(outdegree reciprocity transtrip behavior(alc1 alc2 alc3) linear quadratic avsim behsim) uncond
__gchk outdegree "outdegree (density)" 0.12 0
__gchk reciprocity "reciprocity" 0.12 0
__gchk transtrip "transitive triplets" 0.12 0
__gchk behsim "alc similarity" 0.12 0
__gchk beh_linear "alc linear shape" 0.12 0
__gchk beh_quadratic "alc quadratic shape" 0.12 0
__gchk beh_avsim "alc average similarity" 0.12 0
__gchk period1 "constant net rate (period 1)" 0.1 0.08
__gchk bperiod1 "rate alc (period 1)" 0.1 0.08
__gchk period2 "constant net rate (period 2)" 0.1 0.08
__gchk bperiod2 "rate alc (period 2)" 0.1 0.08
__gchk period4 "constant net rate (period 4)" 0.1 0.08
__gchk bperiod4 "rate alc (period 4)" 0.1 0.08
__gchk period5 "constant net rate (period 5)" 0.1 0.08
__gchk bperiod5 "rate alc (period 5)" 0.1 0.08
__gchk period7 "constant net rate (period 7)" 0.1 0.08
__gchk bperiod7 "rate alc (period 7)" 0.1 0.08
__gchk period8 "constant net rate (period 8)" 0.1 0.08
__gchk bperiod8 "rate alc (period 8)" 0.1 0.08
frame drop ref
display "PASS: coevsim (uncond) agrees with RSiena"


* ---- coevrate
nwclear
use "__groups_base.dta", clear
forvalues w = 1/3 {
	nwset, mat(Gbase`w') name(g`w') nooutput
}
frame create ref
frame ref: import delimited "dev/saom_rsiena_groups_coevrate_cond0.csv", clear
__gfit, opts(outdegree reciprocity transtrip behavior(alc1 alc2 alc3) linear quadratic avalt behratecov(ccv)) uncond
__gchk outdegree "outdegree (density)" 0.12 0
__gchk reciprocity "reciprocity" 0.12 0
__gchk transtrip "transitive triplets" 0.12 0
__gchk beh_linear "alc linear shape" 0.12 0
__gchk beh_quadratic "alc quadratic shape" 0.12 0
__gchk beh_avalt "alc average alter" 0.12 0
__gchk brc_ccv "effect ccv on rate alc" 0.12 0
__gchk period1 "constant net rate (period 1)" 0.1 0.08
__gchk bperiod1 "rate alc (period 1)" 0.1 0.08
__gchk period2 "constant net rate (period 2)" 0.1 0.08
__gchk bperiod2 "rate alc (period 2)" 0.1 0.08
__gchk period4 "constant net rate (period 4)" 0.1 0.08
__gchk bperiod4 "rate alc (period 4)" 0.1 0.08
__gchk period5 "constant net rate (period 5)" 0.1 0.08
__gchk bperiod5 "rate alc (period 5)" 0.1 0.08
__gchk period7 "constant net rate (period 7)" 0.1 0.08
__gchk bperiod7 "rate alc (period 7)" 0.1 0.08
__gchk period8 "constant net rate (period 8)" 0.1 0.08
__gchk bperiod8 "rate alc (period 8)" 0.1 0.08
frame drop ref
display "PASS: coevrate (uncond) agrees with RSiena"


* ---- coevcomp
nwclear
use "__groups_comp.dta", clear
forvalues w = 1/3 {
	nwset, mat(Gcomp`w') name(g`w') nooutput
}
frame create ref
frame ref: import delimited "dev/saom_rsiena_groups_coevcomp_cond0.csv", clear
__gfit, opts(outdegree reciprocity transtrip behavior(alc1 alc2 alc3) linear quadratic avalt behegox behaltx present(p1 p2 p3)) uncond
__gchk outdegree "outdegree (density)" 0.12 0
__gchk reciprocity "reciprocity" 0.12 0
__gchk transtrip "transitive triplets" 0.12 0
__gchk behegox "alc ego" 0.12 0
__gchk behaltx "alc alter" 0.12 0
__gchk beh_linear "alc linear shape" 0.12 0
__gchk beh_quadratic "alc quadratic shape" 0.12 0
__gchk beh_avalt "alc average alter" 0.12 0
__gchk period1 "constant net rate (period 1)" 0.1 0.08
__gchk bperiod1 "rate alc (period 1)" 0.1 0.08
__gchk period2 "constant net rate (period 2)" 0.1 0.08
__gchk bperiod2 "rate alc (period 2)" 0.1 0.08
__gchk period4 "constant net rate (period 4)" 0.1 0.08
__gchk bperiod4 "rate alc (period 4)" 0.1 0.08
__gchk period5 "constant net rate (period 5)" 0.1 0.08
__gchk bperiod5 "rate alc (period 5)" 0.1 0.08
__gchk period7 "constant net rate (period 7)" 0.1 0.08
__gchk bperiod7 "rate alc (period 7)" 0.1 0.08
__gchk period8 "constant net rate (period 8)" 0.1 0.08
__gchk bperiod8 "rate alc (period 8)" 0.1 0.08
frame drop ref
display "PASS: coevcomp (uncond) agrees with RSiena"


* ---- the rest of the contract: e() results, refusals, state after the fit
nwclear
use "__groups_base.dta", clear
forvalues w = 1/3 {
	nwset, mat(Gbase`w') name(g`w') nooutput
}
nwsaom, waves(g1 g2 g3) groups(group) outdegree reciprocity transtrip egox(alc) altx(alc) k0(30) k3(500) seed(5) cores(1)
assert e(ngroups) == 3 & e(N) == 50 & "`e(groupvar)'" == "group" & e(conditional) == 1
matrix gn = e(groupn)
assert gn[1,1] == 15 & gn[1,2] == 20 & gn[1,3] == 15
local cn : colnames e(rates)
assert "`cn'" == "period1 period2 period4 period5 period7 period8"
matrix rp = e(rates_period)
matrix rg = e(rates_group)
assert rp[1,3] == 4 & rg[1,3] == 2 & rg[1,6] == 3
display "PASS: e() results of a fit with groups"

* estat timetest and estat score after a fit with groups
nwsaom, waves(g1 g2 g3) groups(group) outdegree reciprocity transtrip egox(alc) altx(alc) k0(30) k3(1000) seed(1) cores(1) unconditional
estat timetest, fixrates
assert r(df) == 25
matrix gt = r(group)
matrix pt = r(period)
assert rowsof(gt) == 3 & rowsof(pt) == 6
nwsaom, waves(g1 g2 g3) groups(group) outdegree reciprocity transtrip egox(alc) altx(alc) fix(egox(alc) altx(alc)) k0(30) k3(1000) seed(1) cores(1) unconditional
estat score
assert r(df) == 2
assert r(chi2) < 1.5
display "PASS: estat timetest and estat score after a fit with groups"

* what stops with a message
foreach o in "structural(Md)" "symmetric" "joinat(p1) leaveat(p2)" "inpopc" "ml" {
	capture nwsaom, waves(g1 g2 g3) groups(group) outdegree `o' k3(20)
	assert _rc != 0
}
capture nwsaom, waves(g1 g2 g3) groups(group) outdegree behavior(alc1 alc2 alc3 | alc1 alc2 alc3 : linear) k3(20)
assert _rc != 0
gen byte one = 1
capture nwsaom, waves(g1 g2 g3) groups(one) outdegree k3(20)
assert _rc == 198
capture nwsaom, waves(g1 g2 g3) groups(group) outdegree gwaves(9: 1 2) k3(20)
assert _rc != 0
* a tie between two groups
mata: M = st_matrix("Gbase2"); M[1, 20] = 1; st_matrix("Gx", M)
nwset, mat(Gx) name(gx) nooutput
capture nwsaom, waves(g1 gx g3) groups(group) outdegree k3(20)
assert _rc == 198
* estat gof is refused clearly, and a later ordinary fit is not affected by the group state
nwsaom, waves(g1 g2 g3) groups(group) outdegree reciprocity k0(10) k3(50) seed(1) cores(1)
capture estat gof
assert _rc != 0
nwsaom, waves(g1 g2 g3) outdegree reciprocity k0(10) k3(50) seed(1) cores(1)
assert missing(e(ngroups))
assert colsof(e(rates)) == 2
display "PASS: refusals and no group state after a grouped fit"
erase "__groups_base.dta"
erase "__groups_comp.dta"

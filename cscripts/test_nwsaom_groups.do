* Joint estimation of several groups (groups() option, RSiena's sienaGroupCreate() + siena07()).
* Data: the RSiena data s501-s503 cut into three groups of 15, 20 and 15 actors (actors 1-15, 16-35, 36-50; ties between
* the groups removed), with the alcohol covariate s50a. Reference: dev/saom_rsiena_groups.R (RSiena 1.6.14, 10 seeds,
* n3 = 2000, conditional and unconditional); the means of the 10 runs are the constants below. Rate parameters are one per
* period of each group, numbered as RSiena numbers them (the switch from the last wave of a group to the first wave of the
* next one is not a period): period1 period2 period4 period5 period7 period8.
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
nwclear
import delimited "dev/saom_groups_actors.csv", clear
forvalues w = 1/3 {
	preserve
	import delimited "dev/saom_groups_w`w'.csv", clear varnames(nonames)
	mkmat v*, matrix(G`w')
	restore
	nwset, mat(G`w') name(g`w') nooutput
}
local eff "outdegree reciprocity transtrip cycle3 egox(alc) altx(alc)"

* RSiena means: outdegree reciprocity altx egox transtrip cycle3 | rates of periods 1 2 4 5 7 8
local rc_cond  "-3.136 3.103 0.017 -0.060 0.534 0.333 3.495 1.850 5.668 2.286 1.097 2.289"
local rc_unc   "-2.964 2.898 0.011 -0.054 0.484 0.337 3.595 1.917 5.775 2.329 1.109 2.369"
foreach mode in cond unc {
	local opt = cond("`mode'" == "unc", "unconditional", "")
	nwsaom, waves(g1 g2 g3) groups(group) `eff' k0(50) k3(2000) seed(5) cores(1) `opt'
	assert e(ngroups) == 3
	assert e(N) == 50
	assert "`e(groupvar)'" == "group"
	assert e(conditional) == ("`mode'" == "cond")
	matrix gn = e(groupn)
	assert gn[1,1] == 15 & gn[1,2] == 20 & gn[1,3] == 15
	local cn : colnames e(rates)
	assert "`cn'" == "period1 period2 period4 period5 period7 period8"
	matrix rp = e(rates_period)
	matrix rg = e(rates_group)
	assert rp[1,3] == 4 & rg[1,3] == 2 & rg[1,6] == 3
	assert e(tconv_max) < 0.25
	matrix b = e(b)
	matrix r = e(rates)
	local k 0
	foreach ref of local rc_`mode' {
		local ++k
		if `k' <= 6 {
			local v = b[1,`k']
			assert abs(`v' - `ref') < 0.1
		}
		else {
			local v = r[1,`k'-6]
			assert abs(`v' - `ref') < 0.08 * `ref' + 0.1
		}
	}
	display "PASS: groups(), `mode' agrees with RSiena"
}

* the standard errors (unconditional) agree with RSiena's
matrix V = e(V)
local sers "0.267 0.391 0.135 0.137 0.380 0.719"
local k 0
foreach ref of local sers {
	local ++k
	assert abs(sqrt(V[`k',`k']) / `ref' - 1) < 0.1
}
display "PASS: standard errors agree with RSiena"

* the groups are separate actor sets: a fit with the same data gives the same result with the group codes in another order of rows is not
* tested here; the checks that must stop with an error
capture nwsaom, waves(g1 g2 g3) groups(group) `eff' behavior(alc alc alc : linear) k3(20)
assert _rc != 0
capture nwsaom, waves(g1 g2 g3) groups(group) `eff' balance k3(20)
assert _rc != 0
capture nwsaom, waves(g1 g2 g3) groups(group) `eff' simx(alc) k3(20)
assert _rc != 0
gen byte one = 1
capture nwsaom, waves(g1 g2 g3) groups(one) `eff' k3(20)
assert _rc == 198
* a tie between two groups
mata: M = st_matrix("G2"); M[1, 20] = 1; st_matrix("Gx", M)
nwset, mat(Gx) name(gx) nooutput
capture nwsaom, waves(g1 gx g3) groups(group) `eff' k3(20)
assert _rc == 198
display "PASS: groups() refusals"

* estat after a grouped fit is refused clearly, and a later ordinary fit is not affected by the group state
nwsaom, waves(g1 g2 g3) groups(group) `eff' k0(10) k3(50) seed(1) cores(1)
capture estat gof
assert _rc != 0
nwsaom, waves(g1 g2 g3) `eff' k0(10) k3(50) seed(1) cores(1)
assert missing(e(ngroups))
assert colsof(e(rates)) == 2
display "PASS: no group state after a grouped fit"

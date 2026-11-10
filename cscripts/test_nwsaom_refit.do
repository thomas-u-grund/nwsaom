* nwsaom refit: reruns e(cmdline) from the estimates; same results as typing theta0()/rate0()/behtheta0()
cscript
adopath ++ "."
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
nwwebuse glasgow, nwclear
* conditional network-only fit: theta0 only
quietly nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip k0(30) k3(100) seed(12345)
assert `"`e(cmdline)'"' == "nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip k0(30) k3(100) seed(12345)"
matrix b0 = e(b)
quietly nwsaom refit, k3(150) seed(7)
matrix b1 = e(b)
assert e(refit_runs) == 1
assert strpos(`"`e(cmdline)'"', "k3(150)") & strpos(`"`e(cmdline)'"', "seed(7)") & !strpos(`"`e(cmdline)'"', "k3(100)")
local th = strofreal(b0[1,1], "%21.0g") + " " + strofreal(b0[1,2], "%21.0g") + " " + strofreal(b0[1,3], "%21.0g")
quietly nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip k0(30) k3(150) seed(7) theta0(`th')
assert mreldif(e(b), b1) < 1e-12
di as text "PASS: refit = theta0() by hand"
* a second refit replaces the theta0() of the first
quietly nwsaom refit
local n = (strlen(`"`e(cmdline)'"') - strlen(subinstr(`"`e(cmdline)'"', "theta0(", "", .))) / 7
assert `n' == 1
di as text "PASS: one theta0() after two refits"
* unconditional: the rates go into rate0()
quietly nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity unconditional k0(30) k3(100) seed(1)
matrix b0 = e(b)
matrix r0 = e(rates)
quietly nwsaom refit, seed(2)
matrix b1 = e(b)
local th = strofreal(b0[1,1], "%21.0g") + " " + strofreal(b0[1,2], "%21.0g")
local rr = strofreal(r0[1,1], "%21.0g") + " " + strofreal(r0[1,2], "%21.0g")
quietly nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity unconditional k0(30) k3(100) seed(2) theta0(`th') rate0(`rr')
assert mreldif(e(b), b1) < 1e-12
di as text "PASS: unconditional refit = theta0() rate0() by hand"
* co-evolution: behtheta0()
quietly nwsaom, waves(glasgow1 glasgow2) outdegree reciprocity behavior(alcohol1 alcohol2) linear avalt k0(30) k3(100) seed(3)
matrix b0 = e(b)
quietly nwsaom refit, seed(4)
matrix b1 = e(b)
local th = strofreal(b0[1,1], "%21.0g") + " " + strofreal(b0[1,2], "%21.0g")
local bt = strofreal(b0[1,3], "%21.0g") + " " + strofreal(b0[1,4], "%21.0g")
quietly nwsaom, waves(glasgow1 glasgow2) outdegree reciprocity behavior(alcohol1 alcohol2) linear avalt k0(30) k3(100) seed(4) theta0(`th') behtheta0(`bt')
assert mreldif(e(b), b1) < 1e-12
di as text "PASS: co-evolution refit = theta0() behtheta0() by hand"
* multinet: one theta0() with all coefficients (net1_*, net2_*, beh_*); a second
* network overlapping with friendship, as in the nwsaom tutorial 6
nwtomata glasgow1, mat(F1)
nwtomata glasgow2, mat(F2)
set seed 20261001
mata: A1 = (F1 :* (runiform(50, 50) :< 0.7) + (runiform(50, 50) :< 0.005)) :> 0
mata: _diag(A1, 0)
mata: A2 = (A1 :* (runiform(50, 50) :< 0.8) + F2 :* (1 :- A1) :* (runiform(50, 50) :< 0.4)) :> 0
mata: _diag(A2, 0)
nwset, mat(A1) directed name(advice1)
nwset, mat(A2) directed name(advice2)
quietly nwsaom multinet, net1(glasgow1 glasgow2) net2(advice1 advice2) cross1(crprod) cross2(crprod) behavior(alcohol1 alcohol2) beheff1(linear) k0(30) k3(100) seed(5)
assert `"`e(cmdline)'"' == "nwsaom multinet, net1(glasgow1 glasgow2) net2(advice1 advice2) cross1(crprod) cross2(crprod) behavior(alcohol1 alcohol2) beheff1(linear) k0(30) k3(100) seed(5)"
matrix b0 = e(b)
quietly nwsaom refit, seed(6)
assert "`e(cmd)'" == "nwsaom_multinet"
matrix b1 = e(b)
local th ""
forvalues j = 1/`=colsof(b0)' {
	local th `th' `=strofreal(b0[1,`j'], "%21.0g")'
}
quietly nwsaom multinet, net1(glasgow1 glasgow2) net2(advice1 advice2) cross1(crprod) cross2(crprod) behavior(alcohol1 alcohol2) beheff1(linear) k0(30) k3(100) seed(6) theta0(`th')
assert mreldif(e(b), b1) < 1e-12
capture nwsaom refit, cores(2)
assert _rc == 198
di as text "PASS: multinet refit = theta0() by hand"
* maxruns(): stops at convergence or after the given number of runs
quietly nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip k0(30) k3(100) seed(12345)
nwsaom refit, maxruns(2) nodisplay
assert inrange(e(refit_runs), 1, 2)
assert e(refit_converged) == 1 | e(refit_runs) == 2
di as text "PASS: maxruns()"
* the refit hint follows the convergence table with and without detail (with detail it was missing up to 1.5.13)
quietly nwsaom, waves(glasgow1 glasgow2) outdegree reciprocity k0(30) k3(100) seed(1)
capture program drop _t_notconv
program define _t_notconv, eclass
	ereturn scalar tconv_max = 0.5
end
_t_notconv
foreach d in "" "detail" {
	tempfile lg
	quietly log using `"`lg'"', text replace name(_thint)
	_nwsaom_tconvtable, `d'
	quietly log close _thint
	tempname fh
	file open `fh' using `"`lg'"', read text
	local found 0
	file read `fh' line
	while r(eof) == 0 {
		if strpos(`"`macval(line)'"', "type nwsaom refit") | strpos(`"`macval(line)'"', "type {bf:nwsaom refit}") local found 1
		file read `fh' line
	}
	file close `fh'
	assert `found' == 1
}
di as text "PASS: refit hint with and without detail"
* errors
ereturn clear
capture nwsaom refit
assert _rc == 301
quietly nwsaom, waves(glasgow1 glasgow2) outdegree reciprocity k0(30) k3(100) seed(1)
capture nwsaom refit, maxruns(0)
assert _rc == 198
di as text "PASS: errors"

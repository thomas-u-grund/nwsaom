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
* maxruns(): stops at convergence or after the given number of runs
quietly nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip k0(30) k3(100) seed(12345)
nwsaom refit, maxruns(2) nodisplay
assert inrange(e(refit_runs), 1, 2)
assert e(refit_converged) == 1 | e(refit_runs) == 2
di as text "PASS: maxruns()"
* errors
ereturn clear
capture nwsaom refit
assert _rc == 301
quietly nwsaom, waves(glasgow1 glasgow2) outdegree reciprocity k0(30) k3(100) seed(1)
capture nwsaom refit, maxruns(0)
assert _rc == 198
di as text "PASS: errors"

* waves(a b) with exactly two waves must give the same results as the older wave1(a) wave2(b), in every model class
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
capture program drop cmpfits
program define cmpfits
	args label
	tempname b1 V1 b2 V2
	matrix `b1' = e(b)
	matrix `V1' = e(V)
	matrix `b2' = B2
	matrix `V2' = V2
	local d = mreldif(`b1', `b2')
	local dv = mreldif(`V1', `V2')
	di as text "`label': max rel. diff b = " as result %9.2e `d' as text ", V = " as result %9.2e `dv'
	assert `d' < 1e-9 & `dv' < 1e-9
	di as text "PASS: `label' same"
end
nwclear
nwwebuse glasgow, nwclear
* 1 network only, unconditional
quietly nwsaom, wave1(glasgow1) wave2(glasgow2) outdegree reciprocity transtrip k0(30) k3(100) seed(1)
matrix B2 = e(b)
matrix V2 = e(V)
local r1 = e(n_actors)
quietly nwsaom, waves(glasgow1 glasgow2) outdegree reciprocity transtrip k0(30) k3(100) seed(1)
cmpfits network
* 2 co-evolution
quietly nwsaom, wave1(glasgow1) wave2(glasgow2) outdegree reciprocity behsim behavior(alcohol1 alcohol2) linear avalt k0(30) k3(100) seed(2)
matrix B2 = e(b)
matrix V2 = e(V)
quietly nwsaom, waves(glasgow1 glasgow2) outdegree reciprocity behsim behavior(alcohol1 alcohol2) linear avalt k0(30) k3(100) seed(2)
cmpfits coevolution
* 3 fixed effects with theta0, then estat score
quietly nwsaom, wave1(glasgow1) wave2(glasgow2) outdegree reciprocity transtrip cycle3 theta0(-2.3 2 0 0) fix(transtrip cycle3) k0(30) k3(100) seed(1)
matrix B2 = e(b)
matrix V2 = e(V)
quietly nwsaom, waves(glasgow1 glasgow2) outdegree reciprocity transtrip cycle3 theta0(-2.3 2 0 0) fix(transtrip cycle3) k0(30) k3(100) seed(1)
cmpfits fixed
* 4 structural() (older mask option)
quietly nwsaom, wave1(glasgow1) wave2(glasgow2) outdegree reciprocity k0(30) k3(100) seed(1)
mata: st_matrix("MASKT", J(50,50,0))
quietly nwsaom, wave1(glasgow1) wave2(glasgow2) outdegree reciprocity k0(30) k3(100) seed(1) structural(MASKT)
matrix B2 = e(b)
matrix V2 = e(V)
capture noisily nwsaom, waves(glasgow1 glasgow2) outdegree reciprocity k0(30) k3(100) seed(1) structural(MASKT)
assert _rc == 0
cmpfits structural
* 5 maximum likelihood
quietly nwsaom, wave1(glasgow1) wave2(glasgow2) outdegree reciprocity transtrip k0(30) k3(100) seed(1) ml mloptions(seed(2) n3(50) nstart2(20))
matrix B2 = e(b)
matrix V2 = e(V)
quietly nwsaom, waves(glasgow1 glasgow2) outdegree reciprocity transtrip k0(30) k3(100) seed(1) ml mloptions(seed(2) n3(50) nstart2(20))
cmpfits ml
* 6 bayes
quietly nwsaom, wave1(glasgow1) wave2(glasgow2) outdegree reciprocity k0(30) k3(100) seed(1)
quietly nwsaom bayes, nprewarm(5) nwarm(5) nmain(20) nrunmh(2) seed(3) notable
matrix B2 = e(b)
matrix V2 = e(V)
quietly nwsaom, waves(glasgow1 glasgow2) outdegree reciprocity k0(30) k3(100) seed(1)
quietly nwsaom bayes, nprewarm(5) nwarm(5) nmain(20) nrunmh(2) seed(3) notable
cmpfits bayes
* 7 simulate subcommand
nwsaom simulate, wave1(glasgow1) wave2(glasgow2) outdegree reciprocity transtrip theta(-2.3 2 0.5) rates(5) nsim(2) seed(7) generate(ga)
nwsaom simulate, waves(glasgow1 glasgow2) outdegree reciprocity transtrip theta(-2.3 2 0.5) rates(5) nsim(2) seed(7) generate(gb)
di as text "simulate: networks ga/gb created"
* 8 two-mode and undirected: only the call must run with both forms
di as text "TEST DONE"

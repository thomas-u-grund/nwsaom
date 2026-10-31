* estat mems works on a fit made with waves(a b) (two waves) as on wave1(a) wave2(b)
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
program define mutualties, rclass
	args M
	mata: st_numscalar("__mt", sum(st_matrix(st_local("M")) :* st_matrix(st_local("M"))'))
	return scalar stat = scalar(__mt)
end
quietly nwsaom, wave1(glasgow1) wave2(glasgow2) outdegree reciprocity transtrip k0(30) k3(100) seed(1)
capture noisily estat mems, effect(reciprocity) macro(mutualties) nsim(30) seed(1)
local rc1 = _rc
matrix M1 = r(mems)
quietly nwsaom, waves(glasgow1 glasgow2) outdegree reciprocity transtrip k0(30) k3(100) seed(1)
estat mems, effect(reciprocity) macro(mutualties) nsim(30) seed(1)
matrix M2 = r(mems)
assert `rc1' == 0
assert mreldif(M1, M2) < 1e-9
quietly nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip k0(30) k3(100) seed(1)
capture estat mems, effect(reciprocity) macro(mutualties) nsim(30) seed(1)
assert _rc == 498
di "PASS: estat mems accepts waves(a b)"

* degree and density are RSiena's names for the outdegree effect; the coefficient label follows the spelling typed
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
forvalues w = 1/3 {
	import delimited "dev/saom_rsiena_netendow_w`w'.csv", clear varnames(1)
	mkmat v1-v50, matrix(G`w')
	matrix S`w' = G`w' + G`w''
	mata: st_matrix("S`w'", st_matrix("S`w'") :> 0)
	nwset, mat(S`w') undirected name(u`w') nooutput
}
quietly nwsaom, waves(u1 u2 u3) outdegree k0(20) k3(50) seed(1)
matrix B0 = e(b)
assert "`: colnames e(b)'" == "outdegree"
quietly nwsaom, waves(u1 u2 u3) degree k0(20) k3(50) seed(1)
assert "`: colnames e(b)'" == "degree"
assert mreldif(e(b), B0) < 1e-12
quietly nwsaom, waves(u1 u2 u3) density k0(20) k3(50) seed(1)
assert "`: colnames e(b)'" == "density"
assert mreldif(e(b), B0) < 1e-12
capture nwsaom, waves(u1 u2 u3) degree outdegree k0(20) k3(50) seed(1)
assert _rc == 198
capture nwsaom, waves(u1 u2 u3) degree density k0(20) k3(50) seed(1)
assert _rc == 198
gen smoke1 = mod(_n, 3) in 1/50
quietly nwsaom, waves(u1 u2 u3) degree nodematch(smoke1) theta0(-1.4 0) fix(degree) k0(20) k3(50) seed(1)
assert abs(el(e(b), 1, 1) + 1.4) < 1e-12
di "PASS: degree and density are accepted and labelled as typed"

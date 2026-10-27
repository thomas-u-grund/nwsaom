* usage: stata -e do tsim.do <dir> <K> <cond 0/1>  : simulate at fixed parameters through the fit context; mean and t of the deviations
args dir K cond
do /private/tmp/claude-501/-Users-tgrund-FILES-NEW-SOFTWARE-nwcommands/f80eded9-2ca1-45e7-9a6b-23ada6a895b2/scratchpad/st130/pre.do
do unw_saom.do
nwclear
local mopt ""
capture confirm file "`dir'/cc.csv"
local hascc = (_rc == 0)
capture confirm file "`dir'/miss2.csv"
if _rc == 0 {
	import delimited "`dir'/miss2.csv", clear varnames(nonames)
	mkmat v1-v50, matrix(M2)
	matrix Z0 = J(50, 50, 0)
	local mopt "missnet(Z0 M2 Z0)"
}
forvalues w = 1/3 {
	import delimited "`dir'/w`w'.csv", clear varnames(nonames)
	mkmat v1-v50, matrix(S`w')
	clear
	nwset, mat(S`w') directed name(w`w') nooutput
}
if `hascc' {
	import delimited "`dir'/cc.csv", clear varnames(1)
	local mopt "`mopt' joinat(jn) leaveat(lv)"
}
local mdl : env MODEL
local spec "outdegree reciprocity transtrip cycle3 indegpopularity outactivity"
local th0 "-1.7 0.6 0.25 -0.067 0.4 0.02"
local par "-1.7, 0.6, 0.25, -0.067, 0.4, 0.02, 4, 4"
local rcs ""
if "`mdl'" == "ratecov" {
	clear
	set obs 50
	gen double cv = mod(_n, 4) + 0.5
	local rcs "ratecov(cv)"
	local rcc : env RCC
	if "`rcc'" == "" local rcc 0.3
	local par "`par', `rcc'"
	mata: st_matrix("RC", st_data(., "cv") :- mean(st_data(., "cv")))
}
if "`mdl'" == "endow" {
	local spec "outdegree endow(reciprocity) creation(reciprocity) transtrip"
	local th0 "-1.7 0.5 0.8 0.3"
	local par "-1.7, 0.5, 0.8, 0.3, 4, 4"
}
quietly nwsaom, `mopt' waves(w1 w2 w3) `spec' `rcs' theta0(`th0') rate0(4 4) fix(_all) k0(1) k3(10) seed(1)
mata:
mata set matastrict off
void tsim_run(real scalar cond, real scalar K, string scalar dir, real rowvector par) {
	struct SaomNetCtx scalar C
	external class SaomGraph scalar __nwsaom_last_G1, __nwsaom_last_G2, __nwsaom_last_G3
	external class SaomModel scalar __nwsaom_last_M
	pointer(class SaomGraph scalar) rowvector Gw
	real matrix Z, S, M2, pres
	real rowvector fnt
	pointer(real matrix) rowvector MM
	real rowvector mm, sd
	real scalar fh
	SaomStructRestoreLast()
	Gw = (&__nwsaom_last_G1, &__nwsaom_last_G2, &__nwsaom_last_G3)
	C.cond = cond
	MM = J(1,0,NULL)
	if (fileexists(dir + "/miss2.csv")) {
		M2 = st_matrix("M2")
		MM = (&M2, &M2)
	}
	pres = J(0,0,0)
	fnt = *findexternal("__nwsaom_last_fntype")
	if (fileexists(dir + "/cc.csv")) pres = *findexternal("__nwsaom_compstart")
	SaomNetCtxInit(C, Gw, __nwsaom_last_M, pres, MM, fnt, (st_numscalar("RCON") == 1 ? st_matrix("RC") : J(0,0,0)), 0, J(0,0,0))
	SaomNetSimMany(C, __nwsaom_last_M, par, K, 0, Z, S)
	SaomBatchCleanup()
	mm = mean(Z)
	sd = sqrt(diagonal(variance(Z)))'
	printf("MEANDEV "); mm
	printf("SDDEV "); sd
	printf("TSTAT "); mm :/ sd
	unlink(dir + "/nws_sim_c" + strofreal(cond) + ".txt")
	fh = fopen(dir + "/nws_sim_c" + strofreal(cond) + ".txt", "w")
	fput(fh, invtokens(strofreal(mm)))
	fput(fh, invtokens(strofreal(sd)))
	fclose(fh)
}
end
scalar RCON = ("`mdl'" == "ratecov")
local penv : env PAR
if "`penv'" != "" local par "`penv'"
mata: tsim_run(`cond', `K', "`dir'", (`par'))

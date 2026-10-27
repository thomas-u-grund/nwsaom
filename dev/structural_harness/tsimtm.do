* usage: stata -e do tsim.do <dir> <K> <cond 0/1>  : simulate at fixed parameters through the fit context; mean and t of the deviations
args dir K cond
do /private/tmp/claude-501/-Users-tgrund-FILES-NEW-SOFTWARE-nwcommands/f80eded9-2ca1-45e7-9a6b-23ada6a895b2/scratchpad/st130/pre.do
do unw_saom.do
nwclear
local mopt ""
forvalues w = 1/3 {
	import delimited "`dir'/w`w'.csv", clear varnames(nonames)
	mkmat v1-v20, matrix(S`w')
	clear
	nwset, mat(S`w') bipartite name(w`w') nooutput
}
quietly nwsaom, `mopt' waves(w1 w2 w3) outdegree indegpopularity outactivity cycle4 theta0(-1.5 0.3 0.02 0.05) rate0(4 4) fix(_all) k0(1) k3(10) seed(1)
mata:
mata set matastrict off
void tsim_run(real scalar cond, real scalar K, string scalar dir, real rowvector par) {
	struct SaomNetCtx scalar C
	external class SaomGraph scalar __nwsaom_last_G1, __nwsaom_last_G2, __nwsaom_last_G3
	external class SaomModel scalar __nwsaom_last_M
	pointer(class SaomGraph scalar) rowvector Gw
	real matrix Z, S, M2
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
	SaomNetCtxInit(C, Gw, __nwsaom_last_M, J(0,0,0), MM, fnt, J(0,0,0), 0, st_matrix("__nwsaom_tm_structmat"))
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
mata: tsim_run(`cond', `K', "`dir'", (-1.5, 0.3, 0.02, 0.05, 4, 4))

* Validation of nwsaom bayes against RSiena (dev/saom_bayes_ml.R): Glasgow s501-s503. args: model (glas|cov) seed nprewarm nwarm nmain nrunmh
args model seed npw nw nm nr nimp opts
* The core package nwcommands is found through the environment variable NWCORE (path of the core checkout).
local nwcore : env NWCORE
if `"`nwcore'"' == "" {
	di as error "set the environment variable NWCORE to the directory of the nwcommands (core) package"
	exit 198
}
adopath ++ `"`nwcore'"'
adopath ++ `"`c(pwd)'"'
quietly do `"`nwcore'/unw_core.do"'
* (not needed here: unw_ergm.do belongs to another package)
do unw_saom.do
nwclear
forvalues w = 1/3 {
	import delimited "dev/saom_rsiena_netendow_w`w'.csv", clear varnames(1)
	mkmat v1-v50, matrix(W`w')
}
import delimited "dev/saom_rsiena_coev_netendow_beh.csv", clear varnames(1) case(preserve)
mkmat a1, matrix(AM)
clear
set obs 50
gen double alc = .
mata: st_store(., "alc", st_matrix("AM")[., 1])
forvalues w = 1/3 {
	nwset, mat(W`w') directed name(cx`w') nooutput
}
if "`model'" == "glas" nwsaom, waves(cx1 cx2 cx3) outdegree reciprocity transtrip k3(1000) seed(`seed')
else nwsaom, waves(cx1 cx2 cx3) outdegree reciprocity transtrip egox(alc) altx(alc) simx(alc) k3(1000) seed(`seed')
matrix MOM = e(b)
matrix list MOM
nwsaom bayes, nprewarm(`npw') nwarm(`nw') nmain(`nm') nrunmh(`nr') nimprovemh(`nimp') seed(`seed') `opts'
di "BAYESRESULT `model' seed `seed'"
matrix list e(b)
matrix list e(rates)
matrix SD = vecdiag(e(V))
forvalues k = 1/`=colsof(SD)' {
	matrix SD[1,`k'] = sqrt(SD[1,`k'])
}
matrix list SD
frame nwsaom_bayes_draws: gen blk = ceil(_n/`=ceil(`nm'/6)')
frame nwsaom_bayes_draws: tabstat b* rate* nchain, by(blk) stat(mean)

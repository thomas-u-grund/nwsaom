* nwsaom re-estimation of the RSiena-simulated undirected co-evolution replicates (dev/saom_sim_symcoev.R)
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
import delimited "dev/saom_rsiena_symmulti_w1.csv", clear varnames(1)
mkmat v1-v50, matrix(W1)
import delimited "dev/saom_sim_symcoev_alc1.csv", clear varnames(1)
mkmat a1, matrix(A1)
nwset, mat(W1) directed name(sw1) nooutput
tempname res
matrix `res' = J(40, 8, .)
forvalues r = 1/40 {
	import delimited "dev/saom_sim_symcoev2_`r'_net.csv", clear varnames(1)
	mkmat v1-v50, matrix(W2)
	import delimited "dev/saom_sim_symcoev2_`r'_beh.csv", clear varnames(1)
	mkmat b, matrix(B2)
	capture nwdrop sw2
	nwset, mat(W2) directed name(sw2) nooutput
	gen double alc1 = .
	gen double alc2 = .
	mata: st_store(., "alc1", st_matrix("A1")[., 1])
	mata: st_store(., "alc2", st_matrix("B2")[., 1])
	capture nwsaom, wave1(sw1) wave2(sw2) symmetric symtype(joint) outdegree behavior(alc1 alc2) linear avalt k0(50) k3(1000) seed(`r')
	if _rc == 0 {
		matrix b = e(b)
		matrix row = (e(rate), e(rate_beh), b[1,1], b[1,2], 0, b[1,3], 0, 1)
		forvalues c = 1/8 {
			matrix `res'[`r', `c'] = row[1, `c']
		}
		di "REP `r': " e(rate) " " e(rate_beh) " | " b[1,1] " " b[1,2] " " b[1,3]
	}
	else di "REP `r' rc " _rc
}
svmat `res', names(c)
mata: real scalar mm_median(real colvector x) { y = sort(x, 1); return(y[ceil(rows(y)/2)]) }
mata: R = st_matrix("`res'"); R = select(R, R[.,8] :== 1); printf("MEDIAN: outdeg %7.3f linear %7.3f avalt %7.3f\n", mm_median(R[.,3]), mm_median(R[.,4]), mm_median(R[.,6])); printf("MEAN over %f reps: rate %7.3f ratebeh %7.3f outdeg %7.3f linear %7.3f quad %7.3f avalt %7.3f\n", rows(R), mean(R[.,1]), mean(R[.,2]), mean(R[.,3]), mean(R[.,4]), mean(R[.,5]), mean(R[.,6])); printf("SD   : rate %7.3f ratebeh %7.3f outdeg %7.3f linear %7.3f quad %7.3f avalt %7.3f\n", sqrt(variance(R[.,1])), sqrt(variance(R[.,2])), sqrt(variance(R[.,3])), sqrt(variance(R[.,4])), sqrt(variance(R[.,5])), sqrt(variance(R[.,6])))
di "TRUTH: rate 0.6 ratebeh 1.5 outdeg -1.4 linear 0.3 avalt 1.5"

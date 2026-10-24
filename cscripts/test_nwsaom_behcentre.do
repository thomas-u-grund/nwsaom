* Behavior centring with missing behavior data. RSiena centres by the MEAN OF THE WAVE MEANS of the observed values
* (BehaviorLongitudinalData::calculateProperties); nwsaom used the pooled mean of the imputed values (3.0867 here, RSiena 3.0659).
* Reference: dev/saom_rsiena_behcentre.R (mean of wave means 3.065928; siena07 linear target 5.7917 with that centring), data dev/saom_behcentre_data.csv
* (s50a with 3, 2 and 15 missing values in waves 1-3; a1-a3 with missing values, m1-m3 the missing flags, f1-f3 the complete s50a).
cscript
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
	import delimited "dev/saom_r1614_s50_w`w'.csv", clear varnames(1)
	mkmat v1-v50, matrix(W`w')
	nwset, mat(W`w') directed name(c`w') nooutput
}
import delimited "dev/saom_behcentre_data.csv", clear varnames(1)
* the expected values computed by hand from the data
quietly {
	local sm 0
	forvalues w = 1/3 {
		summarize a`w'
		local sm = `sm' + r(mean) / 3
	}
}
assert abs(`sm' - 3.0659278959810874) < 1e-9
* missing data: e(behmean) is the mean of the wave means of the observed values
nwsaom, waves(c1 c2 c3) outdegree reciprocity behavior(a1 a2 a3 : linear quadratic avalt) missbeh(m1 m2 m3) seed(1) k3(100)
assert abs(e(behmean) - `sm') < 1e-9
di "PASS behavior centring: mean of the wave means with missbeh()"
* complete data: both means agree (the pooled mean of the three equal-sized waves)
nwsaom, waves(c1 c2 c3) outdegree reciprocity behavior(f1 f2 f3 : linear quadratic avalt) seed(1) k3(100)
assert abs(e(behmean) - 3.1133333333333333) < 1e-9
di "PASS behavior centring: complete data unchanged"

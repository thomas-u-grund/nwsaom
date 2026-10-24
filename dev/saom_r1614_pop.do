* observed statistics of outPop.c / outPopSqrt / outPopMore / outPopSqrtMore / outPopThreshold / inAct.c / inActSqrt (RSiena 1.6.14 default internal parameter 1) on s50 (glasgow),
* sum over the two periods; RSiena 1.6.14: 119.08 386.6856 443 153.6856 198 119.08 378.5651 (parameter 2: 245 71.6713 138)
cscript
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
nwwebuse glasgow, nwclear
foreach spec in "outpopc" "outpopularity" "ownx(outpopmore:1)" "ownx(outpopsqrtmore:1)" "ownx(outpopthreshold:1)" "inactc" "inactivity" "ownx(outpopmore:2)" "ownx(outpopsqrtmore:2)" "ownx(outpopthreshold:2)" {
	capture nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree `spec' k0(5) k3(20) seed(1)
	if _rc {
		di "POPSTAT `spec' rc=" _rc
		continue
	}
	mata: st1 = __nwsaom_last_M.full_statistic(__nwsaom_last_G2); st2 = __nwsaom_last_M.full_statistic(__nwsaom_last_G3); printf("POPSTAT `spec' %12.4f\n", (st1 + st2)[2])
}

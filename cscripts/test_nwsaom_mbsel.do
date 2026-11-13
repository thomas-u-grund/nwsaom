* Several behaviors: the network effects with ANY behavior as the covariate (behsim behegox behaltx behegoplusalt netbeh:<effect> in that behavior's
* effect list). The observed statistics on s50 + alcohol + smoking equal siena07's targets (dev/saom_rsiena_mbsel.R, RSiena 1.6.14); the estimates
* agree with siena07 within simulation error (dev/saom_rsiena_mbsel.do).
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
do unw_saom.do
set linesize 255
nwclear
forvalues w = 1/3 {
	import delimited "dev/saom_rsiena_netendow_w`w'.csv", clear varnames(1)
	mkmat v1-v50, matrix(W`w')
}
import delimited "dev/saom_rsiena_multibeh_data.csv", clear varnames(1)
forvalues w = 1/3 {
	nwset, mat(W`w') directed name(te`w') nooutput
}

* 1. targets: siena07 1.6.14 (outdegree, reciprocity counted once here, transitive triplets, alc similarity, smk alter, smk ego, higher smk, smk similarity,
*    smk similarity x reciprocity, smk ego and alt)
capture noisily nwsaom, waves(te1 te2 te3) outdegree reciprocity transtrip ///
	behavior(a1 a2 a3 : linear quadratic avalt behsim | s1 s2 s3 : linear quadratic avalt behaltx behegox netbeh:higher behsim netbeh:simrecipx behegoplusalt) k0(5) k3(10) seed(1)
mata: __r0 = .
mata: __rb0 = .
mata: __t = SaomMBInit(__ns_mbGw, __nwsaom_last_M, __ns_mbBw, __ns_mbmin, __ns_mbmax, __ns_mbsim, __ns_mbover, __ns_mbMb, __r0, __rb0)
mata: SaomBatchCleanup()
mata: __tg = colsum(__t.target)[1..10]
mata: __rs = (238, 80, 225, 21.9957, -25.52, -25.52, 120.5, 28.94, 20.0857, -51.04)
mata: __tg
mata: st_numscalar("__d", max(abs(__tg - __rs)))
assert scalar(__d) < 1e-4
di as text "targets equal siena07 PASS"

* 2. a fit: names, labels, engine; estimates near siena07 (3 seeds of siena07: alc similarity 1.18, smk alter 0.10, smk ego 0.035, smk similarity 1.07,
*    smk similarity x reciprocity -1.17)
nwsaom, waves(te1 te2 te3) outdegree reciprocity transtrip ///
	behavior(a1 a2 a3 : linear quadratic avalt behsim | s1 s2 s3 : linear quadratic avalt behaltx behegox behsim netbeh:simrecipx) k3(500) seed(2)
assert "`e(engine)'" == "native"
local cn : colnames e(b)
assert "`: word 4 of `cn''" == "behsim" & "`: word 5 of `cn''" == "behaltx_s" & "`: word 7 of `cn''" == "behsim_s" & "`: word 8 of `cn''" == "natb_simrecipx_s"
assert strpos(`"`e(rsiena_labels)'"', "|s similarity|")
assert abs(_b[behsim_s] - 1.07) < 0.4 & abs(_b[behsim] - 1.18) < 0.4 & abs(_b[natb_simrecipx_s] + 1.17) < 1
assert abs(_b[outdegree] + 2.81) < 0.15 & abs(_b[behaltx_s] - 0.10) < 0.3
di as text "fit with selection on the second behavior PASS"

* 3. the option behsim and behsim in the first list are the same; behsim of behavior 2 alone
nwsaom, waves(te1 te2 te3) outdegree reciprocity behavior(a1 a2 a3 : linear | s1 s2 s3 : linear behsim) k0(20) k3(50) seed(3)
local cn : colnames e(b)
assert "`: word 3 of `cn''" == "behsim_s"
di as text "behsim of behavior 2 alone PASS"

* 4. refusals: unknown network token, the Mata engine
capture nwsaom, waves(te1 te2 te3) outdegree behavior(a1 a2 a3 : linear | s1 s2 s3 : linear netbeh:bogus)
assert _rc == 198
global NWSAOM_NONATIVE 1
capture nwsaom, waves(te1 te2 te3) outdegree behavior(a1 a2 a3 : linear | s1 s2 s3 : linear behsim) k0(5) k3(5)
assert _rc == 198
global NWSAOM_NONATIVE
di as text "refusals PASS"

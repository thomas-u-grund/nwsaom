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

* The Mata fallback is orders of magnitude slower than the plugin, so a fit that runs on it prints one warning line before the
* long computation (missing plugin file, option-like switch NWSAOM_NONATIVE, older plugin, model outside the plugin's capacity);
* a fit with the plugin must not print it; quietly suppresses it; the estimates do not depend on the warning.
* Three runs on the Glasgow data: (A) with the plugin, (B) from a copy of the package without the plugin file,
* (C) with the plugin but the global NWSAOM_NONATIVE = 1.  B and C both run on Mata with the same seed: equal estimates.

nwwebuse glasgow, nwclear
local m nwsaom, wave1(glasgow1) wave2(glasgow2) outdegree reciprocity k3(20) seed(1)
set linesize 250
local key "compiled plugin is not used"

tempfile lA lB lC lQ
tempname fh

* (A) with the plugin
log using `lA', text replace name(wa)
`m'
log close wa
assert "`e(engine)'" == "native"
mata: st_numscalar("nA", sum(strpos(cat(st_local("lA")), st_local("key")) :> 0))
assert scalar(nA) == 0

* (C) with the plugin file present but NWSAOM_NONATIVE = 1
global NWSAOM_NONATIVE 1
log using `lC', text replace name(wc)
`m'
log close wc
log using `lQ', text replace name(wq)
quietly `m'
log close wq
global NWSAOM_NONATIVE
assert "`e(engine)'" == "mata"
matrix bC = e(b)
mata: st_numscalar("nC", sum(strpos(cat(st_local("lC")), st_local("key")) :> 0))
mata: st_numscalar("nCg", sum(strpos(cat(st_local("lC")), "NWSAOM_NONATIVE") :> 0))
mata: st_numscalar("nQ", sum(strpos(cat(st_local("lQ")), st_local("key")) :> 0))
assert scalar(nC) == 1
assert scalar(nCg) == 1
assert scalar(nQ) == 0

* (B) a copy of the package without any plugin file
local scr "`c(tmpdir)'/nwsaom_fbw_`=floor(runiform()*1e9)'"
capture shell rm -rf "`scr'"
mkdir "`scr'"
foreach f in nwsaom*.ado _nwsaom*.ado {
	local fl : dir "." files "`f'"
	foreach x of local fl {
		copy `"`x'"' `"`scr'/`x'"', replace
	}
}
* no other copy of the plugin may be reachable through the adopath
mata: st_local("pf", SaomNativePluginFilename())
capture findfile `pf'
while _rc == 0 {
	local d = substr(`"`r(fn)'"', 1, length(`"`r(fn)'"') - length("`pf'") - 1)
	adopath - `"`d'"'
	capture findfile `pf'
}
adopath ++ `"`scr'"'
* (the Mata code is already loaded; the package ado-files of the copy now come first on the adopath and the plugin is searched next to them)
log using `lB', text replace name(wb)
`m'
log close wb
assert "`e(engine)'" == "mata"
matrix bB = e(b)
mata: st_numscalar("nB", sum(strpos(cat(st_local("lB")), st_local("key")) :> 0))
mata: st_numscalar("nBf", sum(strpos(cat(st_local("lB")), "was not found") :> 0))
assert scalar(nB) == 1
assert scalar(nBf) == 1
assert mreldif(bB, bC) < 1e-12
capture shell rm -rf "`scr'"
di "PASS test_nwsaom_fallbackwarn"

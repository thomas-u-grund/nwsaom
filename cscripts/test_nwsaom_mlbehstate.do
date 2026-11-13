* nwsaom: ml refuses the options it does not cover before the fit; the global behsim with several behaviors is the
* behsim of the first behavior; a fit with several behaviors after one with behfrom() does not stop with r(3301)
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
set linesize 120
nwwebuse glasgow, nwclear

* 1. ml with options it does not cover: r(198) at once, before any estimation output
gen byte p1 = 1
gen byte p2 = 1
gen byte p3 = 1
foreach o in "present(p1 p2 p3)" "missnet(glasgow1 glasgow2)" "endow(reciprocity) creation(reciprocity)" "symmetric" {
	local w = cond(strpos("`o'", "present"), "waves(glasgow1 glasgow2 glasgow3)", "wave1(glasgow1) wave2(glasgow2)")
	ereturn clear
	capture noisily nwsaom, `w' outdegree reciprocity `o' ml seed(1)
	assert _rc == 198
	* refused before the method-of-moments fit: nothing was posted
	assert `"`e(cmd)'"' == ""
}
di "PASS ml refusals before the fit"

* 2. a fit with two behaviors after one with behfrom(): no r(3301)
local bv "behavior(alcohol1 alcohol2 alcohol3 : linear quadratic avalt | smoke1 smoke2 smoke3 : linear quadratic avalt)"
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity `bv' behfrom(beh2) seed(1) k3(100)
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity `bv' seed(1) k3(100)
assert `"`e(cmd)'"' == "nwsaom"
di "PASS fit after behfrom()"

* 3. global behsim = behsim in the list of the first behavior (same estimates)
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity behsim `bv' seed(1) k3(100)
matrix b1 = e(b)
local n1 : colnames b1
assert strpos(" `n1' ", " behsim ")
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity behavior(alcohol1 alcohol2 alcohol3 : linear quadratic avalt behsim | smoke1 smoke2 smoke3 : linear quadratic avalt) seed(1) k3(100)
matrix b2 = e(b)
assert mreldif(b1, b2) == 0
di "PASS global behsim with several behaviors"

* Fixed effects are not judged by the convergence criteria (as RSiena, phase3.r: the largest |t| and tconv.max over !z$fixed)
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
set linesize 80
* capture the output of the convergence table in a local (all lines joined)
capture program drop _t_tctext
program define _t_tctext
	args lname opt
	tempfile lg
	quietly log using `"`lg'"', text replace name(_tfc)
	_nwsaom_tconvtable, `opt'
	quietly log close _tfc
	tempname fh
	local all ""
	file open `fh' using `"`lg'"', read text
	file read `fh' line
	while r(eof) == 0 {
		local all `"`all' `macval(line)'"'
		file read `fh' line
	}
	file close `fh'
	c_local `lname' `"`all'"'
end

* 1. synthetic results: the fixed parameter (variance 0) has a large t-ratio, the others are small
capture program drop _t_post
program define _t_post, eclass
	args t2
	tempname b V tc
	matrix `b' = (1, 0, 2)
	matrix `V' = (0.1, 0, 0 \ 0, 0, 0 \ 0, 0, 0.2)
	matrix colnames `b' = outdegree indegpopularity reciprocity
	matrix colnames `V' = outdegree indegpopularity reciprocity
	matrix rownames `V' = outdegree indegpopularity reciprocity
	ereturn post `b' `V'
	matrix `tc' = (0.02, `t2', -0.03, 0.01)
	matrix colnames `tc' = outdegree indegpopularity reciprocity rate_period1
	ereturn matrix tconv = `tc'
	ereturn scalar tconv_max = 0.08
	ereturn local cmd "nwsaom"
	ereturn local cmdline "nwsaom, waves(a b) outdegree indegpopularity reciprocity fix(indegpopularity)"
end
_t_post 0.319
_nwsaom_tconvfixed fx
assert "`fx'" == "0 1 0 0"
_t_tctext out
assert strpos(`"`out'"', "all below 0.1 in absolute value): met")
assert !strpos(`"`out'"', "not met")
assert !strpos(`"`out'"', "nwsaom refit")
_t_tctext out detail
assert strpos(`"`out'"', "Fixed, not part of the criteria: indegpopularity")
assert !strpos(`"`out'"', "nwsaom refit")
di as text "PASS: a fixed parameter's t-ratio is not judged"
* an estimated parameter above 0.1 is still reported
_t_post 0.319
capture program drop _t_bad
program define _t_bad, eclass
	tempname tc
	matrix `tc' = e(tconv)
	matrix `tc'[1,3] = 0.15
	ereturn matrix tconv = `tc'
end
_t_bad
_t_tctext out
assert strpos(`"`out'"', "not met for")
assert strpos(`"`out'"', "reciprocity (0.150)")
assert !strpos(`"`out'"', "indegpopularity (")
di as text "PASS: estimated parameters are still judged"

* 2. the restricted Glasgow model of the book's exercise: indegpopularity and cycle3 fixed at 0
nwclear
nwwebuse glasgow, nwclear
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip indegpopularity outactivity cycle3 fix(indegpopularity cycle3) seed(1)
matrix tc = e(tconv)
matrix list tc
_nwsaom_tconvfixed fx
local names : colnames tc
local fxn ""
local worst 0
forvalues j = 1/`=colsof(tc)' {
	if "`: word `j' of `fx''" == "1" local fxn `fxn' `: word `j' of `names''
	else local worst = max(`worst', abs(tc[1,`j']))
}
assert "`fxn'" == "indegpopularity cycle3"
_t_tctext out
foreach w in indegpopularity cycle3 {
	assert !strpos(`"`out'"', "`w' (")
}
if `worst' < 0.1 assert strpos(`"`out'"', "all below 0.1 in absolute value): met")
else assert strpos(`"`out'"', "not met for")
_t_tctext out detail
assert strpos(`"`out'"', "Fixed, not part of the criteria: indegpopularity cycle3")
di as text "PASS: fix() in the Glasgow model (largest |t| of the estimated effects " %5.3f `worst' ")"

* 3. refit: the largest |t| leaves the fixed effects out
quietly nwsaom refit, k3(300) seed(2) nodisplay
matrix tc = e(tconv)
_nwsaom_tconvfixed fx
local worst 0
forvalues j = 1/`=colsof(tc)' {
	if "`: word `j' of `fx''" != "1" local worst = max(`worst', abs(tc[1,`j']))
}
assert e(refit_converged) == ((`worst' < 0.1) & (e(tconv_max) < 0.25))
di as text "PASS: refit judges the estimated effects only"

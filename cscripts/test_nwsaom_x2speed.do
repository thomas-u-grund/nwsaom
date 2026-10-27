* The speed-up of the plug-in for two-mode networks (the free alternatives of an actor as a list, the degree effects evaluated
* directly) and of the Mata glue around the plug-in must not change a single number: estimates and standard errors of
* fixed-seed fits are compared with the values the released 1.1.0 gave (fixtures below, 15 significant digits; they are
* identical to the last digit). Two-mode network (unconditional, conditional) and a one-mode network with the degree
* effects. Run with the environment variable X2REC=1 to print new fixtures instead of comparing.
cscript
set linesize 255
local nwcore : env NWCORE
if `"`nwcore'"' == "" {
	di as error "set the environment variable NWCORE to the directory of the nwcommands (core) package"
	exit 198
}
adopath ++ `"`nwcore'"'
adopath ++ `"`c(pwd)'"'
quietly do `"`nwcore'/unw_core.do"'
do unw_saom.do
local rec : env X2REC

nwclear
mata:
mata set matastrict off
void x2_data() {
	na = 30
	ne = 18
	rseed(13579)
	X = (runiform(na, ne) :< 0.12)
	for (w=1; w<=3; w++) {
		st_matrix("__T" + strofreal(w), X)
		F = (runiform(na, ne) :< 0.10)
		X = abs(X - F)
	}
}
x2_data()
end
clear
forvalues w = 1/3 {
	nwset, mat(__T`w') bipartite name(tm`w') nooutput
}

local m1 "waves(tm1 tm2 tm3) outdegree indegpopularity outactivity cycle4 outiso antiiniso2 unconditional cores(1) seed(7)"
local m2 "waves(tm1 tm2 tm3) outdegree indegpopularity outactivity cycle4 outiso antiiniso2 cores(1) seed(11)"
local m3 "waves(tm1 tm2 tm3) outdegree indegpopularity cycle4 unconditional cores(1) seed(3)"
local m4 "waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity indegpopularity outactivity antiiniso2 unconditional cores(1) seed(5)"
* FIXTURES-BEGIN
local fx1 "-2.02465536640714 .959663031868016 .456534102895446 .309021763947677 .109962049985246 .0738901394833299 -.965288890580595 2.06928399146866 12.9844664172684 43199.1874502904 -.0197281468332084 .0627248551489741"
local fx2 "-2.04823394942757 10.3995457638976 .456067834745379 2.76962046143159 .11150064088042 .520876479373792 -1.04337466791496 13.8535672715594 10.8568707555339 13672.3365140804 -.0147265536738992 .0972384771264962"
local fx3 "-.450869851792011 .570025346296044 .0596531484972036 .262093123938971 .0641748267808878 .0551365160570515"
local fx4 "-2.98694702740399 .4640676991308 2.83152915533213 .181232814622801 .322744250183852 .219206035459956 -.00135262179016569 .0375322281987432 .274919183954358 .289703792718974"
* FIXTURES-END
tempname B V
forvalues i = 1/4 {
	if `i' == 4 {
		nwwebuse glasgow, nwclear
	}
	qui nwsaom, `m`i''
	matrix `B' = e(b)
	matrix `V' = e(V)
	local s ""
	forvalues j = 1/`=colsof(`B')' {
		local s "`s' `=string(`B'[1,`j'], "%21.15g")' `=string(sqrt(`V'[`j',`j']), "%21.15g")'"
	}
	if "`rec'" != "" {
		di "FIXTURE`i'=`s'"
	}
	else {
		local nw : word count `fx`i''
		assert `nw' == 2 * colsof(`B')
		forvalues j = 1/`nw' {
			local want : word `j' of `fx`i''
			local have : word `j' of `s'
			assert reldif(`have', `want') < 1e-12
		}
		di as result "PASS: fit `i' reproduces the 1.1.0 numbers"
	}
}

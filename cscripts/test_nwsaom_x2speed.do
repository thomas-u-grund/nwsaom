* The speed-up of the plug-in for two-mode networks (the free alternatives of an actor as a list, the degree effects evaluated
* directly) and of the Mata glue around the plug-in must not change a single number: estimates and standard errors of
* fixed-seed fits are compared with stored values (fixtures below, 15 significant digits), recorded with 1.5.3, whose
* Robbins-Monro steps follow RSiena's defaults (Dolby, repeated subphases); before, the values of the released 1.1.0. Two-mode network (unconditional, conditional) and a one-mode network with the degree
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
local fx1 "-2.01756129881298 .91349588868761 .460354240521661 .302684666716951 .108002019373256 .0732461751529714 -.962355227167434 2.11458628490437 16.6388084034393 1883961.74509561 -.0212337325244638 .0624284022094269"
local fx2 "-2.04978932770068 .894021258487798 .456986573541664 .305699244129828 .113173460487188 .0717215814832138 -1.0704890118692 2.02510648370383 11.8529677428573 14498.168578071 -.0174491119617513 .060778837915052"
local fx3 "-.412403825485096 .57853081240611 .0487805344908802 .277040303639602 .0629195577126237 .0557877299217926"
local fx4 "-3.00742185467161 .48694205497932 2.83300098130886 .183039747842102 .330853147006269 .229248939541908 -.00086169914193074 .0365861307282126 .288897053366144 .31235022158731"
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
			* estimates to 1e-12; standard errors (even words) to 1e-9: a near-singular variance matrix amplifies platform rounding
			assert reldif(`have', `want') < cond(mod(`j', 2) == 0, 1e-9, 1e-12)
		}
		di as result "PASS: fit `i' reproduces the stored numbers"
	}
}

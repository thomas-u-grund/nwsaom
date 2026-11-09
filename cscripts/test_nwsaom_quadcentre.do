cscript

* Regression test (1.5.7): the quadratic shape statistic is the sum of the squared CENTRED behavior values, as in RSiena
* (StatisticCalculator centres the values before QuadraticShapeEffect::egoStatistic squares them). Up to 1.5.6 it was the
* raw sum of squares, which mixes in 2 * mean times the linear statistic and broke the Dolby correction of Phase 2.
* Checks: (1) for the ego-only behavior effects, the change of the statistic when one actor's value changes equals the
* change statistic of the ministep; (2) the plugin's statistic (BEHSTAT) equals the Mata statistic.

local nwcore : env NWCORE
if `"`nwcore'"' == "" {
	di as error "set the environment variable NWCORE to the directory of the nwcommands (core) package"
	exit 198
}
adopath ++ `"`nwcore'"'
capture adopath ++ `"`nwcore'/lib"'
adopath ++ `"`c(pwd)'"'
adopath ++ `"`c(pwd)'/lib"'
adopath ++ `"`c(pwd)'/lib/plugins/macos"'
mata: mata mlib index

mata:
real scalar _qc_check(string scalar nm, real scalar c)
{
	class SaomBehaviorModel scalar M
	class SaomGraph scalar G
	class SaomBehavior scalar B, B2
	real scalar n, i, j, k, d, worst
	real colvector z
	n = 12
	rseed(7)
	G = SaomGraph()
	G.init(n, 1)
	for (i=1; i<=n; i++) for (j=1; j<=n; j++) if (i != j & runiform(1,1) < .3) G.toggle(i, j)
	z = floor(runiform(n,1)*5) :+ 1
	M = SaomBehaviorModel()
	M.init()
	(void) SaomMBAddTerms(M, nm, "")
	B = SaomBehavior()
	B.init(z, 1, 5, c, 0)
	worst = 0
	for (k=1; k<=40; k++) {
		i = ceil(runiform(1,1)*n)
		d = (runiform(1,1) < .5 ? -1 : 1)
		if (z[i] + d < 1 | z[i] + d > 5) continue
		B2 = SaomBehavior()
		B2.init(z, 1, 5, c, 0)
		B2.setvalue(i, z[i] + d)
		worst = max((worst, abs(((*M.statfn[1])(B2, G) - (*M.statfn[1])(B, G)) - (*M.chgfn[1])(B, G, i, d))))
	}
	return(worst)
}
real scalar _qc_plugin(real scalar c)
{
	class SaomGraph scalar G
	class SaomBehavior scalar B
	real scalar n, i, j
	real colvector z
	n = 12
	rseed(11)
	G = SaomGraph()
	G.init(n, 1)
	for (i=1; i<=n; i++) for (j=1; j<=n; j++) if (i != j & runiform(1,1) < .3) G.toggle(i, j)
	z = floor(runiform(n,1)*5) :+ 1
	B = SaomBehavior()
	B.init(z, 1, 5, c, 0)
	return(abs(SaomNativeBehStat(B, G, 102, 0) - stat_saom_quadratic(B, G)))
}
end

foreach t in linear quadratic indeg outdeg recipdeg isolate outisolate {
	foreach c in 3 2.3 {
		mata: st_numscalar("r_w", _qc_check("`t'", `c'))
		di as text "  `t' (mean `c'): max |change of statistic - change statistic| = " as result r_w
		assert r_w < 1e-10
	}
}
di as text "  PASS: statistic and change statistic agree for the ego-only behavior effects"

mata: z0 = (1, 2, 5)'
mata: B0 = SaomBehavior()
mata: B0.init(z0, 1, 5, 2.5, 0)
mata: G0 = SaomGraph()
mata: G0.init(3, 1)
mata: st_numscalar("r_q", stat_saom_quadratic(B0, G0))
assert abs(r_q - (1.5^2 + 0.5^2 + 2.5^2)) < 1e-12
di as text "  PASS: the quadratic statistic is the sum of the squared centred values"

mata: st_numscalar("r_nat", SaomNativeAvailable())
if r_nat {
	mata: st_numscalar("r_ver", SaomNativePluginVersion())
	assert r_ver >= 154
	foreach c in 3 2.3 {
		mata: st_numscalar("r_p", _qc_plugin(`c'))
		assert r_p < 1e-10
	}
	di as text "  PASS: the plugin's quadratic statistic equals the Mata statistic"
}
di as result "ALL TESTS PASSED"

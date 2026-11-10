*! version 1.5.12  10nov2026 nwsaom_refit 1.5.12 10nov2026
* nwsaom refit: rerun the last nwsaom fit, starting from its estimates
* (RSiena's prevAns). The command is taken from e(cmdline); theta0(),
* behtheta0(), rate0() and ratecovcoef() are replaced by the estimates of
* the last fit. With maxruns(#) > 1 the refit is repeated until the
* convergence criteria are met (all |t| < tconv(), overall maximum
* convergence ratio < tmax()) or # runs have been made.
program nwsaom_refit, eclass
	version 14
	syntax [, MAXRUNS(integer 1) TCONV(real 0.1) TMAX(real 0.25) ///
		K3(integer -1) SEED(integer -1) CORES(integer -1) FIRSTG(real -1) noDISPlay]
	if "`e(cmd)'" != "nwsaom" {
		di "{err}nwsaom refit needs the results of {bf:nwsaom} in memory (e(cmd) is " ///
			cond("`e(cmd)'" == "", "empty", "`e(cmd)'") ")."
		exit 301
	}
	if `"`e(cmdline)'"' == "" {
		di "{err}e(cmdline) is not stored; these results come from nwsaom 1.5.11 or earlier. Rerun the model with nwsaom 1.5.12 or later."
		exit 301
	}
	if `maxruns' < 1 {
		di "{err}maxruns() must be at least 1."
		exit 198
	}
	local run 0
	local done 0
	while !`done' {
		local ++run
		local cmd `"`e(cmdline)'"'
		// the options to replace: start values, and any option given here
		local drop theta0 behtheta0 rate0 ratecovcoef
		if `k3' >= 0 local drop `drop' k3
		if `seed' >= 0 local drop `drop' seed
		if `cores' >= 0 local drop `drop' cores
		if `firstg' >= 0 local drop `drop' firstg
		mata: st_local("cmd", _nwsaom_refit_strip(st_local("cmd"), tokens(st_local("drop"))))
		// coefficients: the network effects first, then the behavior effects
		tempname b
		matrix `b' = e(b)
		local pn = e(p_net)
		local pt = colsof(`b')
		local add ""
		local th ""
		forvalues j = 1/`pn' {
			local th `th' `=strofreal(`b'[1,`j'], "%21.0g")'
		}
		local add `"`add' theta0(`th')"'
		if `pt' > `pn' {
			local th ""
			forvalues j = `=`pn'+1'/`pt' {
				local th `th' `=strofreal(`b'[1,`j'], "%21.0g")'
			}
			local add `"`add' behtheta0(`th')"'
		}
		// rates: network-only models of one group (co-evolution models start the rates from the closed form)
		if !e(has_behavior) & "`e(groupvar)'" == "" & "`e(symtype)'" == "" & !e(conditional) {
			local r ""
			capture confirm matrix e(rates)
			if !_rc {
				tempname rr
				matrix `rr' = e(rates)
				forvalues j = 1/`=colsof(`rr')' {
					local r `r' `=strofreal(`rr'[1,`j'], "%21.0g")'
				}
			}
			else if e(rate) < . local r = strofreal(e(rate), "%21.0g")
			if "`r'" != "" local add `"`add' rate0(`r')"'
		}
		capture confirm matrix e(ratecoefs)
		if !_rc & "`e(ratecov)'" != "" {
			tempname rc
			matrix `rc' = e(ratecoefs)
			local r ""
			forvalues j = 1/`=colsof(`rc')' {
				local r `r' `=strofreal(`rc'[1,`j'], "%21.0g")'
			}
			local add `"`add' ratecovcoef(`r')"'
		}
		if `k3' >= 0 local add `"`add' k3(`k3')"'
		if `seed' >= 0 local add `"`add' seed(`seed')"'
		if `cores' >= 0 local add `"`add' cores(`cores')"'
		if `firstg' >= 0 local add `"`add' firstg(`firstg')"'
		if strpos(`"`cmd'"', ",") == 0 local cmd `"`cmd' ,"'
		local cmd `"`cmd'`add'"'
		local prevmax = e(tconv_max)
		if "`display'" == "" {
			di as text _n "{hline 78}"
			di as text "nwsaom refit, run `run'" cond(`maxruns' > 1, " of at most `maxruns'", "") ": starting from the last estimates" ///
				cond(`prevmax' < ., " (overall ratio " + strofreal(`prevmax', "%5.3f") + ")", "")
			di as text "{hline 78}"
		}
		if "`display'" != "" quietly `cmd'
		else `cmd'
		// convergence: every |t| below tconv() and the overall maximum below tmax()
		tempname tc
		matrix `tc' = e(tconv)
		local tworst 0
		forvalues j = 1/`=colsof(`tc')' {
			if abs(`tc'[1,`j']) < . local tworst = max(`tworst', abs(`tc'[1,`j']))
		}
		local conv = (`tworst' < `tconv') & (e(tconv_max) < `tmax')
		if "`display'" != "" di as text "nwsaom refit, run `run': largest |t| " as result %5.3f `tworst' ///
			as text ", overall ratio " as result %5.3f e(tconv_max) as text cond(`conv', " (converged)", "")
		if `conv' | `run' >= `maxruns' local done 1
	}
	ereturn scalar refit_runs = `run'
	ereturn scalar refit_converged = `conv'
	if "`display'" == "" | `run' > 1 {
		di as text _n "nwsaom refit: " as result `run' as text " run" cond(`run' > 1, "s", "") "; largest |t| " ///
			as result %5.3f `tworst' as text ", overall ratio " as result %5.3f e(tconv_max) ///
			as text cond(`conv', " (converged)", " (not converged)")
	}
end

mata:
// remove the options named in drop (with their parenthesised arguments)
// from a command line; an option counts only after a space or a comma
string scalar _nwsaom_refit_strip(string scalar cmd, string rowvector drop)
{
	real scalar i, k, j, depth, n, L, found
	string scalar low, out, nm, prev
	out = cmd
	for (k = 1; k <= cols(drop); k++) {
		nm = strlower(drop[k]) + "("
		L = strlen(nm)
		found = 1
		while (found) {
			found = 0
			low = strlower(out)
			n = strlen(out)
			for (i = 1; i <= n - L + 1; i++) {
				if (substr(low, i, L) != nm) continue
				prev = (i == 1 ? " " : substr(out, i - 1, 1))
				if (prev != " " & prev != ",") continue
				depth = 0
				for (j = i + L - 1; j <= n; j++) {
					if (substr(out, j, 1) == "(") depth++
					else if (substr(out, j, 1) == ")") {
						depth--
						if (depth == 0) break
					}
				}
				out = substr(out, 1, i - 1) + substr(out, j + 1, .)
				found = 1
				break
			}
		}
	}
	return(stritrim(strtrim(out)))
}
end

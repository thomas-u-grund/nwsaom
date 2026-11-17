*! version 1.8.0  17nov2026 nwsaom_refit 1.5.12 10nov2026
* nwsaom refit: rerun the last nwsaom fit, starting from its estimates
* (RSiena's prevAns), also after nwsaom multinet. The command is taken from e(cmdline); theta0(),
* behtheta0(), rate0() and ratecovcoef() are replaced by the estimates of
* the last fit. With maxruns(#) > 1 the refit is repeated until the
* convergence criteria are met (all |t| < tconv(), overall maximum
* convergence ratio < tmax()) or # runs have been made.
program nwsaom_refit, eclass
	version 14
	syntax [, MAXRUNS(integer 1) TCONV(real 0.1) TMAX(real 0.25) ///
		K3(integer -1) SEED(integer -1) CORES(integer -1) FIRSTG(real -1) noDISPlay *]
	// display options of the coefficient table (ci, level(), noci, nopvalues, cformat(), ...): given here, they replace
	// the display options of the stored command line
	local diopts `"`options'"'
	_nwsaom_tabopts __chk check, `diopts'
	if !inlist("`e(cmd)'", "nwsaom", "nwsaom_multinet") {
		di "{p 0 0 2}{err}nwsaom refit needs the results of {bf:nwsaom} or {bf:nwsaom multinet} in memory (e(cmd) is " ///
			cond("`e(cmd)'" == "", "empty", "`e(cmd)'") ").{p_end}"
		exit 301
	}
	if `"`e(cmdline)'"' == "" {
		di "{p 0 0 2}{err}e(cmdline) is not stored; these results come from an earlier release of nwsaom. Rerun the model with the current release.{p_end}"
		exit 301
	}
	local multinet = ("`e(cmd)'" == "nwsaom_multinet")
	if `multinet' & `cores' >= 0 {
		di "{err}cores() is not an option of nwsaom multinet."
		exit 198
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
		// (multinet: one theta0() with all coefficients, in the order of e(b))
		tempname b
		matrix `b' = e(b)
		local pn = cond(`multinet', colsof(`b'), e(p_net))
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
		if !`multinet' & !e(has_behavior) & "`e(groupvar)'" == "" & "`e(symtype)'" == "" & !e(conditional) {
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
		if !_rc & "`e(ratecov)'" != "" & !`multinet' {
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
		if `"`diopts'"' != "" {
			mata: st_local("cmd", _nwsaom_refit_stripdi(st_local("cmd")))
			local add `"`add' `diopts'"'
		}
		if strpos(`"`cmd'"', ",") == 0 local cmd `"`cmd' ,"'
		local cmd `"`cmd'`add'"'
		local prevmax = e(tconv_max)
		if "`display'" == "" {
			di as text _n "{hline 78}"
			di as text "{p 0 0 2}nwsaom refit, run `run'" cond(`maxruns' > 1, " of at most `maxruns'", "") ": starting from the last estimates" ///
				cond(`prevmax' < ., " (overall ratio " + strofreal(`prevmax', "%5.3f") + ")", "") "{p_end}"
			di as text "{hline 78}"
		}
		if "`display'" != "" quietly `cmd'
		else `cmd'
		// convergence: every |t| below tconv() and the overall maximum below tmax()
		tempname tc
		matrix `tc' = e(tconv)
		// fixed parameters are not judged (RSiena: the largest |t| over the estimated parameters)
		_nwsaom_tconvfixed fx
		local tworst 0
		forvalues j = 1/`=colsof(`tc')' {
			if "`: word `j' of `fx''" == "1" continue
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

// remove the display options of ereturn display (ci, level(), noci, cformat(), ..., also abbreviated) from the options
// of a command line (after the first comma outside parentheses and quotes)
string scalar _nwsaom_refit_stripdi(string scalar cmd)
{
	real scalar i, n, depth, inq, start, j, k, keep
	string scalar c, opts, out, tok, nm
	string rowvector full
	real rowvector minl

	full = ("level", "vsquish", "noallbaselevels", "allbaselevels", "nobaselevels", "baselevels", "nocnsreport",
		"fullcnsreport", "noemptycells", "emptycells", "noomitted", "omitted", "nolstretch", "lstretch", "coeflegend",
		"selegend", "cformat", "sformat", "pformat", "fvwrap", "fvwrapon", "nofvlabel", "fvlabel", "noci", "nopvalues",
		"markdown", "citype", "noabbrev", "abbrev", "ci")
	minl = (1, 7, 9, 7, 6, 4, 6, 8, 7, 5, 6, 4, 10, 8, 5, 8, 7, 7, 7, 6, 8, 8, 5, 4, 4, 8, 6, 8, 6, 2)
	n = strlen(cmd)
	depth = inq = start = 0
	for (i = 1; i <= n; i++) {
		c = substr(cmd, i, 1)
		if (c == `"""') inq = !inq
		if (inq) continue
		if (c == "(") depth++
		else if (c == ")") depth--
		else if (c == "," & depth == 0) {
			start = i
			break
		}
	}
	if (start == 0) return(cmd)
	out = substr(cmd, 1, start)
	opts = substr(cmd, start + 1, .)
	n = strlen(opts)
	i = 1
	while (i <= n) {
		if (substr(opts, i, 1) == " ") {
			i++
			continue
		}
		// one option: up to the next blank outside parentheses and quotes
		depth = inq = 0
		for (j = i; j <= n; j++) {
			c = substr(opts, j, 1)
			if (c == `"""') inq = !inq
			if (inq) continue
			if (c == "(") depth++
			else if (c == ")") depth--
			else if (c == " " & depth == 0) break
		}
		tok = substr(opts, i, j - i)
		nm = strlower(strpos(tok, "(") ? substr(tok, 1, strpos(tok, "(") - 1) : tok)
		keep = 1
		for (k = 1; k <= cols(full); k++) {
			if (strlen(nm) >= minl[k] & strlen(nm) <= strlen(full[k]) & substr(full[k], 1, strlen(nm)) == nm) keep = 0
		}
		if (keep) out = out + " " + tok
		i = j
	}
	return(stritrim(strtrim(out)))
}
end

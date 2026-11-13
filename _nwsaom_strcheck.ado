*! version 1.7.1  13nov2026 _nwsaom_strcheck: string variables in an nwsaom command (added in 1.5.16)
* Copyright (C) 2026 Thomas U. Grund
* Called by nwsaom with the command as typed. Every word that names a string
* variable is placed in its effect: the option around it, or the effect before
* a colon (behx(avsamexalt:sex), endow(altx:alc), eff1(samex:sex)).
* - Effects that compare categories (samex, nodematch, groups, the same*,
*   hom*, jump* and unequal* effects) only need to know which actors share a
*   value: the variable is returned in c_local __saom_strcat, and nwsaom runs
*   with it encoded (_nwstrcat of nwcommands 3.20.1).
* - Everywhere else the values are used as numbers (centered, averaged,
*   differences, behavior, rate covariates). A string was read as missing
*   without a message; it now stops with r(109).
* The sub-commands that work from a stored fit are not checked; refit and
* simulate rerun nwsaom and are checked there.
capture program drop _nwsaom_strcheck
program _nwsaom_strcheck
	version 14
	mata: _nwsaom_strscan(st_local("0"))
	if "`__num'" != "" {
		gettoken v rest : __num
		gettoken where : __numwhere
		di as err "{p 0 0 2}{bf:`v'} is a string variable, and {bf:`where'} uses the values of a covariate as numbers. Effects that compare categories (samex(), nodematch(), groups(), the same*, hom* and jump* effects) take a string variable; for {bf:`where'}, use a numeric variable.{p_end}"
		exit 109
	}
	if "`__cat'" != "" {
		capture findfile _nwstrcat.ado
		if _rc {
			gettoken v : __cat
			di as err "{p 0 0 2}{bf:`v'} is a string variable: string covariates need nwcommands 3.20.1 or later. Update nwcommands, or {bf:encode} the variable first.{p_end}"
			exit 109
		}
	}
	c_local __saom_strcat `__cat'
end

version 14
mata:
void _nwsaom_strscan(string scalar cmd)
{
	real scalar i, n, j, idx, iscat
	string scalar ch, tok, ctx, prevtok, catlist, numlist, numwhere, nxt, lc
	string colvector stack

	n = strlen(cmd)
	stack = J(0, 1, "")
	catlist = numlist = numwhere = ""
	prevtok = ""
	i = 1
	while (i <= n) {
		ch = substr(cmd, i, 1)
		if (regexm(ch, "[A-Za-z0-9_]")) {
			j = i
			while (j <= n) {
				if (!regexm(substr(cmd, j, 1), "[A-Za-z0-9_]")) break
				j++
			}
			tok = substr(cmd, i, j - i)
			nxt = (j <= n ? substr(cmd, j, 1) : "")
			if (nxt == "(") {
				stack = stack \ strlower(tok)
				i = j + 1
				prevtok = ""
				continue
			}
			if (nxt == ":") {
				prevtok = strlower(tok)
				i = j + 1
				continue
			}
			ctx = prevtok
			if (ctx == "" & rows(stack) > 0) ctx = stack[rows(stack)]
			prevtok = ""
			i = j
			if (substr(tok, 1, 3) == "_nw" | ctx == "") continue
			idx = _st_varindex(tok, 0)
			if (idx == .) continue
			if (!st_isstrvar(idx)) continue
			lc = ctx
			iscat = (lc == "nodematch" | lc == "groups" | strpos(lc, "same") | strpos(lc, "homx") | strpos(lc, "jumpx") | strpos(lc, "unequalx"))
			if (iscat) catlist = catlist + " " + tok
			else {
				numlist = numlist + " " + tok
				numwhere = numwhere + " " + ctx + "()"
			}
			continue
		}
		if (ch == "(") stack = stack \ ""
		else if (ch == ")") {
			if (rows(stack) > 1) stack = stack[1::rows(stack) - 1]
			else stack = J(0, 1, "")
		}
		if (ch != " " & ch != ":") prevtok = ""
		i++
	}
	// a variable used both ways: the numeric use decides (error)
	st_local("__cat", strtrim(catlist))
	st_local("__num", strtrim(numlist))
	st_local("__numwhere", strtrim(numwhere))
}
end

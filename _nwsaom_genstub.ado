*! version 1.7.0  13nov2026 nwcommands: check the names that generate() of estat simulate / nwsaom simulate will create
* Copyright (C) 2026 Thomas U. Grund
* This file is part of nwsaom, a Stata package derived from the R package 'RSiena' (Ripley, R. M., Snijders, T. A. B., Boda, Z., Voros, A., Preciado, P. and contributors; GPL-2 | GPL-3).
* nwsaom is free software: you can redistribute it and/or modify it under the terms of the GNU General
* Public License, version 3, as published by the Free Software Foundation. It is distributed in the hope
* that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
* or FITNESS FOR A PARTICULAR PURPOSE. See the file LICENSE for the full text.
/*
	_nwsaom_genstub stub, nsim(#) nperiods(#) [coev(0/1) groups(#) replace check]

	The networks (and, after a co-evolution fit, the variables) are named stub_<sim>_p<period>, after groups()
	stub_g<group>_<sim>_p<period>. Every name must be a Stata name of at most 32 characters, and without replace no network
	(or variable) of these names may exist. Checked before anything is simulated or created. With check, only the length is
	checked (the names of the groups are checked group by group when they are created).
	behnames(names): a fit with several behaviors; the behavior variables are stub_<sim>_p<period>_<name>.
*/
capture program drop _nwsaom_genstub
program define _nwsaom_genstub
	syntax name(name=stub), NSIM(integer) NPERiods(integer) [COEV(integer 0) GROUPS(integer 0) BEHNAMES(string) REPLACE CHECK]
	local gpart = cond(`groups' > 0, "_g`groups'", "")
	local longest "`stub'`gpart'_`nsim'_p`nperiods'"
	// several behaviors: the variables are stub_<sim>_p<period>_<behavior>
	local lvar ""
	foreach bn of local behnames {
		if ustrlen("`longest'_`bn'") > ustrlen("`lvar'") local lvar "`longest'_`bn'"
	}
	if ustrlen("`lvar'") > 32 {
		di as err "{p 0 0 2}generate(): the stub {bf:`stub'} is too long. The behavior variables are named {it:stub}_{it:simulation}_p{it:period}_{it:behavior} (for example {bf:`lvar'}), and names have at most 32 characters.{p_end}"
		exit 198
	}
	if ustrlen("`longest'") > 32 {
		di as err "{p 0 0 2}generate(): the stub {bf:`stub'} is too long. The networks are named {it:stub}`=cond(`groups' > 0, "_g{it:group}", "")'_{it:simulation}_p{it:period} (for example {bf:`longest'}), and names have at most 32 characters; use a stub of at most `=32 - ustrlen("`longest'") + ustrlen("`stub'")' characters.{p_end}"
		exit 198
	}
	capture confirm name `longest'
	if _rc {
		di as err "generate(): `longest' is not a valid name."
		exit 198
	}
	if "`check'" != "" | "`replace'" != "" exit
	forvalues s = 1/`nsim' {
		forvalues pd = 1/`nperiods' {
			local nm "`stub'`gpart'_`s'_p`pd'"
			quietly nwvalidate `nm'
			if "`r(exists)'" == "true" {
				di as err "{p 0 0 2}generate(): network {bf:`nm'} already exists. Specify option {bf:replace} to overwrite it, or use another stub.{p_end}"
				exit 483
			}
			foreach bn of local behnames {
				capture confirm variable `nm'_`bn', exact
				if _rc == 0 {
					di as err "{p 0 0 2}generate(): variable {bf:`nm'_`bn'} already exists. Specify option {bf:replace} to overwrite it, or use another stub.{p_end}"
					exit 110
				}
			}
			if `coev' & "`behnames'" == "" {
				capture confirm variable `nm', exact
				if _rc == 0 {
					di as err "{p 0 0 2}generate(): variable {bf:`nm'} already exists. Specify option {bf:replace} to overwrite it, or use another stub.{p_end}"
					exit 110
				}
			}
		}
	}
end

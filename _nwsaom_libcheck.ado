*! version 1.0.11  26oct2026 _nwsaom_libcheck - make the nwsaom Mata libraries visible; clear message when the core nwcommands and nwsaom Mata libraries do not match
* Copyright (C) 2026 Thomas U. Grund
* This file is part of nwsaom (GPL-3, see the file LICENSE).
* Stata indexes the Mata libraries (.mlib) once, early in a session. Libraries installed by net install can be missing from that
* index in a session (even a new one), and then Mata stops with r(3499) "<function>() not found". So this program, which every
* entry point of nwsaom calls first, checks that library functions are visible and runs -mata mlib index- once when they are not.
capture program drop _nwsaom_libcheck
program define _nwsaom_libcheck
	version 14
	capture mata: mata which SaomRatesReset()
	local __lc1 = _rc
	capture mata: mata which __nwsaom_libcheck()
	if `__lc1' | _rc {
		capture mata: mata mlib index
	}
	capture mata: __nwsaom_libcheck()
	if _rc == 3021 | _rc == 3260 {
		di as error "the installed core nwcommands and nwsaom were built for different versions"
		di as error "reinstall the model package: nwinstall, models   (or: net install nwsaom, from(...) replace)"
		exit 3021
	}
end

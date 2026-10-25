*! version 1.0.4  25oct2026 _nwsaom_libcheck - clear message when the core nwcommands and nwsaom Mata libraries do not match
* Copyright (C) 2026 Thomas U. Grund
* This file is part of nwsaom (GPL-3, see the file LICENSE).
capture program drop _nwsaom_libcheck
program define _nwsaom_libcheck
	version 14
	capture mata: __nwsaom_libcheck()
	if _rc == 3021 {
		di as error "the installed core nwcommands and nwsaom were built for different versions"
		di as error "reinstall the model package: nwinstall, models   (or: net install nwsaom, from(...) replace)"
		exit 3021
	}
end

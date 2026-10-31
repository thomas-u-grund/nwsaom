*! version 1.4.2  31oct2026 _nwsaom_dlgprep.ado -- fills the lists of the nwsaom dialogs when a dialog opens
* Copyright (C) 2026 Thomas U. Grund
* Part of nwsaom (GPL-3, see LICENSE). Called by the dialogs (PROGRAM initialize); works with core 3.12.1.
* Fills, for the dialog named in the argument: netlist (network names) and netlist_a (one action per network that sets the
* "Network type" drop-down: directed, undirected or two-mode) and, for the simulate dialog, fitlist (one entry: "fit" if the
* last estimation was nwsaom, else "nofit").
capture program drop _nwsaom_dlgprep
program _nwsaom_dlgprep
	version 14
	syntax anything(name=dialogname)
	local d ".`dialogname'_dlg"
	qui nwset
	local nets "`r(nets)'"
	capture `d'.netlist.Arrdropall
	capture `d'.netlist_a.Arrdropall
	capture `d'.fitlist.Arrdropall
	`d'.netlist.Arrpush " "
	capture `d'.netlist_a.Arrpush "script nettype_auto"
	foreach n of local nets {
		local act "nettype_auto"
		capture {
			_nwsyntax `n', max(1)
			if "`is2mode'" == "true" local act "nettype_b"
			else if "`directed'" == "true" local act "nettype_d"
			else local act "nettype_u"
		}
		`d'.netlist.Arrpush "`n'"
		capture `d'.netlist_a.Arrpush "script `act'"
	}
	local f "nofit"
	if `"`e(cmd)'"' == "nwsaom" local f "fit"
	capture `d'.fitlist.Arrpush "`f'"
end

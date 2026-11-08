cscript

* Regression test: RSiena's finite-difference phase 1 (CalculateDerivative and phase1.1 in R/phase1.r). An effect of a
* constant covariate has a statistic that never changes, so the score-function derivative has a zero diagonal element:
* phase 1 is doubled to 200 simulations, then run with finite differences (with 4 restarts for a larger epsilon), and the
* effect is fixed. The other estimates must be those of the model without it. Network-only and co-evolution estimators.

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

nwwebuse glasgow, nwclear
gen one = 1

program _fd_note_seen, rclass
	args logf
	tempname fh
	local seen 0
	file open `fh' using `"`logf'"', read text
	file read `fh' line
	while r(eof) == 0 {
		if strpos(`"`line'"', "phase 1 was run again with finite differences") local seen 1
		file read `fh' line
	}
	file close `fh'
	return scalar seen = `seen'
end

* network only
tempfile lg
log using `"`lg'"', text replace name(fd)
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity egox(one) seed(1) cores(1)
log close fd
_fd_note_seen `"`lg'"'
assert r(seen) == 1
assert _b[egox_one] == 0
assert abs(_b[outdegree] + 2.39) < 0.15
assert abs(_b[reciprocity] - 2.85) < 0.3
di as text "  PASS: network-only fit falls back to finite differences and fixes the dead effect"

* co-evolution
log using `"`lg'"', text replace name(fd)
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity egox(one) behavior(alcohol1 alcohol2 alcohol3) linear avalt seed(1) cores(1)
log close fd
_fd_note_seen `"`lg'"'
assert r(seen) == 1
assert _b[egox_one] == 0
assert abs(_b[outdegree] + 2.39) < 0.15
di as text "  PASS: co-evolution fit falls back to finite differences and fixes the dead effect"

* an ordinary fit does not use finite differences
log using `"`lg'"', text replace name(fd)
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity seed(1) cores(1)
log close fd
_fd_note_seen `"`lg'"'
assert r(seen) == 0
di as text "  PASS: no finite differences in an ordinary fit"
di as result "ALL TESTS PASSED"

cscript

* Long messages wrap at word boundaries (1.5.15). Stata cuts a display line that is longer than the linesize at exactly that
* column, in the middle of a word ("... the data say little about chang" / "> e."); the messages are now SMCL paragraphs.
* The test sets linesize 80 (as in the book), triggers an error of nwsaom and the Jaccard note of nwsaom describe, and
* checks the log text.

local nwcore : env NWCORE
if `"`nwcore'"' == "" {
	di as error "set the environment variable NWCORE to the directory of the nwcommands (core) package"
	exit 198
}
adopath ++ `"`nwcore'"'
adopath ++ `"`c(pwd)'"'
quietly do `"`nwcore'/unw_core.do"'
do unw_saom.do

* _mw_check logfile "message": the message must appear in the log, joined from its output lines (trimmed, joined with one
* space) exactly as written, on at least two lines, none longer than the linesize and none a hard-wrap continuation ("> ").
capture program drop _mw_check
program _mw_check
	args logf msg
	local start = substr(`"`macval(msg)'"', 1, 30)
	tempname fh
	local found 0
	local nl 0
	local hard 0
	local toolong 0
	local joined ""
	file open `fh' using `"`logf'"', read text
	file read `fh' line
	while r(eof) == 0 {
		if `found' == 1 & strlen(`"`macval(joined)'"') < strlen(`"`macval(msg)'"') {
			if substr(`"`macval(line)'"', 1, 2) == "> " local hard 1
			if strlen(`"`macval(line)'"') > 80 local toolong 1
			local t = trim(`"`macval(line)'"')
			local joined `"`macval(joined)' `macval(t)'"'
			local ++nl
		}
		if `found' == 0 & strpos(trim(`"`macval(line)'"'), `"`macval(start)'"') == 1 {
			local found 1
			if strlen(`"`macval(line)'"') > 80 local toolong 1
			local joined = trim(`"`macval(line)'"')
			local nl 1
		}
		file read `fh' line
	}
	file close `fh'
	di as text "  lines: `nl'  hard wrap: `hard'  too long: `toolong'"
	assert `found' == 1
	assert `nl' >= 2
	assert `hard' == 0
	assert `toolong' == 0
	assert `"`macval(joined)'"' == `"`macval(msg)'"'
	di as text "  PASS: wraps at word boundaries: " substr(`"`macval(msg)'"', 1, 50) "..."
end

set linesize 80
tempfile l1 l2

* two independent random waves: few ties stay (Jaccard far below 0.3)
nwclear
clear
mata: rseed(11); n = 30
mata: R = (runiform(n, n) :< 0.1) :* (1 :- I(n)); st_matrix("W1", R)
mata: R = (runiform(n, n) :< 0.1) :* (1 :- I(n)); st_matrix("W2", R)
nwset, mat(W1) directed name(w1) nooutput
nwset, mat(W2) directed name(w2) nooutput

* 1. error of nwsaom (also shows that nwsaom.ado still loads: the program is near Stata's size limit)
log using `l1', text replace name(mw1)
capture noisily nwsaom, waves(w1 w2) wave1(w1) wave2(w2) outdegree
local rc = _rc
log close mw1
assert `rc' == 198
_mw_check `l1' "specify either wave1(netname)/wave2(netname) (exactly two waves) or waves(netlist) (two or more waves), not both."

* 2. note of nwsaom describe
log using `l2', text replace name(mw2)
nwsaom describe, waves(w1 w2)
log close mw2
_mw_check `l2' "Note: Jaccard < 0.3 in period 1->2; few ties stay, the data say little about change."

di as result "ALL TESTS PASSED"

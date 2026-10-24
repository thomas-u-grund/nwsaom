capture program drop nwinstall
sysdir set PLUS "/private/tmp/claude-501/-Users-tgrund-FILES-NEW-SOFTWARE-nwcommands/f80eded9-2ca1-45e7-9a6b-23ada6a895b2/scratchpad/emptyplus"
adopath ++ "/private/tmp/claude-501/-Users-tgrund-FILES-NEW-SOFTWARE-nwcommands/f80eded9-2ca1-45e7-9a6b-23ada6a895b2/scratchpad/dev"
adopath ++ "/Users/tgrund/FILES_NEW/SOFTWARE/nwsaom"
adopath ++ "/Users/tgrund/FILES_NEW/SOFTWARE/nwsaom/lib/plugins/macos"
quietly do "/private/tmp/claude-501/-Users-tgrund-FILES-NEW-SOFTWARE-nwcommands/f80eded9-2ca1-45e7-9a6b-23ada6a895b2/scratchpad/dev/unw_core.do"
do unw_saom.do
* Behavior centring with missing behavior data: compare with dev/saom_rsiena_behcentre.R (run it first; it writes the data).
nwclear
forvalues w = 1/3 {
	import delimited "dev/saom_r1614_s50_w`w'.csv", clear varnames(1)
	mkmat v1-v50, matrix(W`w')
}
forvalues w = 1/3 {
	nwset, mat(W`w') directed name(c`w') nooutput
}
import delimited "dev/saom_behcentre_data.csv", clear varnames(1)
local tags : environ CENTRE_TAGS
if "`tags'" == "" local tags "miss complete"
* (run one tag per Stata process: CENTRE_TAGS=complete)
foreach t of local tags {
	foreach s in 1 2 3 {
		if "`t'" == "miss" capture noisily nwsaom, waves(c1 c2 c3) outdegree reciprocity behavior(a1 a2 a3 : linear quadratic avalt) missbeh(m1 m2 m3) seed(`s')
		else {
			capture noisily nwsaom, waves(c1 c2 c3) outdegree reciprocity behavior(f1 f2 f3 : linear quadratic avalt) seed(`s')
		}
		matrix b = e(b)
		di "CENTRE `t' seed `s': " _newline "  b " b[1,1] " " b[1,2] " " b[1,3] " " b[1,4] " " b[1,5] " " b[1,6]
		di "  behmean " %12.8f e(behmean)
	}
}

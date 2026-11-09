* Checks that nwcommands' copy of the Glasgow excerpt (nwwebuse glasgow, used by the article and the
* Stata scripts) holds the same data as the CSV files in data/glasgow, which R/01_check_data.R checks
* against RSiena's copy. nwcommands stores the 50 pupils in the order of their labels as text
* (n1, n10, n11, ...); the check matches the pupils by label.
do stata/setup.do
local bad 0
nwwebuse glasgow, nwclear
gen long id = real(substr(_nwnode, 2, .))
mkmat id, matrix(ID)
forvalues w = 1/3 {
	nwtomata glasgow`w', mat(G`w')
	preserve
	quietly import delimited using "data/glasgow/s50_friend_w`w'.csv", clear varnames(nonames)
	mkmat v1-v50, matrix(C)
	restore
	mata: id = st_matrix("ID"); C = st_matrix("C")[id, id]; G = editmissing(G`w', 0)
	mata: st_local("same", strofreal(G == C))
	di as text "Glasgow friendship wave `w'" _col(42) cond(`same', "identical", "DIFFERENT")
	if !`same' local bad 1
}
mkmat smoke1 smoke2 smoke3 alcohol1 alcohol2 alcohol3, matrix(A)
preserve
quietly import delimited using "data/glasgow/s50_actors.csv", clear varnames(1)
mkmat smoke1 smoke2 smoke3 alcohol1 alcohol2 alcohol3, matrix(B)
restore
mata: st_local("same", strofreal(st_matrix("A") == st_matrix("B")[id, .]))
di as text "Glasgow smoking and alcohol use" _col(42) cond(`same', "identical", "DIFFERENT")
if !`same' local bad 1
di as text cond(`bad', "Some data differ.", "All data identical.")

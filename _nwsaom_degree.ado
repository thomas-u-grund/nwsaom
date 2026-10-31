*! _nwsaom_degree: spelling of the outdegree (density) effect: outdegree, degree or density (RSiena's names)
*! the label of the coefficient follows the spelling typed, as for egox()/altx()/samex()
program define _nwsaom_degree, sclass
	version 17
	args degree density outdegree
	sreturn clear
	local lab "outdegree"
	if "`degree'`density'" != "" {
		if "`outdegree'" != "" | ("`degree'" != "" & "`density'" != "") {
			di as error "specify only one of outdegree, degree and density - they are the same effect"
			exit 198
		}
		local outdegree "outdegree"
		local lab = cond("`degree'" != "", "degree", "density")
	}
	sreturn local od "`outdegree'"
	sreturn local lab "`lab'"
end

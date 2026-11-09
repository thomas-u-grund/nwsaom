* Reads the 50 pupils of the Teenage Friends and Lifestyle Study (the s50 data of RSiena), treated as three groups of 15, 20 and 15 actors
* (pupils 1-15, 16-35, 36-50; ties between the groups are removed): wave networks g1 g2 g3 (block-diagonal) and the
* variables group, alc1 alc2 alc3 (alcohol use at the three waves, 1 to 5) in the data set.
nwclear
quietly import delimited using "data/groups/s50g_actors.csv", clear
forvalues w = 1/3 {
    preserve
    quietly import delimited using "data/groups/s50g_wave`w'.csv", clear varnames(nonames)
    quietly mkmat v*, matrix(W`w')
    restore
    nwset, mat(W`w') directed name(g`w') nooutput
}

* Example 1: fifteen school classes in one joint model (nwsaom with groups()); the example of the book's chapter on SAOMs
* The classes are a data set of nwcommands (nwwebuse baerveldt); nwstack stacks them into one data set:
* 810 actors, group variable class, wave networks w1 and w2 without ties between classes.
do stata/setup.do
set linesize 80
capture mkdir results/article
log using results/article/groups_joint.log, text replace nomsg
nwwebuse baerveldt, nwclear
local w1 ""
local w2 ""
forvalues k = 1/15 {
    local w1 `w1' class`k'_w1
    local w2 `w2' class`k'_w2
}
clear
nwstack `w1', name(w1) group(class)
nwstack `w2', name(w2)
nwsaom describe, waves(w1 w2)
* ONE model for all classes: the same three effects everywhere, one rate per class;
* a first fit, then a restart from its estimates (as in the book)
quietly nwsaom, waves(w1 w2) groups(class) outdegree reciprocity transtrip seed(1)
matrix b = e(b)
nwsaom, waves(w1 w2) groups(class) outdegree reciprocity transtrip seed(2) theta0(`=b[1,1]' `=b[1,2]' `=b[1,3]')
estimates store joint
* what the fit stored about the groups
display "groups: " e(ngroups) "   actors: " e(N)
matrix list e(groupn)
matrix list e(rates_group)
log close

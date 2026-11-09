* Example 1: four school classes in one joint model (nwsaom with groups())
* stata/groups_stack_classes.do reads the eight csv files and builds the stacked data set:
* 151 actors (45 + 37 + 33 + 36), group variable class, wave networks w1 and w2 without ties between classes.
do stata/setup.do
set linesize 100
do stata/groups_stack_classes.do
capture mkdir results/article
log using results/article/groups_joint.log, text replace nomsg

* the stacked data set: one row per actor, the group variable says which class
tabulate class

* the two wave networks of all classes together
nwsaom describe, waves(w1 w2)

* ONE model for all classes: the same three effects everywhere, one rate per class
nwsaom, waves(w1 w2) groups(class) outdegree reciprocity transtrip seed(5)

* what the fit stored about the groups
display "groups: " e(ngroups) "   actors: " e(N)
matrix list e(groupn)
matrix list e(rates_group)
matrix list e(rates_period)
log close

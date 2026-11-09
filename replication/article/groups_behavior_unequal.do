* Example 3: co-evolution of friendship and alcohol use in three groups, and groups observed at different waves
* stata/groups_stack_s50.do builds the stacked data set: 50 actors in three groups (15, 20, 15), wave networks g1 g2 g3, behavior alc1 alc2 alc3
do stata/setup.do
set linesize 100
do stata/groups_stack_s50.do
capture mkdir results/article
log using results/article/groups_behavior_unequal.log, text replace nomsg

tabulate group
summarize alc1 alc2 alc3
nwsaom describe, waves(g1 g2 g3)

* (a) network and behavior together: selection (egox, altx) and influence (average alter)
nwsaom, waves(g1 g2 g3) groups(group) outdegree reciprocity transtrip ///
    behavior(alc1 alc2 alc3) linear quadratic avalt behegox behaltx seed(1)
matrix list e(rates)
matrix list e(rates_beh)

* (b) unequal waves: group 1 observed at all three waves, group 2 only at waves 1 and 2, group 3 only at waves 2 and 3
nwsaom, waves(g1 g2 g3) groups(group) gwaves(2: 1 2 | 3: 2 3) outdegree reciprocity transtrip seed(1)
matrix list e(groupwaves)
matrix list e(rates_group)
matrix list e(rates_period)
log close

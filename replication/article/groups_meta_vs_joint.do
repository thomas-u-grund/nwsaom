* Example 2: the same four classes fitted separately (then combined with nwsaom meta) and jointly
do stata/setup.do
set linesize 100
do stata/groups_stack_classes.do              // stacked data set (151 actors, variable class) and networks w1 w2
* the same classes as four separate pairs of networks school1_w1 school1_w2 ... school4_w2
forvalues s = 1/4 {
    forvalues w = 1/2 {
        quietly import delimited using "data/groups/school`s'_wave`w'.csv", clear
        local n = _N
        quietly mkmat v1-v`n', matrix(X`w')
        matrix X`w' = X`w' - diag(vecdiag(X`w'))
    }
    nwset, mat(X1) directed name(school`s'_w1) nooutput
    nwset, mat(X2) directed name(school`s'_w2) nooutput
}
* import delimited replaced the data in memory: rebuild the group variable of the stacked data set
clear
quietly set obs 151
quietly generate byte class = 1 in 1/45
quietly replace class = 2 in 46/82
quietly replace class = 3 in 83/115
quietly replace class = 4 in 116/151
capture mkdir results/article
log using results/article/groups_meta_vs_joint.log, text replace nomsg

* (a) four separate fits of the same model, stored
forvalues s = 1/4 {
    quietly nwsaom, wave1(school`s'_w1) wave2(school`s'_w2) outdegree reciprocity transtrip seed(5)
    estimates store school`s'
}
estimates table school1 school2 school3 school4, b(%7.3f) se(%7.3f) title("Separate fits, one per class")

* (b) combine the four fits: mean effect, between-class standard deviation, heterogeneity test
nwsaom meta school1 school2 school3 school4

* (c) one joint model for all classes
nwsaom, waves(w1 w2) groups(class) outdegree reciprocity transtrip seed(5)
estimates store joint

* (d) side by side: the joint estimate lies close to the mean of the classes
quietly nwsaom meta school1 school2 school3 school4, notable
matrix T = r(theta)
matrix meanT = J(1, 4, 0.25) * T                 // simple average of the four separate estimates
matrix MM = r(meta)
local c = colnumb(MM, "iwls_mean")
matrix iwls = MM[1..3, `c']'                     // IWLS mean of every effect
estimates restore joint                          // nwsaom meta leaves the last class active
matrix jt = e(b)
matrix cmp = meanT \ iwls \ jt
matrix rownames cmp = avg_classes meta_IWLS joint
matrix colnames cmp = outdegree reciprocity transtrip
matrix list cmp, format(%7.3f)

* (e) a joint model in which reciprocity may differ for class 2: add an indicator and its interaction
generate byte c2 = (class == 2)
nwsaom, waves(w1 w2) groups(class) outdegree reciprocity transtrip egox(c2) interact(egox_c2#reciprocity) seed(5)
log close

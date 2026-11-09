* Example 2: the same fifteen classes fitted separately (then combined with nwsaom meta) and jointly; the commands of the book
do stata/setup.do
set linesize 80
do stata/groups_stack_classes.do              // stacked data set (810 actors, variable class), networks w1 w2, and class1_w1 ... class15_w2
capture mkdir results/article
log using results/article/groups_meta_vs_joint.log, text replace nomsg

* (a) fifteen separate fits of the same model (a first fit, then a restart from its estimates), stored
local fits ""
forvalues s = 1/15 {
    quietly nwsaom, waves(class`s'_w1 class`s'_w2) outdegree reciprocity transtrip seed(1)
    matrix b = e(b)
    quietly nwsaom, waves(class`s'_w1 class`s'_w2) outdegree reciprocity transtrip seed(2) theta0(`=b[1,1]' `=b[1,2]' `=b[1,3]')
    estimates store class`s'
    display "class `s': max convergence ratio " %5.3f e(tconv_max)
    local fits `fits' class`s'
}
estimates table `fits', b(%7.3f) se(%7.3f) title("Separate fits, one per class")

* (b) combine the fifteen fits: mean effect, between-class standard deviation, heterogeneity test
nwsaom meta `fits'

* (c) one joint model for all classes (as in groups_joint.do)
quietly nwsaom, waves(w1 w2) groups(class) outdegree reciprocity transtrip seed(1)
matrix b = e(b)
nwsaom, waves(w1 w2) groups(class) outdegree reciprocity transtrip seed(2) theta0(`=b[1,1]' `=b[1,2]' `=b[1,3]')
estimates store joint

* (d) side by side: simple average of the classes, IWLS mean, joint estimate; standard errors of the joint and the IWLS mean
quietly nwsaom meta `fits', notable
matrix T = r(theta)
matrix meanT = J(1, 15, 1/15) * T
matrix MM = r(meta)
matrix iwls = MM[1..3, colnumb(MM, "iwls_mean")]'
matrix iwlsse = MM[1..3, colnumb(MM, "iwls_se")]'
estimates restore joint
matrix jt = e(b)
matrix V = e(V)
matrix jse = (sqrt(V[1,1]), sqrt(V[2,2]), sqrt(V[3,3]))
matrix cmp = meanT \ iwls \ jt[1, 1..3] \ iwlsse \ jse
matrix rownames cmp = avg_classes meta_IWLS joint se_meta se_joint
matrix colnames cmp = outdegree reciprocity transtrip
matrix list cmp, format(%7.3f)

* (e) a joint model in which reciprocity may differ for class 1, the class with the largest separate estimate
generate byte c1 = (class == 1)
nwsaom, waves(w1 w2) groups(class) outdegree reciprocity transtrip egox(c1) interact(egox_c1#reciprocity) seed(2) theta0(`=b[1,1]' `=b[1,2]' `=b[1,3]' 0 0)
log close

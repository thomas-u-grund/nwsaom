* Network plots of the three Glasgow waves (figure fig_glasgow_waves.pdf of the article).
* Run from the replication folder: do article/plot_glasgow.do   Output in results/article.
do stata/setup.do
capture mkdir results
capture mkdir results/article
cd results/article
capture set scheme stsj
if _rc set scheme sj
nwwebuse glasgow, nwclear
* one layout for all waves: computed once (from the second wave), then reused with nodexy()
nwplot glasgow2, layout(kk) generate(gx gy) nodraw
local opt color(smoke1, colorpalette(gs11 gs6 black)) symbol(smoke1, legendoff symbolpalette(circle diamond square)) nodefactor(1) arrowfactor(.7) legend(rows(1) size(small)) xsize(3) ysize(3)
nwplot glasgow1, nodexy(gx gy) `opt' title("Wave 1") name(w1, replace)
nwplot glasgow2, nodexy(gx gy) `opt' title("Wave 2") name(w2, replace)
nwplot glasgow3, nodexy(gx gy) `opt' title("Wave 3") name(w3, replace)
graph combine w1 w2 w3, rows(1) xsize(7.2) ysize(2.5) name(glasgow_waves, replace)
graph export fig_glasgow_waves.pdf, name(glasgow_waves) replace
cd "$REP"

* Figures and listings of the plot examples (Glasgow data). Run from manual/fig with
*   NWCORE=<core directory> NWSAOM=<nwsaom directory> PLUSDIR=<empty scratch dir> StataBE -e do mkfigs.do
capture program drop nwinstall
local plus : env PLUSDIR
local core : env NWCORE
local pkg  : env NWSAOM
sysdir set PLUS "`plus'"
adopath ++ "`core'"
adopath ++ "`core'/lib"
adopath ++ "`pkg'"
adopath ++ "`pkg'/lib"
adopath ++ "`pkg'/lib/plugins/macos"
set more off
nwclear
nwwebuse glasgow, nwclear
nwsaom version

*# gof
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip seed(1)
estat gof, seed(1) name(gof) export(fig.pdf)
estat convergence
estat convergence, plot export(fig_convergence.pdf)

*# timetest
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip k0(100) k3(1000) seed(1)
estat timetest, plot export(fig_timetest.pdf)

*# meta
nwwebuse glasgow, nwclear
nwsaom simulate, wave1(glasgow1) wave2(glasgow2) outdegree reciprocity transtrip theta(-2.3 2 0.5) rates(5) nsim(4) seed(7) generate(g)
forvalues s = 1/4 {
    quietly nwsaom, wave1(glasgow1) wave2(g_`s'_p1) outdegree reciprocity transtrip k3(500) seed(`s')
    estimates store grp`s'
}
nwsaom meta grp1 grp2 grp3 grp4, plot export(fig_meta.pdf)
exit

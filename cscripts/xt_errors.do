* Extended tests: ERROR PATHS. Every command below must stop with the exact r() code the code raises (file:line in the comment),
* and leave the estimation results (e(b), e(V), e(cmd), e(cmdline), e(waves)), the data (datasignature, N, k) and the networks
* (number, current network) unchanged. After the nwsaom errors, estat simulate of the stored fit must also give the same
* numbers as before (the failing calls use the same waves and effects as the stored fit, so even a call that fails after it has
* rebuilt the Mata model leaves an identical model; failing calls with OTHER data are probed in xt_suspects.do).
* Codes of Stata itself (syntax, numlist, unab) are marked "Stata"; their exact values are expected, not read from nwsaom.
* DRAFT, not yet run. Expected runtime: about 1-2 minutes (3 fits; every other call stops early).
cscript
local nwcore : env NWCORE
if `"`nwcore'"' == "" {
	di as error "set the environment variable NWCORE to the directory of the nwcommands (core) package"
	exit 198
}
quietly do `"`nwcore'/unw_core.do"'
do unw_saom.do
set linesize 255
do cscripts/xt_common.do

* xt_err code : command  - runs the command, asserts r(code), unchanged e(), data and networks, and (when $XT_SIMCHK is 1)
* the same estat simulate numbers as the snapshot matrix __XT_SIM0
capture program drop xt_err
program define xt_err
	gettoken code 0 : 0
	gettoken colon 0 : 0, parse(":")
	capture noisily `0'
	local rc = _rc
	if `rc' != `code' {
		di as error "expected r(`code'), got r(`rc'): `0'"
		exit 9
	}
	xt_esame
	xt_dsame
	if "$XT_SIMCHK" == "1" {
		quietly estat simulate, nsim(2) seed(5)
		tempname S
		matrix `S' = r(sim)
		assert mreldif(`S', __XT_SIM0) == 0
	}
	di as text "  ok r(`code'): `0'"
end

nwclear
clear
set obs 30
mata: xt_dir("D", 30, 3, 0.10, 0.05, 11)
mata: xt_sym("S", 30, 2, 0.10, 0.05, 12)
mata: xt_tm("TM", 30, 8, 2, 0.15, 0.10, 13)
forvalues w = 1/3 {
	nwset, mat(D`w') directed name(dn`w') nooutput
}
forvalues w = 1/2 {
	nwset, mat(S`w') undirected name(sn`w') nooutput
	nwset, mat(S`w') directed name(sd`w') nooutput
}
* a valued wave (a tie value 2), a wave of another size, a two-mode wave
matrix V2 = D2
matrix V2[1, 2] = 2
nwset, mat(V2) directed name(vn2) nooutput
mata: st_matrix("D31", st_matrix("D1")[|1, 1 \ 29, 29|])
nwset, mat(D31) directed name(small1) nooutput
gen double x = mod(_n * 7, 11) / 3
gen byte p1 = 1
gen byte p2 = 1
gen byte p3 = 1
gen byte pbad = cond(_n == 3, 2, 1)
gen double z1 = mod(_n, 4) + 1
gen double z2 = mod(_n + (_n > 15), 4) + 1
gen double z3 = mod(_n + (_n > 10), 4) + 1
gen byte grp = 1 + (_n > 15)
matrix MS0 = J(30, 30, 0)
matrix MSbig = J(31, 31, 0)
matrix MSbad = J(30, 30, 0)
matrix MSbad[1, 2] = 2

* the stored fit, its snapshot and the baseline simulation
nwsaom, waves(dn1 dn2 dn3) outdegree reciprocity k0(10) k3(60) seed(3)
estimates store base
xt_esnap
xt_dsnap
quietly estat simulate, nsim(2) seed(5)
matrix __XT_SIM0 = r(sim)
global XT_SIMCHK 1

* ---------------------------------------------------------------------------------------------------------------------------
* 1. nwsaom: waves and data
* ---------------------------------------------------------------------------------------------------------------------------
* nwsaom.ado:280 nwunab ..., min(2) -> Stata unab: too few names
xt_err 102 : nwsaom, waves(dn1) outdegree reciprocity k3(60)
* nwunab -> Stata unab: name not found
xt_err 111 : nwsaom, waves(dn1 nosuchnet dn3) outdegree reciprocity k3(60)
* _nwsyntax.ado:71 errNWsNotFound
xt_err 482 : nwsaom, wave1(nosuchnet) wave2(dn2) outdegree reciprocity k3(60)
* nwsaom.ado:278 wave1()/wave2() together with waves()
xt_err 198 : nwsaom, wave1(dn1) wave2(dn2) waves(dn1 dn2 dn3) outdegree reciprocity k3(60)
* nwsaom.ado:292 wave1() without wave2()
xt_err 198 : nwsaom, wave1(dn1) outdegree reciprocity k3(60)
* nwsaom.ado:304 no outdegree
xt_err 198 : nwsaom, waves(dn1 dn2 dn3) reciprocity k3(60)
* _nwsaom_chkbin.ado:38 a tie value other than 0/1/10/11
xt_err 198 : nwsaom, waves(dn1 vn2 dn3) outdegree reciprocity k3(60)
* nwsaom.ado:478 waves of different sizes
xt_err 198 : nwsaom, waves(small1 dn2 dn3) outdegree reciprocity k3(60)
* nwsaom.ado:582 symmetric with waves that are not tie-symmetric
xt_err 198 : nwsaom, waves(dn1 dn2 dn3) outdegree symmetric k3(60)
* nwsaom.ado:565 undirected waves mixed with asymmetric directed ones
xt_err 198 : nwsaom, waves(sn1 dn2) outdegree k3(60)
* _nwsaom_symcheck.ado:56 symtype() not a model type
xt_err 198 : nwsaom, waves(sn1 sn2) outdegree symtype(bogus) k3(60)
* _nwsaom_symcheck.ado:103 symtype() for a directed relation
xt_err 198 : nwsaom, waves(dn1 dn2 dn3) outdegree reciprocity symtype(joint) k3(60)
* _nwsaom_symcheck.ado:19 reciprocity in a non-directed model (undirected waves: symmetric is set automatically)
xt_err 198 : nwsaom, waves(sn1 sn2) outdegree reciprocity k3(60)
* _nwsaom_symcheck.ado:16 transtrip under symmetric (symbad)
xt_err 198 : nwsaom, waves(sn1 sn2) outdegree transtrip k3(60)
* nwsaom.ado:1467 transtriads for a directed relation (fails after the Mata model was rebuilt with another effect list:
* no simulation check here, see xt_suspects.do)
global XT_SIMCHK 0
xt_err 198 : nwsaom, waves(dn1 dn2 dn3) outdegree reciprocity transtriads k3(60)
global XT_SIMCHK 1
di "PASS errors: waves and data"

* ---------------------------------------------------------------------------------------------------------------------------
* 2. nwsaom: options
* ---------------------------------------------------------------------------------------------------------------------------
* Stata syntax: an option nwsaom does not have
xt_err 198 : nwsaom, waves(dn1 dn2 dn3) outdegree reciprocity nosuchoption k3(60)
* Stata numlist: rate0() must be > 0
xt_err 125 : nwsaom, waves(dn1 dn2 dn3) outdegree reciprocity rate0(-1) unconditional k3(60)
* nwsaom.ado:2960 theta0() with the wrong number of values
xt_err 198 : nwsaom, waves(dn1 dn2 dn3) outdegree reciprocity theta0(-1) k3(60)
* nwsaom.ado:2990 fix() names an effect that is not in the model
xt_err 198 : nwsaom, waves(dn1 dn2 dn3) outdegree reciprocity theta0(-1 1) fix(transtrip) k3(60)
* nwsaom.ado:3043 cores() negative
xt_err 198 : nwsaom, waves(dn1 dn2 dn3) outdegree reciprocity cores(-1) k3(60)
* nwsaom.ado:226 nodeocov() and egox() together
xt_err 198 : nwsaom, waves(dn1 dn2 dn3) outdegree reciprocity egox(x) nodeocov(x) k3(60)
* nwsaom.ado:633 present() with the wrong number of variables
xt_err 198 : nwsaom, waves(dn1 dn2 dn3) outdegree reciprocity present(p1 p2) k3(60)
* nwsaom.ado:947 present() not coded 0/1
xt_err 198 : nwsaom, waves(dn1 dn2 dn3) outdegree reciprocity present(p1 pbad p3) k3(60)
* _nwsaom_precheck.ado:105 joinat() together with present()
xt_err 198 : nwsaom, waves(dn1 dn2 dn3) outdegree reciprocity present(p1 p2 p3) joinat(x) k3(60)
* _nwsaom_precheck.ado:126 missnet() with the wrong number of matrices
xt_err 198 : nwsaom, waves(dn1 dn2 dn3) outdegree reciprocity missnet(MS0 MS0) k3(60)
* nwsaom.ado:860 missnet() matrix of the wrong size
xt_err 198 : nwsaom, waves(dn1 dn2 dn3) outdegree reciprocity missnet(MS0 MSbig MS0) k3(60)
* nwsaom.ado:867 missnet() matrix not 0/1
xt_err 198 : nwsaom, waves(dn1 dn2 dn3) outdegree reciprocity missnet(MS0 MSbad MS0) k3(60)
* _nwsaom_precheck.ado:134 missbeh() without behavior()
xt_err 198 : nwsaom, waves(dn1 dn2 dn3) outdegree reciprocity missbeh(p1 p2 p3) k3(60)
* nwsaom.ado:387 behavior() with the wrong number of variables
xt_err 198 : nwsaom, waves(dn1 dn2 dn3) outdegree reciprocity behavior(z1 z2) linear k3(60)
* nwsaom.ado:420 behavior() without a linear shape effect
xt_err 198 : nwsaom, waves(dn1 dn2 dn3) outdegree reciprocity behavior(z1 z2 z3) avalt k3(60)
* nwsaom.ado:455 a behavior effect without behavior()
xt_err 198 : nwsaom, waves(dn1 dn2 dn3) outdegree reciprocity linear k3(60)
* nwsaom.ado:799 ratecovcoef() with the wrong number of values
xt_err 198 : nwsaom, waves(dn1 dn2 dn3) outdegree reciprocity ratecov(x) ratecovcoef(0 0) k3(60)
* nwsaom.ado:957 gwaves() without groups()
xt_err 198 : nwsaom, waves(dn1 dn2 dn3) outdegree reciprocity gwaves(2: 1 2) k3(60)
* nwsaom.ado:1625 a dyadic covariate matrix that does not exist (late error with another effect list: no simulation check)
global XT_SIMCHK 0
xt_err 111 : nwsaom, waves(dn1 dn2 dn3) outdegree reciprocity dyadx(xwx:NOSUCHMAT) k3(60)
global XT_SIMCHK 1
* nwsaom.ado:716 outdegree endowment/creation with the rate estimated
xt_err 198 : nwsaom, waves(dn1 dn2 dn3) outdegreeendow outdegreecreation reciprocity k3(60)
* nwsaom.ado:186 endow() without creation() for the same effect
xt_err 198 : nwsaom, waves(dn1 dn2 dn3) outdegree reciprocity endow(transties) k3(60)
di "PASS errors: nwsaom options"

* ---------------------------------------------------------------------------------------------------------------------------
* 3. estat and nwsaom simulate (the stored fit stays in memory)
* ---------------------------------------------------------------------------------------------------------------------------
* nwsaom_estat_simulate.ado:44 nsim() < 1
xt_err 198 : estat simulate, nsim(0)
* nwsaom_estat_simulate.ado:59 theta() matrix not found
xt_err 111 : estat simulate, nsim(2) theta(NOSUCHMATRIX)
* nwsaom_estat_simulate.ado:63 theta() of the wrong shape (a network-sized matrix)
xt_err 198 : estat simulate, nsim(2) theta(MS0)
* nwsaom_estat_simulate.ado:120 rates() with the wrong number of values
xt_err 198 : estat simulate, nsim(2) rates(3)
* Stata numlist: rates() must be > 0
xt_err 125 : estat simulate, nsim(2) rates(3 -1)
* nwsaom_estat_simulate.ado:130 ratesbeh() after a network-only fit
xt_err 198 : estat simulate, nsim(2) ratesbeh(1 1)
* nwsaom_estat.ado:253 estat gof, nsim() < 5
xt_err 198 : estat gof, nsim(4)
* nwsaom_estat.ado:271 stats() unknown
xt_err 198 : estat gof, nsim(10) stats(bogus)
* nwsaom_estat.ado:275 stats(behavior) after a network-only fit
xt_err 198 : estat gof, nsim(10) stats(behavior)
* nwsaom_estat.ado:230 join() other than off
xt_err 198 : estat gof, nsim(10) join(on)
* nwsaom_estat.ado:1180 estat mems after three waves
xt_err 498 : estat mems, effect(outdegree) macro(xt_mties) nsim(20)
* nwsaom_estat_score.ado:35 estat score after a fit without fix()
xt_err 198 : estat score
* nwsaom_estat_timetest.ado:58 effects() names an effect that is not in the model
xt_err 198 : estat timetest, effects(transtrip)
* nwsaom_estat.ado:212 an estat subcommand nwsaom does not have
xt_err 321 : estat bogus
* nwsaom_simulate.ado:46 / :50 nwsaom simulate without theta() / rates()
xt_err 198 : nwsaom simulate, waves(dn1 dn2 dn3) outdegree reciprocity rates(3 3) nsim(2)
xt_err 198 : nwsaom simulate, waves(dn1 dn2 dn3) outdegree reciprocity theta(-2 1) nsim(2)
* nwsaom_simulate.ado:58 the set-up fit fails (theta0() count, nwsaom.ado:2960)
xt_err 198 : nwsaom simulate, waves(dn1 dn2 dn3) outdegree reciprocity theta(-2) rates(3 3) nsim(2)
* nwsaom_describe.ado: Stata unab (one wave) and behavior() count (:192)
xt_err 102 : nwsaom describe, waves(dn1)
xt_err 198 : nwsaom describe, waves(dn1 dn2 dn3) behavior(z1 z2)
* nwsaom_describe.ado:43 waves of different sizes
xt_err 198 : nwsaom describe, waves(small1 dn2)
* nwsaom_refit.ado:28 maxruns() < 1
xt_err 198 : nwsaom refit, maxruns(0)
* nwsaom_meta.ado:20 alpha() out of (0,1); :30 stored estimates not found
xt_err 198 : nwsaom meta base base, alpha(1)
xt_err 111 : nwsaom meta base nosuchestimates
* nwsaom_multiplex.ado:87 undirected networks (own estimator, theta01() given)
xt_err 198 : nwsaom multiplex, netawave1(sn1) netawave2(sn2) netbwave1(dn1) netbwave2(dn2) theta01(-1 0) theta02(-1 0) k3(60)
* nwsaom_multinet.ado:172 different numbers of waves
xt_err 198 : nwsaom multinet, net1(dn1 dn2 dn3) net2(dn1 dn2) k3(60)
di "PASS errors: estat, simulate, describe, refit, meta, multiplex, multinet"

* ---------------------------------------------------------------------------------------------------------------------------
* 4. errors that depend on the fit in memory
* ---------------------------------------------------------------------------------------------------------------------------
global XT_SIMCHK 0
* a two-wave fit: estat timetest needs three waves (nwsaom_estat_timetest.ado:37); estat mems: interval() / nsim() / effect() / macro()
nwsaom, waves(dn1 dn2) outdegree reciprocity k0(10) k3(60) seed(3)
xt_esnap
xt_dsnap
xt_err 198 : estat timetest
* nwsaom_estat.ado:1220 interval() with one value
xt_err 198 : estat mems, effect(outdegree) macro(xt_mties) nsim(20) interval(1)
* nwsaom_estat.ado:1224 nsim() < 20
xt_err 198 : estat mems, effect(outdegree) macro(xt_mties) nsim(19)
* nwsaom_estat.ado:1236 effect() not a coefficient
xt_err 198 : estat mems, effect(transtrip) macro(xt_mties) nsim(20)
* Stata syntax: effect() and macro() are required
xt_err 198 : estat mems, nsim(20)
* nwsaom_estat.ado:1257 macro() program that does not exist (the leftover network it may leave is probed in xt_suspects.do)
capture noisily estat mems, effect(outdegree) macro(nosuchprogram) nsim(20)
assert _rc == 498
xt_esame
* a fit with fix(): estat score tested() of an effect that is not fixed (nwsaom_estat_score.ado:59)
nwsaom, waves(dn1 dn2 dn3) outdegree reciprocity theta0(-2 0) fix(reciprocity) k0(10) k3(60) seed(3)
xt_esnap
xt_dsnap
xt_err 198 : estat score, tested(outdegree)
* a two-mode fit (22 actors x 8 events = 30 nodes): estat gof (nwsaom_estat.ado:241) and estat mems (:1180) stop
nwclear
clear
mata: xt_tm("TN", 22, 8, 2, 0.15, 0.10, 14)
nwset, mat(TN1) bipartite name(tn1) nooutput
nwset, mat(TN2) bipartite name(tn2) nooutput
nwset, mat(D2) directed name(dm2) nooutput
nwsaom, waves(tn1 tn2) outdegree k0(10) k3(60) seed(3)
xt_esnap
xt_dsnap
xt_err 198 : estat gof, nsim(10)
xt_err 198 : estat mems, effect(outdegree) macro(xt_mties) nsim(20)
* nwsaom.ado:497 actormode() not 1 or 2; nwsaom.ado:505 an effect a two-mode network does not have
xt_err 198 : nwsaom, waves(tn1 tn2) outdegree actormode(3) k3(60)
xt_err 198 : nwsaom, waves(tn1 tn2) outdegree reciprocity k3(60)
* nwsaom.ado:491 two-mode and one-mode waves of the same size mixed
xt_err 198 : nwsaom, waves(tn1 dm2) outdegree k3(60)
* no estimates at all: Stata's estat
ereturn clear
xt_dsnap
capture noisily estat gof
assert _rc == 301
capture noisily estat simulate
assert _rc == 301
* nwsaom_refit.ado:15 no nwsaom results
capture noisily nwsaom refit
assert _rc == 301
xt_dsame
di "PASS errors that depend on the fit in memory"

di "ALL PASS"

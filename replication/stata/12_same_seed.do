* A seed reproduces within one Stata session: each model is fitted twice in a row with the same seed,
* and once more with cores(1); all three fits must give identical estimates and standard errors.
* Run from the replication folder:  stata -e do stata/12_same_seed.do
quietly do stata/setup.do
nwwebuse glasgow, nwclear
local cmd_E1 "waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity cycle3 nodematch(smoke1)"
local cmd_E4 "waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity behsim behavior(alcohol1 alcohol2 alcohol3) linear avalt"
local bad 0
foreach m in E1 E4 {
	quietly nwsaom, `cmd_`m'' seed(12345)
	matrix b1 = e(b)
	matrix V1 = e(V)
	quietly nwsaom, `cmd_`m'' seed(12345)
	matrix b2 = e(b)
	matrix V2 = e(V)
	quietly nwsaom, `cmd_`m'' seed(12345) cores(1)
	matrix b3 = e(b)
	matrix V3 = e(V)
	local d12 = mreldif(b1, b2) + mreldif(V1, V2)
	local d13 = mreldif(b1, b3) + mreldif(V1, V3)
	display as text "`m': second fit differs by " as result `d12' as text ", fit on one core by " as result `d13'
	if `d12' != 0 | `d13' != 0 local bad 1
}
if `bad' display as error "A seed did not reproduce."
else display as text "Same seed, same session: identical estimates and standard errors."

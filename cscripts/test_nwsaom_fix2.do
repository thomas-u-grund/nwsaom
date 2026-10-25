cscript

* Regression test: "nwsaom version" as the FIRST command of a fresh session reported the native plugin as missing, because the
* Mata library was not yet indexed (SaomNativePluginPath() "not found"). This test must therefore not load unw_*.do: it runs against the built
* library in lib/. The plugin lives in lib/plugins/macos, which is put on the adopath like an installed plugin.

local nwcore : env NWCORE
if `"`nwcore'"' == "" {
	di as error "set the environment variable NWCORE to the directory of the nwcommands (core) package"
	exit 198
}
adopath ++ `"`nwcore'"'
capture adopath ++ `"`nwcore'/lib"'
adopath ++ `"`c(pwd)'"'
adopath ++ `"`c(pwd)'/lib"'
adopath ++ `"`c(pwd)'/lib/plugins/macos"'

* first command of the session
nwsaom version
assert strpos(`"`r(plugin)'"', "missing") == 0
assert strpos(`"`r(plugin)'"', "saom_sim") > 0
di as text "  PASS: nwsaom version finds the native plugin in a fresh session"
di as result "ALL TESTS PASSED"

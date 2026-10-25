* Builds lib/lnwsaom.mlib from the Mata source(s) of this package. Run from the root of the repository:
*   NWCORE=/path/to/nwcommands StataBE -e do lib/build.do
* The sources use the core classes (nw_def) at compile time; the core library is found through NWCORE/lib.
version 12
* BUILD GUARD: Mata libraries must be built with the OLDEST supported Stata (currently Stata 17), never with a newer one: a library
* compiled by a newer Stata is silently ignored by older Stata versions ("compiled by Stata 18.0, is too new to be run by this version
* of Stata and so was ignored"), and every function is then "not found" (r(3499)). Set NW_ALLOW_NEWER_STATA=1 only for experiments
* whose library is never released.
local nw_minbuild 17
local nw_allow : env NW_ALLOW_NEWER_STATA
if c(stata_version) > `nw_minbuild' & "`nw_allow'" != "1" {
    di as error "this library must be built with Stata `nw_minbuild' (the oldest supported version), but this is Stata " c(stata_version) ". A library built by a newer Stata cannot be used by older Stata versions."
    di as error "Run the build with Stata `nw_minbuild' (see RELEASING.md, 'Build the Mata libraries with the oldest supported Stata'); NW_ALLOW_NEWER_STATA=1 overrides this for experiments."
    exit 198
}
clear all
capture mata: mata clear
local nwcore : env NWCORE
if `"`nwcore'"' == "" {
	di as error "set the environment variable NWCORE to the directory of the nwcommands (core) package"
	exit 198
}
local root `"`c(pwd)'"'
* The libraries are compiled against the core's FINISHED library lib/lnwcommands.mlib (not against a fresh compile of the core
* source): a Mata class carries the time it was compiled, and objects made by the installed core are only accepted by code that
* was compiled against that very library (otherwise r(3021) "class compiled at different times"). Whenever the core library is
* rebuilt, rebuild this package's libraries with this script and release them together (see RELEASING.md).
capture confirm file `"`nwcore'/lib/lnwcommands.mlib"'
if _rc {
	di as error "`nwcore'/lib/lnwcommands.mlib not found: build the core library first (do lib/build.do in the core)"
	exit 601
}
adopath ++ `"`nwcore'/lib"'
mata: mata mlib index
mata: mata which nw_def()
do unw_saom.do
mata: mata mlib create lnwsaom1, dir(`"`root'/lib"') replace
mata: mata mlib add lnwsaom1 stat*() Saom*(), dir(`"`root'/lib"')
mata: mata mlib create lnwsaom2, dir(`"`root'/lib"') replace
mata: mata mlib add lnwsaom2 change*() _*() sn*() saom*() mm*(), dir(`"`root'/lib"')
mata: mata mlib index

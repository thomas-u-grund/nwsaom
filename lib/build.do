* Builds lib/lnwsaom.mlib from the Mata source(s) of this package. Run from the root of the repository:
*   NWCORE=/path/to/nwcommands StataBE -e do lib/build.do
* The sources use the core classes (nw_def) at compile time; the core library is found through NWCORE/lib.
version 12
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

* Builds lib/lnwsaom.mlib from the Mata source(s) of this package. Run from the root of the repository:
*   NWCORE=/path/to/nwcommands StataBE -e do lib/build.do
* The sources use the core classes (nw_def) at compile time. The core is therefore compiled into a temporary
* library first and cleared from memory again, so that lnwsaom.mlib contains only this package's functions.
version 12
clear all
capture mata: mata clear
local nwcore : env NWCORE
if `"`nwcore'"' == "" {
	di as error "set the environment variable NWCORE to the directory of the nwcommands (core) package"
	exit 198
}
local root `"`c(pwd)'"'
local tmpdir `"`c(tmpdir)'/nwcore_tmp_mlib"'
capture mkdir `"`tmpdir'"'
do `"`nwcore'/unw_core.do"'
mata: mata mlib create lnwcoretmp, dir(`"`tmpdir'"') replace
mata: mata mlib add lnwcoretmp *(), dir(`"`tmpdir'"')
mata: mata clear
adopath ++ `"`tmpdir'"'
mata: mata mlib index
do unw_saom.do
mata: mata mlib create lnwsaom1, dir(`"`root'/lib"') replace
mata: mata mlib add lnwsaom1 stat*() Saom*(), dir(`"`root'/lib"')
mata: mata mlib create lnwsaom2, dir(`"`root'/lib"') replace
mata: mata mlib add lnwsaom2 change*() _*() sn*() saom*() mm*(), dir(`"`root'/lib"')
mata: mata mlib index

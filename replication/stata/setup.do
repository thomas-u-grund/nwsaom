* Set-up for every do-file of the replication package. Run the do-files from the replication folder:
*     cd <replication folder>
*     do stata/02_examples.do
* By default the installed packages are used. To install the versions of the article from their release tags:
*     net install nwcommands, replace from(https://raw.githubusercontent.com/thomas-u-grund/nwcommands/v3.17.2/)
*     nwinstall, all from(https://raw.githubusercontent.com/thomas-u-grund/nwcommands/v3.17.2)
*     nwinstall, modelpkg(nwsaom) release(v1.5.10)
* To use source trees instead (git checkouts of nwcommands 3.17.2 and nwsaom 1.5.10), set before running:
*     global NWCORE "<nwcommands tree>"
*     global NWSAOM "<nwsaom tree>"
*     global NWPLUS "<an empty folder>"   (optional: a PLUS folder without other installed copies)
version 17
capture program drop nwinstall
clear all
set more off
set linesize 80
capture confirm file "stata/setup.do"
if _rc {
	di as error "run the do-files from the replication folder (cd there first)"
	exit 601
}
global REP "`c(pwd)'"
if `"$NWCORE"' != "" {
	if `"$NWSAOM"' == "" {
		di as error "global NWSAOM (the nwsaom tree) must be set together with NWCORE"
		exit 198
	}
	if `"$NWPLUS"' != "" {
		capture mkdir `"$NWPLUS"'
		sysdir set PLUS `"$NWPLUS"'
	}
	local plat = cond(c(os) == "Windows", "windows", cond(c(os) == "MacOSX", "macos", "unix"))
	quietly adopath ++ `"$NWCORE"'
	quietly adopath ++ `"$NWCORE/lib"'
	quietly adopath ++ `"$NWCORE/lib/plugins/`plat'"'
	quietly adopath ++ `"$NWSAOM"'
	quietly adopath ++ `"$NWSAOM/lib"'
	quietly adopath ++ `"$NWSAOM/lib/plugins/`plat'"'
	global nwwebpath `"$NWCORE/data"'
}
which nwsaom
nwsaom version
display "Stata `c(stata_version)' (`c(edition_real)'), `c(os)' `c(machine_type)'"

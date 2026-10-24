#!/bin/zsh
# Does Stata accept the generated dialogs?  `capture db <name>` in Stata -e (batch): rc 0 = loads, 1001 = rejected.
# Usage: NWCORE=/path/to/nwcommands dlg/db_load_check.sh   (batch mode shows no window: this checks loading only, not the look)
root=${0:A:h:h}
tmp=$(mktemp -d /private/tmp/nwsaom_db_XXXXXX)
mkdir -p $tmp/plus
cat > $tmp/dbchk.do <<EOF
cd "$tmp"
capture program drop nwinstall
sysdir set PLUS "$tmp/plus"
adopath ++ "$NWCORE"
adopath ++ "$root"
discard
foreach d in nwsaom nwsaom_multinet nwsaom_bayes nwsaom_meta nwsaom_describe nwsaom_multiplex nwsaom_estat {
	capture db \`d'
	display "DBRC|\`d'|" _rc
}
EOF
cd $tmp
perl -e 'alarm 300; exec @ARGV' ${STATA:-/Applications/Stata/StataBE.app/Contents/MacOS/StataBE} -e do dbchk.do > /dev/null 2>&1
[[ -f dbchk.log ]] || { echo "NOT RUN (no log)"; exit 2; }
grep '^DBRC' dbchk.log
! grep '^DBRC' dbchk.log | grep -qv '|0$'

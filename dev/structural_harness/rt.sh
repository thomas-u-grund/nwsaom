#!/bin/zsh
# usage: rt.sh testname  (runs cscripts/<testname>.do with Stata 17 from the worktree)
S=/private/tmp/claude-501/-Users-tgrund-FILES-NEW-SOFTWARE-nwcommands/f80eded9-2ca1-45e7-9a6b-23ada6a895b2/scratchpad/st130
cd $S/nwsaom
export NWCORE=/private/tmp/claude-501/-Users-tgrund-FILES-NEW-SOFTWARE-nwcommands/f80eded9-2ca1-45e7-9a6b-23ada6a895b2/scratchpad/r3100
{ cat $S/run/rt.do; echo "do cscripts/$1.do"; } > $S/run/run_$1.do
perl -e 'alarm 1500; exec @ARGV' "/Applications/Stata 17.0/StataBE.app/Contents/MacOS/StataBE" -e do $S/run/run_$1.do > /dev/null 2>&1
grep -E '^PASS|^r\([0-9]+\)' run_$1.log | sort | uniq -c | head -40
tail -5 run_$1.log | cut -c1-200

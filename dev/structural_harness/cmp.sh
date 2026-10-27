#!/bin/zsh
# usage: cmp.sh variant  -> data+R targets+nwsaom targets, compare
v=$1
S=/private/tmp/claude-501/-Users-tgrund-FILES-NEW-SOFTWARE-nwcommands/f80eded9-2ca1-45e7-9a6b-23ada6a895b2/scratchpad/st130
d=$S/p0/$v
mkdir -p $d
cd $S/nwsaom && Rscript dev/saom_rsiena_structural.R $d $v targets 2>&1 | grep -E 'DIST|TARGET' > $d/r_targets.txt
cd $S/nwsaom && perl -e 'alarm 280; exec @ARGV' "/Applications/Stata 17.0/StataBE.app/Contents/MacOS/StataBE" -e do ../run/tv.do $d
rm -f $S/nwsaom/tv.log
python3 $S/cmp.py $d

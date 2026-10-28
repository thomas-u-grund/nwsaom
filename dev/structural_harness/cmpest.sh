#!/bin/zsh
# usage: cmpest.sh variant cond(1|0) [seeds] [n3]
v=$1; cond=${2:-1}; seeds=${3:-8}; n3=${4:-1000}
S=/private/tmp/claude-501/-Users-tgrund-FILES-NEW-SOFTWARE-nwcommands/f80eded9-2ca1-45e7-9a6b-23ada6a895b2/scratchpad/st130
d=$S/p0/$v
mkdir -p $d
[[ -f $d/w1.csv ]] || (cd $S && Rscript nwsaom/dev/saom_rsiena_structural.R $d $v data)
cd $S && COND=$cond Rscript nwsaom/dev/saom_rsiena_structural.R $d $v est $seeds $n3 2>&1 | grep -v '^Cop\|^If you\|^This is' > $d/r_est_c$cond.txt
tag=$([[ $cond == 1 ]] && echo cond || echo uncond)
cd $S/nwsaom && perl -e 'alarm 900; exec @ARGV' "/Applications/Stata 17.0/StataBE.app/Contents/MacOS/StataBE" -e do ../run/testim.do $d $seeds $tag >/dev/null
rm -f $S/nwsaom/testim.log
python3 $S/cmpest.py $d $cond

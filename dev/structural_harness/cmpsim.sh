#!/bin/zsh
# usage: cmpsim.sh variant cond [K] [seeds] [n3]
v=$1; cond=${2:-0}; K=${3:-4000}; seeds=${4:-6}; n3=${5:-500}
S=/private/tmp/claude-501/-Users-tgrund-FILES-NEW-SOFTWARE-nwcommands/f80eded9-2ca1-45e7-9a6b-23ada6a895b2/scratchpad/st130
d=$S/p0/$v
mkdir -p $d
[[ -f $d/w1.csv ]] || (cd $S/nwsaom && Rscript dev/saom_rsiena_structural.R $d $v data)
cd $S/nwsaom && COND=$cond Rscript dev/saom_rsiena_structural.R $d $v sim $seeds $n3 2>&1 | grep -E '^MEAN|^SE' > $d/r_sim_c$cond.txt
cd $S/nwsaom && perl -e 'alarm 560; exec @ARGV' "/Applications/Stata 17.0/StataBE.app/Contents/MacOS/StataBE" -e do ../run/$([[ $v == tm* ]] && echo tsimtm.do || ([[ $v == sy* ]] && echo tsimsym.do || echo tsim.do)) $d $K $cond >/dev/null
rm -f $S/nwsaom/tsim.log
python3 $S/cmpsim.py $d $cond $K

* Loads the fifteen Dutch school classes of Baerveldt's study (nwwebuse baerveldt, a data set of nwcommands) and stacks them:
* wave networks w1 and w2 are block-diagonal (no ties between classes); variable class is 1..15 (810 pupils).
* The networks of the single classes (class1_w1 ... class15_w2) stay in memory.
nwwebuse baerveldt, nwclear
local w1 ""
local w2 ""
forvalues k = 1/15 {
    local w1 `w1' class`k'_w1
    local w2 `w2' class`k'_w2
}
clear
nwstack `w1', name(w1) group(class)
nwstack `w2', name(w2)

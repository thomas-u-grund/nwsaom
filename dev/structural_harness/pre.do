capture program drop nwinstall
clear all
set more off
sysdir set PLUS "/private/tmp/claude-501/-Users-tgrund-FILES-NEW-SOFTWARE-nwcommands/f80eded9-2ca1-45e7-9a6b-23ada6a895b2/scratchpad/st130/plus1"
local core "/private/tmp/claude-501/-Users-tgrund-FILES-NEW-SOFTWARE-nwcommands/f80eded9-2ca1-45e7-9a6b-23ada6a895b2/scratchpad/r3100"
local pkg  "/private/tmp/claude-501/-Users-tgrund-FILES-NEW-SOFTWARE-nwcommands/f80eded9-2ca1-45e7-9a6b-23ada6a895b2/scratchpad/st130/nwsaom"
global NWCORE "`core'"
adopath ++ "`core'"
adopath ++ "`core'/lib"
adopath ++ "`pkg'"
adopath ++ "`pkg'/lib/plugins/macos"

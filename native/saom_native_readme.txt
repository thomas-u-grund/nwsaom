nwsaom: C source of the native plugin
=====================================

nwsaom simulates the model in a compiled Stata plugin (saom_sim). The package
installs the compiled plugins for macOS, Linux and Windows; this file comes with
the C source they were built from. nwsaom is free software under the GNU General
Public License, version 3 (file LICENSE in the repository).

Where to get the source
  * In Stata:  net get nwsaom, from(https://raw.githubusercontent.com/thomas-u-grund/nwsaom/main)
    copies the files into the current directory. net get puts all files of a
    package into one folder; the build needs the layout of the repository (below).
  * On GitHub: https://github.com/thomas-u-grund/nwsaom, folder native/.

Files
  saom_sim.c, saom_ml.c, saom_bayes.c, saom_struct.c   the plugin (saom_sim.c includes the others)
  stplugin.c, stplugin.h   StataCorp's Stata Plugin Interface 3.0 (https://www.stata.com/plugins/),
                           redistributed unchanged; not part of nwsaom's own code
  makefile                 the build rules (Makefile in the repository; net get writes lower case names)

Layout needed for the build (as in the repository)
  native/saom_sim.c  native/saom_ml.c  native/saom_bayes.c  native/saom_struct.c  native/Makefile
  native/spi/stplugin.c  native/spi/stplugin.h

Build
  macOS (universal binary):  cd native && make macos
  Linux:                     cd native && make unix
  Windows (Visual Studio x64 prompt, in native/):
      cl /LD /DSYSTEM=STWIN32 /I spi saom_sim.c spi\stplugin.c /Fe:..\lib\plugins\windows\saom_sim_windows.plugin
  The binaries are written to lib/plugins/<platform>/ next to the .ado files.

#!/usr/bin/env python3
"""check_version.py - verify that every version display matches VERSION (same as set_version.py --check), and, when the environment
variable NWCORE points to the core checkout, that this package's Mata libraries were built against the core's current Mata library."""
import os, sys, hashlib
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import set_version
rc = set_version.main(['--check'])
root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
core = os.environ.get("NWCORE", "")
rec = os.path.join(root, "lib", "core_mlib.sha256")
if core:
    lib = os.path.join(core, "lib", "lnwcommands.mlib")
    if not os.path.exists(rec):
        print("lib/core_mlib.sha256 is missing: build the libraries (lib/build.do) and run NWCORE=... python3 tools/record_core_lib.py"); rc = 1
    elif not os.path.exists(lib):
        print("NWCORE is set but " + lib + " does not exist"); rc = 1
    elif hashlib.sha256(open(lib, "rb").read()).hexdigest() != open(rec).read().split()[0]:
        print("the core Mata library changed since this package's libraries were built: run lib/build.do and release in step")
        print("  (core: " + lib + "; after the rebuild run: NWCORE=" + core + " python3 tools/record_core_lib.py)"); rc = 1
    else:
        print("core Mata library matches lib/core_mlib.sha256")
else:
    print("NWCORE not set: the core Mata library hash was not compared")
sys.exit(rc)

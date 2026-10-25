#!/usr/bin/env python3
"""record_core_lib.py -- record the sha256 of the core Mata library this package's libraries were built against.

Run it right after building the libraries (lib/build.do) with NWCORE set to the core checkout:
    NWCORE=/path/to/nwcommands python3 tools/record_core_lib.py
It writes lib/core_mlib.sha256. tools/check_version.py (run by the tests and CI, and before every release) compares that hash with
$NWCORE/lib/lnwcommands.mlib when NWCORE is set and fails when they differ.
"""
import hashlib, os, sys
root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
core = os.environ.get("NWCORE", "")
lib = os.path.join(core, "lib", "lnwcommands.mlib")
if not core or not os.path.exists(lib):
    print("record_core_lib: set NWCORE to the core nwcommands checkout (lib/lnwcommands.mlib not found)"); sys.exit(1)
h = hashlib.sha256(open(lib, "rb").read()).hexdigest()
open(os.path.join(root, "lib", "core_mlib.sha256"), "w").write(h + "  lnwcommands.mlib\n")
print("recorded lib/core_mlib.sha256:", h)

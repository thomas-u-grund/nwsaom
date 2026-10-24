#!/usr/bin/env python3
"""check_version.py - verify that every version display matches VERSION (same as set_version.py --check)."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import set_version
sys.exit(set_version.main(['--check']))

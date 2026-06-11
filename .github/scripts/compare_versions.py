#!/usr/bin/env python3
"""Version comparison utility for GitHub Actions CI"""
import sys
from packaging import version

if len(sys.argv) != 3:
    print("Usage: compare_versions.py <version1> <version2>")
    sys.exit(1)

v1 = sys.argv[1]
v2 = sys.argv[2]

if version.parse(v1) > version.parse(v2):
    print(f"{v1} is newer than {v2}")
    sys.exit(0)
else:
    print(f"{v1} should be newer than {v2}")
    sys.exit(1)
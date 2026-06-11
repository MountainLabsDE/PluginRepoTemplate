#!/usr/bin/env python3
"""Plugin file validator for GitHub Actions CI"""
import json, sys, os, re

uplugin_file = os.environ.get('UPLUGIN', '')

if not uplugin_file or not os.path.exists(uplugin_file):
    print(f"::error::Invalid .uplugin file path: {uplugin_file}")
    sys.exit(1)

with open(uplugin_file) as f:
    data = json.load(f)

required = ['FileVersion', 'Version', 'VersionName', 'FriendlyName',
             'Category', 'Modules']
missing = [k for k in required if k not in data]
if missing:
    print(f"::error::Missing required fields in .uplugin: {missing}")
    sys.exit(1)

# Validate VersionName is semver-like
vn = data.get('VersionName', '')
if not re.match(r'^\d+\.\d+\.\d+$', vn):
    print(f"::error::VersionName must be semver (x.y.z), got: {vn}")
    sys.exit(1)

# Validate modules array
for mod in data.get('Modules', []):
    for field in ['Name', 'Type', 'LoadingPhase']:
        if field not in mod:
            print(f"::error::Module missing field {field}: {mod.get('Name', 'unknown')}")
            sys.exit(1)

print(f"✓ .uplugin file is valid: {data.get('FriendlyName', 'Unknown')}")
print(f"✓ Version: {vn}")
print(f"✓ Modules: {', '.join([m['Name'] for m in data.get('Modules', [])])}")
sys.exit(0)
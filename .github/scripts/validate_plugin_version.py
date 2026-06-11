#!/usr/bin/env python3
"""Plugin version consistency checker for GitHub Actions CI"""
import json, re, sys, os

uplugin_file = os.environ.get('UPLUGIN', 'UniversalInteractionSystem.uplugin')

if not os.path.exists(uplugin_file):
    print(f"::error::Plugin file not found: {uplugin_file}")
    sys.exit(1)

with open(uplugin_file) as f:
    data = json.load(f)

# Required fields
for field in ['FileVersion', 'Version', 'VersionName', 'FriendlyName', 'Category', 'Modules']:
    if field not in data:
        print(f'::error::Missing required field: {field}')
        sys.exit(1)

# Version consistency check
ver_name = data['VersionName']
ver_int = data['Version']

if not re.match(r'^\d+\.\d+\.\d+$', ver_name):
    print(f'::error::Invalid VersionName format: {ver_name} (expected X.Y.Z)')
    sys.exit(1)

parts = ver_name.split('.')
expected_int = int(parts[0]) * 10000 + int(parts[1]) * 100 + int(parts[2])
if ver_int != expected_int:
    print(f'::error::Version ({ver_int}) does not match VersionName ({ver_name}, expected int {expected_int})')
    sys.exit(1)

# Module check
if not data['Modules']:
    print('::error::No modules defined in .uplugin')
    sys.exit(1)

print(f'✓ Plugin validation passed: {data["FriendlyName"]} v{ver_name}')
print(f'✓ Version consistency: {ver_name} ↔ {ver_int}')
print(f'✓ Modules: {len(data["Modules"])}')
sys.exit(0)